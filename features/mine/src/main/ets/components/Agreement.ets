import { webview } from "@kit.ArkWeb";
import { TextModifier } from "@kit.ArkUI";

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
    .title(this.param.title,
      {
        mainTitleModifier: new TextModifier().fontColor('#404040').fontSize(16).fontWeight(FontWeight.Normal)
      })
    .backgroundColor("#f1f1f1")
  }
}

@Builder
export function AgreementBuilder() {
  Agreement()
}