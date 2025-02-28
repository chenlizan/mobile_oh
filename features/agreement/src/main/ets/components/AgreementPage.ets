import { Api_Context, PreferenceStorage, RouterConstants } from "@xy/basic";
import { webview } from "@kit.ArkWeb";
import { common } from "@kit.AbilityKit";

@Component
export struct AgreementPage {
  @Link globalPageIndex: string;
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @StorageLink('preferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage();
  @State showWeb: boolean = false
  @State webUrl: string = ''
  controller: webview.WebviewController = new webview.WebviewController();

  handleAgree = () => {
    this.preferenceStorage.is_agreement = true;

    this.globalPageIndex = RouterConstants.SCHOOL_PAGE_URL
  }

  handleRefuse = () => {
    (getContext(this) as common.UIAbilityContext)?.terminateSelf();
  }

  handleBack = () => {
    this.showWeb = false
    this.webUrl = ''
  }

  showAgreement = (url: string) => {
    this.showWeb = true
    this.webUrl = url
  };

  @Builder
  AgreementWeb() {
    Flex({direction: FlexDirection.Column}) {
      Web({ src: this.webUrl, controller: this.controller })
      .flexGrow(1)

      Button('返回', { type: ButtonType.Normal })
        .fontSize(14)
        .width('100%')
        .fontColor(Color.White)
        .backgroundColor('#40A9FF')
        .onClick(this.handleBack)
    }
    .width('80%')
    .height('80%')
    .backgroundColor(Color.White)
    .borderRadius(12)
  }

  @Builder
  AgreementGuide() {
    Flex({direction: FlexDirection.Column}) {
      Column() {
        Text('个人隐私保护指引')
          .width('100%')
          .fontSize(16)
          .textAlign(TextAlign.Center)
          .fontWeight(FontWeight.Bold)
          .padding({ bottom: 10 })
          .borderWidth({ bottom: 1 })
          .borderColor('#EBEDF0')

        Text('欢迎使用小雅智能助手！')
          .fontSize(14)
          .width('100%')
          .margin({top: 10})

        Text() {
          Span('我们非常注重您的个人信息和隐私保护。为了在使用过程中提供稳定可靠的服务，请仔细充分阅读、理解并同意')
            .fontSize(14)
            .fontColor(Color.Grey)
          Span('《小雅用户服务协议》')
            .fontSize(14)
            .fontColor(Color.Blue)
            .onClick(() => this.showAgreement(this.Api_Context.getUserAgreement()))
          Span('和')
            .fontColor(Color.Grey)
            .fontSize(14)
          Span('《隐私政策》')
            .fontSize(14)
            .fontColor(Color.Blue)
            .onClick(() => this.showAgreement(this.Api_Context.getPrivacyPolicy()))
          Span('相关内容，以便了解我们收集、使用、存储信息及，对信息的保护措施。')
            .fontSize(14)
            .fontColor(Color.Grey)
        }
        .margin({top: 10})
      }
      .flexGrow(1)
      .padding(10)

      Flex() {
        Button('拒绝', { type: ButtonType.Normal })
          .fontSize(14)
          .flexGrow(1)
          .fontColor('#999999')
          .backgroundColor('#F5F5F5')
          .onClick(this.handleRefuse)

        Button('同意', { type: ButtonType.Normal })
          .fontSize(14)
          .flexGrow(1)
          .fontColor(Color.White)
          .backgroundColor('#40A9FF')
          .onClick(this.handleAgree)
      }
    }
    .width('80%')
    .height(300)
    .backgroundColor(Color.White)
    .borderRadius(12)
  }

  build() {
    NavDestination() {
      Row() {
        Column() {
          if (this.showWeb) {
            this.AgreementWeb()
          } else {
            this.AgreementGuide()
          }
        }
        .width('100%')
      }
      .height('100%')
      .backgroundColor(Color.Black)

    }
  }
}
