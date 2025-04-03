import {
  Api_Context,
  AppIcon,
  Avatar,
  CCApi,
  ccApiGet,
  CustomList,
  CustomListItem,
  CustomNavTitle,
  IconConstants,
  PARAMS,
  PreferenceStorage,
  SystemApi,
  UserInfoModel,
  xyApiGet
} from "@xy/basic"

@Component
struct UserEdit {
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @StorageLink('UserInfo') userInfo: UserInfoModel = new UserInfoModel()
  @StorageLink('PreferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage();
  @State schoolList: Record<string, string>[] = []

  aboutToAppear(): void {
    this.getUserSchoolInfo()
  }

  async getUserSchoolInfo() {
    const response =
      await ccApiGet(this.Api_Context.getApiPrefix('ccApi') + CCApi.queryUserSchoolInfo, { 'userId': this.userInfo.id })
    if (response.code === 200) {
      this.schoolList = response.result as Record<string, string>[]
    }
  }

  @Builder
  BuildAvatarItem() {
    Row() {
      Avatar({ avatar: this.userInfo.avatar, avatarSize: 40 })
      AppIcon({ iconCode: IconConstants.RIGHT })
    }
  }

  @Builder
  BuildTextItem(value: string) {
    Row() {
      Text(value)
        .margin({ right: 8 })
        .fontColor('#999999')
        .fontSize(14)
      AppIcon({ iconCode: IconConstants.RIGHT })
    }
  }

  @Builder
  BuildNicknameItem() {
    Row() {
      Text(this.userInfo.nickname)
        .margin({ right: 8 })
        .fontColor('#999999')
        .fontSize(14)
      AppIcon({ iconCode: IconConstants.RIGHT })
    }
  }

  @Builder
  BuildMobileItem() {
    Row() {
      Text(this.userInfo.mobile ? this.userInfo.mobile : '去绑定')
        .margin({ right: 8 })
        .fontColor('#999999')
        .fontSize(14)
      AppIcon({ iconCode: IconConstants.RIGHT })
    }
  }

  @Builder
  BuildDocumentItem() {
    Row() {
      Text(this.preferenceStorage.node_key ? '******' : '未设置阅读密码')
        .margin({ right: 8 })
        .fontColor('#999999')
        .fontSize(14)
      AppIcon({ iconCode: IconConstants.RIGHT })
    }
  }

  build() {
    NavDestination() {
      CustomList({ listPadding: { left: 16, right: 16 } }) {
        CustomListItem({
          text: "头像",
          operateBuilder: () => this.BuildAvatarItem(),
          itemBorder: {},
          onClickBtn: () => {
          }
        })
        CustomListItem({
          text: "昵称",
          operateBuilder: () => this.BuildNicknameItem(),
          onClickBtn: () => this.pageInfos.pushPath({ name: 'userNickname' })
        })
        CustomListItem({
          text: "手机号码",
          operateBuilder: () => this.BuildMobileItem(),
          onClickBtn: () => this.pageInfos.pushPath({ name: 'userMobile' })
        })
        CustomListItem({
          text: "登录密码",
          operateBuilder: () => this.BuildTextItem('******'),
          onClickBtn: () => this.pageInfos.pushPath({ name: 'userPassword' })
        })
        CustomListItem({
          text: "阅读密码",
          operateBuilder: () => this.BuildDocumentItem(),
          onClickBtn: () => this.pageInfos.pushPath({ name: 'userDocumentPassword' })
        })
        CustomListItem({
          text: "所在学校",
          fontWeight: FontWeight.Bold,
          itemBorder: {},
          operateBuilder: () => {
          },
          itemMargin: { top: 16 },
        })
        ForEach(this.schoolList, (school: Record<string, Record<string, string>>) => {
          CustomListItem({
            text: `${school?.schoolName ?? ''}${school?.departmentName ? ' · ' + school.departmentName : ''}`,
            onClickBtn: () => this.pageInfos.pushPath({ name: 'userSchool', param: JSON.stringify(school) })
          })
        })
        CustomListItem({
          text: "用户级别",
          operateBuilder: () => this.BuildTextItem((this.userInfo.fileCapacity as Record<string, string>).caseName),
          itemBorder: {},
          itemMargin: { top: 16 },
          onClickBtn: () => this.pageInfos.pushPath({ name: 'userLevelInfo' })
        })
      }
    }
    .title(CustomNavTitle('账号设置'))
    .backgroundColor("#f1f1f1")
  }
}

@Builder
export function UserEditBuilder() {
  UserEdit()
}