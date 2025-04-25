import { common } from '@kit.AbilityKit'
import { display, window } from '@kit.ArkUI'
import { webview } from '@kit.ArkWeb'
import _ from '@wolfx/lodash'
import qs from '@open/qs'
import {
  Api_Context,
  AppIcon,
  CustomNavTitle,
  CustomToast,
  DownloadToLocal,
  getDefaultExtensionFromMimeType,
  getExtension,
  getOW365Setting,
  HomeApi,
  IconConstants,
  isOfficeFile,
  judgeCourseIsSP,
  judgeRoleHasCourseOperationWeight,
  PreferenceStorage,
  UserInfoModel,
  xyApiGet
} from '@xy/basic'
import { KnowledgeBar } from './KnowledgeBar'
import { TaskFinishItem } from './TaskFinishItem'

const context: Context = getContext(this)

@Component
struct OfficeResource {
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @StorageLink('PreferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage()
  @StorageLink('UserInfo') userInfo: UserInfoModel = new UserInfoModel()
  @State canDownload: boolean = false
  @State screenWidth: number = 0
  @State screenHeight: number = 0
  private param: Record<string, string | number | boolean | Record<string, string>> = {}
  private windowClass = (context as common.UIAbilityContext).windowStage.getMainWindowSync()
  private controller: webview.WebviewController = new webview.WebviewController()

  async getOfficeUrl() {
    const item = this.param.item as Record<string, string>
    if (isOfficeFile(item.name, item.mimetype)) {
      const ow365_settings = getOW365Setting()
      const params: Record<string, string | number> = { 'i': ow365_settings?.account }

      let extName = '';

      if (item?.name?.indexOf('.') !== -1) {
        extName = getExtension(item?.name) as string
      }

      if (_.isEmpty(extName)) {
        extName = getDefaultExtensionFromMimeType(item?.mimetype) as string
      }

      let body: Record<string, string> = {};

      if (!_.isEmpty(extName)) {
        body = { 'filename': `${item?.quote_id}.${extName}` };
      }

      const response =
        await xyApiGet(this.Api_Context.getApiPrefix('baseApi_out') + HomeApi.cloudFileUrl + item.quote_id, body)
      if (response.success) {
        params.ssl = 1;
        params.furl = (response.data as Record<string, string>).url
      }

      this.controller.loadUrl(`${ow365_settings?.origin}?${qs.stringify(params)}`)
    }
  }

  aboutToAppear(): void {
    const currentTeam = this.preferenceStorage.currentTeam
    this.param = JSON.parse(String(this.pageInfos.getParamByName('officeResource')[0]))
    const item = this.param.item as Record<string, string | number>
    this.canDownload =
      judgeRoleHasCourseOperationWeight(this.param.loginRole as number) ||
        ((item.is_copyable || item.download === 2 || this.param.fromBridge || this.param.isDocument) &&
          (this.param.loginRole === 1 ||
            (judgeCourseIsSP(currentTeam as Record<string, number>) && this.param.loginRole !== 7))) as boolean
    this.screenWidth = px2vp(display.getDefaultDisplaySync().width)
    this.screenHeight = px2vp(display.getDefaultDisplaySync().height)
    this.getOfficeUrl()
  }

  @Builder
  BuildNavRightBtn() {
    Row() {
      if (this.canDownload) {
        AppIcon({
          iconCode: IconConstants.DOWNLOAD,
          iconColor: '#999999',
          iconSize: 16,
          iconMargin: { right: 10 },
          onClickBtn: () => {
            DownloadToLocal(this.param.item as Record<string, string | number>)
          }
        })
      }
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
        Web({ src: '', controller: this.controller })
          .width('100%')
          .flexGrow(1)
          .backgroundColor(Color.Black)
          .onControllerAttached(() => {
            CustomToast.toast_loading('')
          })
          .onPageEnd(() => {
            CustomToast.hide()
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
export function OfficeResourceBuilder() {
  OfficeResource()
}