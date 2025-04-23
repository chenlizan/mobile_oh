import _ from '@wolfx/lodash'
import { CustomLocalH5 } from './CustomLocalH5'
import { webview } from '@kit.ArkWeb'
import { KnowledgeBar } from './KnowledgeBar'
import { AppIcon, CustomNavTitle, IconConstants } from '@xy/basic'
import { common } from '@kit.AbilityKit'
import { window } from '@kit.ArkUI'

const context: Context = getContext(this)

@Component
struct TeachDesignResource {
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @State controller: webview.WebviewController = new webview.WebviewController()
  private param: Record<string, string | number | boolean | Record<string, string>> = {}
  private windowClass = (context as common.UIAbilityContext).windowStage.getMainWindowSync()

  aboutToAppear(): void {
    this.param = JSON.parse(String(this.pageInfos.getParamByName('teachDesignResource')[0]))
  }

  getUrlPath() {
    const item = this.param.item as Record<string, string>
    let path = `#/paper_mobile/teach_design/${item.quote_id}`
    return path
  }

  @Builder
  BuildNavRightBtn() {
    Row() {
      AppIcon({
        iconCode: IconConstants.REFRESH,
        iconColor: '#999999',
        iconSize: 16,
        iconMargin: { right: 10 },
        onClickBtn: () => {
          this.controller.refresh()
        }
      })
      AppIcon({
        iconCode: IconConstants.ROTATION,
        iconColor: '#999999',
        iconSize: 16,
        onClickBtn: async () => {
          if (this.windowClass.getPreferredOrientation() === window.Orientation.LANDSCAPE) {
            this.windowClass.setPreferredOrientation(window.Orientation.PORTRAIT)
          } else {
            this.windowClass.setPreferredOrientation(window.Orientation.LANDSCAPE)
          }
        }
      })
    }
  }

  build() {
    NavDestination() {
      Flex({ direction: FlexDirection.Column }) {
        CustomLocalH5({
          url: this.getUrlPath(),
          controller: this.controller
        })
        if (!this.param.isSub && !this.param.isDocument && !this.param.fromBridge) {
          KnowledgeBar({ item: this.param.item as Record<string, string>, loginRole: this.param.loginRole as number })
        }
      }
    }
    .title(CustomNavTitle((this.param.item as Record<string, string>).name, () => this.BuildNavRightBtn()))
    .onBackPressed(() => {
      if (this.windowClass.getPreferredOrientation() === window.Orientation.LANDSCAPE) {
        this.windowClass.setPreferredOrientation(window.Orientation.PORTRAIT)
      }
      return false
    })
  }
}

@Builder
export function TeachDesignResourceBuilder() {
  TeachDesignResource()
}