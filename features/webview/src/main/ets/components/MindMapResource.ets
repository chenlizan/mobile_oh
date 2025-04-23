import _ from '@wolfx/lodash'
import { Api_Context, AppIcon, CustomNavTitle, IconConstants, UserInfoModel } from '@xy/basic'
import { CustomLocalH5 } from './CustomLocalH5'
import { webview } from '@kit.ArkWeb'
import { KnowledgeBar } from './KnowledgeBar'
import { TaskFinishItem } from './TaskFinishItem'
import { display } from '@kit.ArkUI'

@Component
struct MindMapResource {
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @StorageLink('UserInfo') userInfo: UserInfoModel = new UserInfoModel()
  @State controller: webview.WebviewController = new webview.WebviewController()
  @State screenWidth: number = 0
  @State screenHeight: number = 0
  private param: Record<string, string | number | boolean | Record<string, string>> = {}

  aboutToAppear(): void {
    this.param = JSON.parse(String(this.pageInfos.getParamByName('mindMapResource')[0]))
    this.screenWidth = px2vp(display.getDefaultDisplaySync().width)
    this.screenHeight = px2vp(display.getDefaultDisplaySync().height)
  }

  getUrlPath() {
    const item = this.param.item as Record<string, string>
    const isSub = this.param.isSub
    const isCourse = this.param.isCourse
    const isDocument = this.param.isDocument
    const fromBridge = this.param.fromBridge

    let path = ''
    if (isCourse || fromBridge) {
      path = this.Api_Context.getApiPrefix('base_mobilepage') + 'mindmap/group/preview/' + item.id
      if (isSub) {
        path = this.Api_Context.getApiPrefix('base_mobilepage') + 'mindmap/subgroup/preview/' + item.id
      }
    } else if (isDocument) {
      path = `${this.Api_Context.getApiPrefix('base_mobilepage',)}mindmap/mynote/preview/${item.id}`
      if (item?.shared_from_type) {
        path =
          `${this.Api_Context.getApiPrefix('base_mobilepage',)}mindmap/share/preview/${item.root_node_id}/${item.id}/${this.userInfo.id}`
      }
    }

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
  }
}

@Builder
export function MindMapResourceBuilder() {
  MindMapResource()
}