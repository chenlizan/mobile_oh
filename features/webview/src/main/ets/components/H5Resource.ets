import _ from '@wolfx/lodash'
import { webview } from '@kit.ArkWeb'
import { AppIcon, CustomNavTitle, IconConstants } from '@xy/basic'
import { CustomLocalH5 } from './CustomLocalH5'

@Component
struct H5Resource {
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @State controller: webview.WebviewController = new webview.WebviewController()
  private param: Record<string, string | number | boolean | Record<string, string>> = {}

  aboutToAppear(): void {
    this.param = JSON.parse(String(this.pageInfos.getParamByName('h5Resource')[0]))
  }

  getUrlPath() {
    let path = this.param.source_url as string
    return path;
  }

  @Builder
  BuildNavRightBtn() {
    Row() {
      // AppIcon({
      //   iconCode: IconConstants.WATCH,
      //   iconColor: '#999999',
      //   iconSize: 16,
      //   onClickBtn: () => {
      //   }
      // })
      AppIcon({
        iconCode: IconConstants.REFRESH,
        iconColor: '#999999',
        iconSize: 16,
        onClickBtn: () => {
          this.controller.refresh()
        }
      })
    }
  }

  build() {
    NavDestination() {
      CustomLocalH5({
        controller: this.controller,
        url: this.getUrlPath()
      })
    }
    .title(CustomNavTitle(this.param.title as string, () => this.BuildNavRightBtn()))
    .hideTitleBar(this.param.hideNav as boolean)
  }
}

@Builder
export function H5ResourceBuilder() {
  H5Resource()
}