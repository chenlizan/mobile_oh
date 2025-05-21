import { CustomLocalH5 } from "./CustomLocalH5"
import { webview } from "@kit.ArkWeb"
import { PreferenceStorage, UserInfoModel } from "@xy/basic"

@Component
struct QuestionEditorResource {
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @StorageLink('PreferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage()
  @StorageLink('UserInfo') userInfo: UserInfoModel = new UserInfoModel()
  @State controller: webview.WebviewController = new webview.WebviewController()
  private param: Record<string, string | number | boolean | Record<string, string>> = {}

  aboutToAppear(): void {
    this.param = JSON.parse(String(this.pageInfos.getParamByName('questionEditorResource')[0]))
  }

  getUrlPath() {
    const item = this.param.item as Record<string, string>
    const courseInfo = this.preferenceStorage.currentTeam?? {}
    let path = `#/examEditor/${courseInfo.id}/${item.quote_id}`
    path += '?placeholder=1'
    return path
  }

  build() {
    NavDestination() {
      Flex({ direction: FlexDirection.Column }) {
        CustomLocalH5({
          url: this.getUrlPath(),
          controller: this.controller
        })
      }
    }
    .hideTitleBar(true)
  }
}

@Builder
export function QuestionEditorResourceBuilder () {
  QuestionEditorResource()
}