import _ from '@wolfx/lodash'
import {
  xyApiPost,
  RouterConstants,
  Api_Context,
  UserInfoModel,
  ccApiGet,
  ObjectUtil,
  CCApi,
  ObjectOption
} from '@xy/basic';

@Component
export struct LoginPage {
  @Link globalPageIndex: string;
  private domain: string = 'ccnu'
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context(this.domain)
  @StorageLink('UserInfo') userInfo: UserInfoModel = new UserInfoModel()

  aboutToAppear() {
  }

  async handleUserInfo() {
    const infra_userinfo_response = await ccApiGet(this.Api_Context.getApiPrefix('ccApi') + CCApi.queryInfraUserInfo)
    if (infra_userinfo_response.code === 200) {
      this.userInfo.mobile =
        new ObjectUtil(infra_userinfo_response.result as ObjectOption<never>).getValue('mobile')
    }

    const userinfo_response = await ccApiGet(this.Api_Context.getApiPrefix('ccApi') + CCApi.getUserInfo)
    if (userinfo_response.code === 200) {
      const res = new ObjectUtil(userinfo_response.result as ObjectOption<never>)
      this.userInfo.userId = res.getValue('id')
      this.userInfo.id = res.getValue('authorId')
      this.userInfo.nickname = res.getValue('nickname')
      this.userInfo.realname = res.getValue('realname')
      this.userInfo.avatar = res.getValue('headImageUrl') || res.getValue('avatar')
      this.userInfo.schools = res.getValue('schoolRoleInfos')
      this.userInfo.fileCapacity = res.getValue('userFileCapacityLevel')
      this.userInfo.isSchoolFellow = (res.getValue('schoolRoleInfos') ?? [].length ?? 0) !== 0;

      _.forEach(res.getValue('schoolRoleInfos'), (info: never) => {
        const _info = new ObjectUtil(info as ObjectOption<never>)
        _.map(_info.getValue('roleDepartmentList') ?? [], (depart: never) => {
          const _depart = new ObjectUtil(info as ObjectOption<never>)
          if (_depart.getValue('roleCode') === 'JS010' && _info.getValue('zsFlag') === 0) {
            this.userInfo.isSchoolFellow = true;
            this.userInfo.hasStudent = true;
          }

          if (_depart.getValue('roleCode') === 'JS005') {
            this.userInfo.hasStudent = true;
          }

          if (_depart.getValue('roleCode') !== 'JS005' && _depart.getValue('roleCode') !== 'JS010') {
            this.userInfo.isRealStudent = false;
          }
        });
      });
    }
  }

  handleLogin = async () => {
    const res = await xyApiPost(this.Api_Context.getApiPrefix('baseApi') + 'oauth2/public/login/byid',
      { 'id': '5524075382300476791' },
      {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': 'Basic YWlzdGFybW9vYzoyN2E5NWUxYjExMDQ3MGExNWQ5NTQzNmY5ZWRmZDk4Mg=='
      },)
    if (res) {
      if (res.success) {
        this.handleUserInfo()
        this.globalPageIndex = RouterConstants.MAIN_PAGE_URL
      }
    }
  }

  build() {
    NavDestination() {
      Row() {
        Column() {
          Button('登陆')
            .fontSize(50)
            .fontWeight(FontWeight.Bold)
            .buttonStyle(ButtonStyleMode.TEXTUAL)
            .onClick(this.handleLogin)
        }
        .width('100%')
      }
      .height('100%')
    }
  }
}
