import { webview } from "@kit.ArkWeb"
import _ from "@wolfx/lodash"
import {
  Api_Context,
  CustomNavTitle,
  CustomToast,
  HomeApi,
  PreferenceStorage,
  UserInfoModel,
  xyApiGet
} from "@xy/basic"

@Component
struct AIHelper {
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @StorageLink('PreferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage()
  @StorageLink('UserInfo') userInfo: UserInfoModel = new UserInfoModel()
  @State source_url: string = ''
  private controller: webview.WebviewController = new webview.WebviewController()

  async aboutToAppear() {
    this.source_url = await this.getChatUiUrl()
    this.controller.loadUrl(this.source_url)
  }

  async queryDeepThinkModel() {
    const response = await xyApiGet(this.Api_Context.getApiPrefix('baseApi_out') + HomeApi.queryDeepThinkModel)
    if (response.success) {
      return !!(response.data as Record<string, boolean>)?.deep_think_mode
    } else {
      return false
    }
  }

  async getChatUiUrl(advanceManager = [], robotId = '8', currentTeam = null) {
    const access_token = this.preferenceStorage.access_token
    const refresh_token = this.preferenceStorage.refresh_token
    const chatApi = this.Api_Context.getApiPrefix('chatApi')
    if (!chatApi) {
      CustomToast.toast_info('智能助手服务异常，请返回总门户，重新选择学校加载相关服务')
      this.pageInfos.pop()
    }

    const deep_think_mode = await this.queryDeepThinkModel()
    const response = await xyApiGet(this.Api_Context.getAIGlobalConfig())
    if (response.code === 200) {
      const globalConfig = response.data as Record<string, string>
      const xy_ai_token = globalConfig.xy_ai_token
      const assistantSetting = _.find(this.userInfo.userFeatures, { menuCode: 'GN002' }) as Record<string, number>
      const conversationAssistant = _.find(this.userInfo.userFeatures, { menuCode: 'GN001' }) as Record<string, number>
      let hasOtherAssistant = assistantSetting?.status === 1
      let hasConversationAssistant = conversationAssistant?.status === 1
      let courseName = ''
      let group_id = ''
      let ragDatasetName = ''
      let ragAppId = ''

      return `${chatApi}?robotId=${robotId}&sessionId=${refresh_token}&xyBearer=${access_token}&group_id=${group_id}&courseName=${courseName}&aiServer=${this.Api_Context.getOpenApi()}&aiBearer=${xy_ai_token}&hasOtherAssitant=${hasOtherAssistant}&hasConversationAssistant=${hasConversationAssistant}&refresh=${Math.random()
        .toString(
          32,
        )}&deep_think_mode=${deep_think_mode}&ragDatasetName=${ragDatasetName}&ragAppId=${ragAppId}`
    }

    return `${chatApi}?robotId=${robotId}&sessionId=${refresh_token}&xyBearer=${access_token}&refresh=${Math.random()
      .toString(
        32,
      )}&deep_think_mode=${deep_think_mode}`
  }

  build() {
    NavDestination() {
      Web({
        src: this.source_url,
        controller: this.controller
      })
        .width('100%')
        .height('100%')
    }
    .title(CustomNavTitle('AI助手'))
    .backgroundColor("#f1f1f1")
  }
}

@Builder
export function AIHelperBuilder() {
  AIHelper()
}