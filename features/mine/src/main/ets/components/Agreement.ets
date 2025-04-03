import { webview } from "@kit.ArkWeb";
import { CustomNavTitle } from "@xy/basic";

@Component
export struct Agreement {
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack();
  private controller: webview.WebviewController = new webview.WebviewController();
  private param: Record<string, string> = {}

  aboutToAppear(): void {
    this.param = JSON.parse(String(this.pageInfos.getParamByName('agreement')[0]))
  }

  build() {
    NavDestination() {
      Web({
        src: this.param.url,
        controller: this.controller
      })
    }
    .title(CustomNavTitle(this.param.title))
    .backgroundColor("#f1f1f1")
  }
}

@Builder
export function AgreementBuilder() {
  Agreement()
}