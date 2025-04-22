import _ from '@wolfx/lodash'
import { common } from '@kit.AbilityKit'
import { webview } from '@kit.ArkWeb'
import { display, window } from '@kit.ArkUI'
import { CustomLocalH5 } from './CustomLocalH5'
import { KnowledgeBar } from './KnowledgeBar'
import { TaskFinishItem } from './TaskFinishItem'
import {
  AppIcon,
  CustomNavTitle,
  DownloadToLocal,
  getExtension,
  IconConstants,
  judgeCourseIsSP,
  judgeRoleHasCourseOperationWeight,
  PreferenceStorage
} from '@xy/basic'

const context: Context = getContext(this)

@Component
struct CodeResource {
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @StorageLink('PreferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage()
  @State controller: webview.WebviewController = new webview.WebviewController()
  @State canDownload: boolean = false
  @State screenWidth: number = 0
  @State screenHeight: number = 0
  private param: Record<string, string | number | boolean | Record<string, string>> = {}
  private windowClass = (context as common.UIAbilityContext).windowStage.getMainWindowSync()

  aboutToAppear(): void {
    const currentTeam = this.preferenceStorage.currentTeam
    this.param = JSON.parse(String(this.pageInfos.getParamByName('codeResource')[0]))
    const item = this.param.item as Record<string, string | number>
    this.canDownload =
      judgeRoleHasCourseOperationWeight(this.param.loginRole as number) ||
        ((item.is_copyable || item.download === 2 || this.param.fromBridge || this.param.isDocument) &&
          (this.param.loginRole === 1 ||
            (judgeCourseIsSP(currentTeam as Record<string, number>) && this.param.loginRole !== 7))) as boolean
    this.screenWidth = px2vp(display.getDefaultDisplaySync().width)
    this.screenHeight = px2vp(display.getDefaultDisplaySync().height)
  }

  getUrlPath() {
    const item = this.param.item as Record<string, string>
    let path = `#/CodeFilesViewer/${item.quote_id}/${getExtension(item.name)}`
    path += '?placeholder=1'
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
      iconMargin: { left: 8 },
      onClickBtn: () => {
        this.controller.refresh()
      }
    })
    AppIcon({
      iconCode: IconConstants.ROTATION,
      iconColor: '#999999',
      iconSize: 16,
      iconMargin: { left: 8 },
      onClickBtn: async () => {
        if (this.windowClass.getPreferredOrientation() === window.Orientation.LANDSCAPE) {
          this.windowClass.setPreferredOrientation(window.Orientation.PORTRAIT)
        } else {
          this.windowClass.setPreferredOrientation(window.Orientation.LANDSCAPE)
        }
      }
    })
  }

  build() {
    NavDestination() {
      Flex({ direction: FlexDirection.Column }) {
        CustomLocalH5({
          url: this.getUrlPath(),
          controller: $controller
        })
        if (!this.param.isSub && !this.param.isDocument && !this.param.fromBridge) {
          KnowledgeBar({ item: this.param.item as Record<string, string>, loginRole: this.param.loginRole as number })
        }
      }
      if (this.param.showFinish) {
        TaskFinishItem({
          imgOffSetX: this.screenWidth - 70,
          imgOffSetY: this.screenHeight - 260,
          isSub: this.param.isSub as boolean,
          item: this.param.item as Record<string, string>
        })
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
export function CodeResourceBuilder() {
  CodeResource()
}