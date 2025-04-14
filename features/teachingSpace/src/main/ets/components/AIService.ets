import { Api_Context, CustomNavTitle, PreferenceStorage } from "@xy/basic"
import { webview } from "@kit.ArkWeb"

@Component
struct AIService {
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @StorageLink('PreferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage()
  @State source_url: string = ''
  private controller: webview.WebviewController = new webview.WebviewController()

  aboutToAppear(): void {
    const faqDomain = this.Api_Context.getFaqDomain()
    const access_token = this.preferenceStorage.access_token
    this.source_url =
      `${faqDomain}/index.html?xyBearer=${access_token}&lang=zh-CN&faqBaseUrl=${faqDomain}/user-oriented/api/v1&baseUrl=${this.Api_Context.getApiPrefix('hostApi')}&refresh=${Math.random()
        .toString(32)}`
  }

  build() {
    NavDestination() {
      Web({
        src: this.source_url,
        controller: this.controller
      })
        .width('100%')
        .height('100%')
    }
    .title(CustomNavTitle('系统帮助'))
    .backgroundColor("#f1f1f1")
  }
}

@Builder
export function AIServiceBuilder() {
  AIService()
}