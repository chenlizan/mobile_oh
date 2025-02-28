import _ from '@wolfx/lodash'
import { CustomList, CustomListItem, Api_Context, UserInfoModel, AppIcon, IconConstants } from "@xy/basic";


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


@Component
export struct Avatar {
  @State avatar: string | null = null
  getAvatarSource = (avatar: string) => {
    let source: string | null = null
    if (avatar) {
      if (avatar.indexOf('cloud/file_access') !== -1) {
        if (avatar.indexOf('/cloud/file_access') === 0) {
          let icon_url =
            AppStorage.get<Api_Context>('Api_Context')?.getApiPrefix('baseApi_out') + avatar.slice(1);
          source = icon_url;
        } else if (avatar.indexOf('cloud/file_access') === 0) {
          let icon_url = AppStorage.get<Api_Context>('Api_Context')?.getApiPrefix('baseApi_out') + avatar;
          source = icon_url;
        }
      } else {
        source = avatar;
      }
    }
    return source;
  }

  build() {
    Row() {
      if (this.avatar) {
        Image(this.getAvatarSource(this.avatar))
          .borderRadius(50)
      } else {
        Image($r('app.media.default'))
          .borderRadius(50)
      }
    }
    .width(60)
    .height(60)
    .borderRadius(50)
    .borderWidth(1)
    .borderColor(Color.White)
  }
}