import { CustomList, CustomListItem, BuildImageArrowRight, Api_Context, ccApiGet, CCApi } from "@xy/basic";
import { UserInfoModel } from "../model/UserInfoModel";

@Component
export struct MinePage {
  @StorageLink('access_token') token: string = ''
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  private userInfo: UserInfoModel = new UserInfoModel()

  async aboutToAppear() {
    const infra_userinfo_response = await ccApiGet(this.Api_Context.getApiPrefix('ccApi') + CCApi.queryInfraUserInfo)
    if (infra_userinfo_response.code === 200) {
      this.userInfo.mobile = (infra_userinfo_response.result as UserInfoModel).mobile
    }

    const userinfo_response = await ccApiGet(this.Api_Context.getApiPrefix('ccApi') + CCApi.getUserInfo)
    if (userinfo_response.code === 200) {
      const res = (userinfo_response.result as UserInfoModel)
      this.userInfo.userId = res.id
      // this.id = res.authorId
      this.userInfo.nickname = res.nickname
      this.userInfo.realname = res.realname
      this.userInfo.avatar = res.avatar
      // this.userInfo.schools = res.schoolRoleInfos
      this.userInfo.fileCapacity = res.fileCapacity
    }
  }

  build() {
    Column() {
      Row() {
        Row() {
          Column() {
            Text('头像')
          }
          .margin({ left: 40, right: 16 })

          Column() {
            Text('Wc123456')
            Text('华中师范大学')
          }
        }

        Row() {
          BuildImageArrowRight()
        }
        .margin({ right: 32 })
      }
      .width('100%')
      .height('120vp')
      .padding({ bottom: '-10vp' })
      .justifyContent(FlexAlign.SpaceBetween)
      .backgroundColor(Color.Blue)


      CustomList({ listWidth: '90%' }) {
        CustomListItem({
          text: '个人年度报告',
          itemMargin: { top: '8vp' },
          itemRadius: '8vp',
          itemBorder: ''
        })
        CustomListItem({
          text: '个人数据看板',
          itemMargin: { top: '8vp' },
          itemRadius: '8vp',
          itemBorder: ''
        })
        CustomListItem({
          text: '反馈&建议',
          itemMargin: { top: '8vp' },
          itemRadius: '8vp',
          itemBorder: ''
        })
        CustomListItem({
          text: '关于小雅',
          itemMargin: { top: '8vp' },
          itemRadius: '8vp',
          itemBorder: '',
          onClickBtn: () => {
            this.pageInfos.pushPath({ name: "about" })
          }
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor("#f1f1f1")
  }
}
