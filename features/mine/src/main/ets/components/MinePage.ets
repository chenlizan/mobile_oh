import _ from '@wolfx/lodash'
import { CustomList, CustomListItem, Api_Context, UserInfoModel, AppIcon, IconConstants, Avatar } from "@xy/basic";


@Component
export struct MinePage {
  @StorageLink('access_token') token: string = ''
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @StorageLink('UserInfo') userInfo: UserInfoModel = new UserInfoModel()

  async aboutToAppear() {
  }

  build() {
    Column() {
      Row() {
        Row() {
          Column() {
            Avatar({ avatar: this.userInfo.avatar })
          }
          .margin({ left: 40, right: 16 })

          Column() {
            Text(this.userInfo.nickname)
              .fontSize(20)
              .fontColor(Color.White)
              .fontWeight(FontWeight.Bold)
              .textAlign(TextAlign.Start)
            Text('华中师范大学')
              .fontColor(Color.White)
              .textAlign(TextAlign.Start)
          }
          .height('40%')
          .alignItems(HorizontalAlign.Start)
          .justifyContent(FlexAlign.SpaceAround)
        }

        Row() {
          AppIcon({ iconCode: IconConstants.RIGHT, iconSize: 16, iconColor: Color.White })
        }
        .margin({ right: 32 })
      }
      .width('100%')
      .height('170vp')
      .justifyContent(FlexAlign.SpaceBetween)
      .backgroundColor(Color.Blue)
      .backgroundImage($r('app.media.homeBg'))
      .backgroundImageSize({ width: '100%', height: '100%' })
      .backgroundEffect({ radius: 25 })

      Column() {
        CustomList({ listWidth: '94%' }) {
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
      .margin({ top: -24 })

    }
    .width('100%')
    .height('100%')
    .backgroundColor("#f1f1f1")
  }
}