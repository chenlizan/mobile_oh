import _ from '@wolfx/lodash'
import { Api_Context, CustomLocalH5, UserInfoModel } from '@xy/basic'

@Component
struct MindMapResource {
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @StorageLink('UserInfo') userInfo: UserInfoModel = new UserInfoModel()
  private param: Record<string, string | number | boolean | Record<string, string>> = {}

  aboutToAppear(): void {
    this.param = JSON.parse(String(this.pageInfos.getParamByName('mindMapResource')[0]))
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

  build() {
    NavDestination() {
      CustomLocalH5({
        url: this.getUrlPath()

      })
    }
    .hideTitleBar(true)
  }
}

@Builder
export function MindMapResourceBuilder() {
  MindMapResource()
}