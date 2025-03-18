import _ from "@wolfx/lodash";
import { TextModifier } from "@kit.ArkUI";
import {
  Api_Context,
  AppIcon,
  CCApi,
  ccApiGet,
  CustomToast,
  getIdentityList,
  IconConstants,
  ObjectOption,
  ObjectUtil,
  PreferenceStorage,
  RouterConstants,
  SelectSpace,
  UserInfoModel
} from "@xy/basic";

@Component
export struct IdentityPage {
  @Link globalPageIndex: string;
  @StorageLink('PreferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage();
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context(this.preferenceStorage?.school?.domain)
  @StorageLink('UserInfo') userInfo: UserInfoModel = new UserInfoModel()
  @State manageSpaces: SelectSpace[] = []
  @State isRefreshing: boolean = false

  aboutToAppear(): void {
    this.handleUserInfo()
  }

  async handleUserInfo(cb?: () => void) {
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

      this.manageSpaces = getIdentityList(res) as SelectSpace[]
      this.preferenceStorage.need_select_space = this.manageSpaces.length > 0
      if (this.manageSpaces.length > 0) {
        const item: SelectSpace = {
          type: 'teaching',
          role: '教师学生',
          title: '教与学的空间',
        };
        this.manageSpaces.unshift(item as SelectSpace);
      }

      if (this.manageSpaces.length === 0) {
        this.globalPageIndex = RouterConstants.MAIN_PAGE_URL
      }

      if (cb) {
        setTimeout(() => {
          cb()
        }, 500)
      }
    }
  }

  handleSelect(space: SelectSpace) {
    if (space.type !== 'teaching') {
      CustomToast.toast_info(`移动端暂未开放${space.title}，请去web端查看。`)
      return;
    }
    this.preferenceStorage.selectSpace = space
    this.globalPageIndex = RouterConstants.MAIN_PAGE_URL
  }

  getSpaceIconByType(type: string | undefined) {
    switch (type) {
      case 'teaching':
        return IconConstants.SPACE_TEACHING
      case 'supervision':
        return IconConstants.SPACE_SUPERVISION
      case 'review':
        return IconConstants.SPACE_REVIEW
      case 'manager':
        return IconConstants.SPACE_MANAGER
      default:
        return IconConstants.SPACE_TEACHING
    }
  };

  build() {
    NavDestination() {
      Column() {
        if (this.userInfo.nickname && this.userInfo.realname) {
          Text(`用户${this.userInfo.nickname}（${this.userInfo.realname}）在本系统中拥有多个角色，请选择一个角色进入相应的空间`)
            .margin({ left: 16, right: 16, bottom: 8 })
            .fontColor('#999999')
            .fontSize(12)
            .opacity(0.85)
        }
        Refresh({ refreshing: $$this.isRefreshing }) {
          List() {
            ForEach(this.manageSpaces, (item: SelectSpace) => {
              ListItem() {
                Flex({ direction: FlexDirection.Column }) {
                  Column() {
                    Row() {
                      AppIcon({
                        iconCode: this.getSpaceIconByType(item.type),
                        iconSize: 24,
                        iconColor: '#40a9ff',
                        iconBackgroundColor: '#e4f2ff',
                        iconRadius: 50,
                        iconPadding: 8
                      })
                      Text(item.role)
                        .margin({ left: 8 })
                      Text(item.roleSpace ?? '')
                        .margin({ left: 8 })
                    }
                    .justifyContent(FlexAlign.Start)
                    .width('100%')
                    .padding({ top: 16, left: 16 })
                    .borderRadius({ topLeft: 8, topRight: 8 })

                    Row() {
                      Image($r('app.media.space_arrow_right'))
                        .width(32)
                        .height(14)
                        .margin({ right: 8 })
                      Text(item.title)
                        .fontSize(20)
                        .fontWeight(FontWeight.Bold)
                    }
                    .width('100%')
                    .height(100)
                    .justifyContent(FlexAlign.Center)
                  }
                  .borderRadius({ topLeft: 8, topRight: 8 })
                  .backgroundColor(Color.White)
                  .width('100%')

                  Row() {
                    if (item.schoolName) {
                      Image($r('app.media.space_school'))
                        .width(24)
                        .height(24)
                        .margin({ left: 16, right: 8 })
                      Text(item.schoolName)
                        .fontColor('#999999')
                    }
                  }
                  .height(48)
                }
                .width('100%')
                .backgroundColor('#f1f1f1')
                .borderRadius(8)
                .borderWidth(1)
                .borderColor(this.preferenceStorage?.selectSpace?.type === item.type ? '#40a9ff' : '#f1f1f1')
                .shadow(ShadowStyle.OUTER_DEFAULT_XS)
              }
              .margin({ left: 16, right: 16, bottom: 16 })
              .onClick(() => this.handleSelect(item))
            })
          }
        }.onRefreshing(() => {
          this.handleUserInfo(() => {
            this.isRefreshing = false;
          })
        })
      }
      .margin({ bottom: 30 })
    }
    .title(this.userInfo.nickname ? '我的小雅空间' : null, {
      mainTitleModifier: new TextModifier().fontColor('#404040').fontSize(16).fontWeight(FontWeight.Normal)
    })
  }
}