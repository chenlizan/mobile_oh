import { Api_Context, CustomNavTitle } from "@xy/basic"
import { display } from "@kit.ArkUI"

@Component
struct CourseQrcode {
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @State screenWidth: number = 0
  private param: Record<string, string> = {}

  aboutToAppear(): void {
    this.screenWidth = px2vp(display.getDefaultDisplaySync().width)
    this.param = JSON.parse(String(this.pageInfos.getParamByName('courseQrcode')[0]))
  }

  build() {
    NavDestination() {
      Flex({ direction: FlexDirection.Column, justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
        Text(this.param.name)
          .fontSize(18)
        Text(`课程空间编号：${this.param.key}`)
          .margin(12)
          .fontSize(14)
        QRCode(`${this.Api_Context.getApiPrefix('base_homepage')}joinGroupQrCode/?group_id=${this.param.id}&qrtype=JOIN_GROUP`)
          .width(300)
          .height(300)
        Text('扫描二维码加入课程')
          .margin(12)
          .fontColor('#999999')
          .fontSize(13)
      }
      .width(this.screenWidth - 24)
      .margin({ left: 12, right: 12 })
      .borderRadius(4)
      .backgroundColor(Color.White)
    }
    .title(CustomNavTitle('扫码加入课程'))
    .backgroundColor('#f1f1f1')
  }
}

@Builder
export function CourseQrcodeBuilder() {
  CourseQrcode()
}