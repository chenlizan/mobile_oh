import _ from '@wolfx/lodash'
import { webview } from '@kit.ArkWeb'
import { AppIcon, CustomNavTitle, IconConstants, judgeGroupIsEnd, PreferenceStorage } from '@xy/basic'
import { CustomLocalH5 } from './CustomLocalH5'

@Component
struct H5Resource {
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @StorageLink('PreferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage()
  @State controller: webview.WebviewController = new webview.WebviewController()
  private param: Record<string, string | number | boolean | Record<string, string>> = {}

  aboutToAppear(): void {
    this.param = JSON.parse(String(this.pageInfos.getParamByName('h5Resource')[0]))
  }

  getUrlPath() {
    let path = this.param.source_url as string
    return path;
  }

  injectedExtraJavaScript = () => {
    const currentTeam = this.preferenceStorage.currentTeam
    let extra = ''
    if (!_.isEmpty(currentTeam)) {
      extra += `window.courseEnd=${judgeGroupIsEnd(currentTeam as Record<string, string>, false)}`
    }
    return `${extra}`
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
        url: this.getUrlPath(),
        extraJavaScript: this.injectedExtraJavaScript(),
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