import { display } from "@kit.ArkUI"
import { CustomNavTitle, UserInfoModel } from "@xy/basic"

@Component
struct UserMobile {
  @StorageLink('UserInfo') userInfo: UserInfoModel = new UserInfoModel()
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @State screenWidth: number = 0

  aboutToAppear(): void {
    this.screenWidth = px2vp(display.getDefaultDisplaySync().width)
  }

  @Builder
  BuildNavRightBtn() {
    if (this.userInfo.mobile) {
      Button('移除手机', { buttonStyle: ButtonStyleMode.TEXTUAL })
        .margin({ left: -36 })
        .fontColor('#999999')
        .onClick(() => this.pageInfos.pushPath({ name: 'userRemoveMobile' }))
    }
  }

  build() {
    NavDestination() {
      Column() {
        Image($r('app.media.mobile_bg'))
          .margin({ top: 60 })
          .width(this.screenWidth / 4)

        Row() {
          Text('你的手机号: ')
            .fontColor('#999999')
            .fontSize(14)
          Text(this.userInfo.mobile)
            .fontColor('#40A9FF')
        }
        .margin({ top: 20, bottom: 30 })

        Button('更换手机号', { type: ButtonType.Normal })
          .margin({ left: 32, right: 32 })
          .width(this.screenWidth - 64)
          .height(40)
          .backgroundColor('#40A9FF')
          .borderRadius(4)

        Text('更换手机号后，登录手机号将改变')
          .fontColor('#9a999999')
          .fontSize(14)
          .margin({ top: 12 })
      }
      .width(this.screenWidth)
      .height('100%')

    }
    .title(CustomNavTitle('手机号码', () => this.BuildNavRightBtn()))
    .backgroundColor("#f1f1f1")
  }
}

@Builder
export function UserMobileBuilder() {
  UserMobile()
}