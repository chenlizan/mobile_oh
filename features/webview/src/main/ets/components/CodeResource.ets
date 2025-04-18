import { webview } from '@kit.ArkWeb'
import { window } from '@kit.ArkUI'
import _ from '@wolfx/lodash'
import {
  AppIcon,
  CustomLocalH5,
  CustomNavTitle,
  DownloadToLocal,
  getExtension,
  IconConstants,
  judgeCourseIsSP,
  judgeRoleHasCourseOperationWeight,
  PreferenceStorage
} from '@xy/basic'

@Component
struct CodeResource {
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @StorageLink('PreferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage()
  @State controller: webview.WebviewController = new webview.WebviewController()
  @State canDownload: boolean = false
  private param: Record<string, string | number | boolean | Record<string, string>> = {}

  aboutToAppear(): void {
    const currentTeam = this.preferenceStorage.currentTeam
    this.param = JSON.parse(String(this.pageInfos.getParamByName('codeResource')[0]))
    const item = this.param.item as Record<string, string | number>
    this.canDownload =
      judgeRoleHasCourseOperationWeight(this.param.loginRole as number) ||
        ((item.is_copyable || item.download === 2 || this.param.fromBridge || this.param.isDocument) &&
          (this.param.loginRole === 1 ||
            (judgeCourseIsSP(currentTeam as Record<string, number>) && this.param.loginRole !== 7))) as boolean
  }

  getUrlPath() {
    const item = this.param.item as Record<string, string>
    let path = `#/CodeFilesViewer/${item.quote_id}/${getExtension(item.name,)}`
    return path
  }

  @Builder
  BuildNavRightBtn() {
    if (this.canDownload) {
      AppIcon({
        iconCode: IconConstants.DOWNLOAD,
        iconColor: '#999999',
        iconSize: 16,
        onClickBtn: () => {
          DownloadToLocal(this.param.item as Record<string, string | number>)
        }
      })
    }
    AppIcon({
      iconCode: IconConstants.REFRESH,
      iconColor: '#999999',
      iconSize: 16,
      onClickBtn: () => {
        this.controller.refresh()
      }
    })
    AppIcon({
      iconCode: IconConstants.ROTATION,
      iconColor: '#999999',
      iconSize: 16,
      onClickBtn: async () => {
        const windowClass = await window.getLastWindow(getContext())
        if (windowClass.getPreferredOrientation() === window.Orientation.PORTRAIT) {
          windowClass.setPreferredOrientation(window.Orientation.LANDSCAPE)
        } else {
          windowClass.setPreferredOrientation(window.Orientation.PORTRAIT)
        }
      }
    })
  }

  build() {
    NavDestination() {
      CustomLocalH5({
        url: this.getUrlPath(),
      })
    }
    .title(CustomNavTitle(this.param.name as string, () => this.BuildNavRightBtn()))
    .hideTitleBar(true)
  }
}

@Builder
export function CodeResourceBuilder() {
  CodeResource()
}