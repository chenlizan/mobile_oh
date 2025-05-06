import { display } from '@kit.ArkUI'
import { KnowledgeBar } from './KnowledgeBar'
import { TaskFinishItem } from './TaskFinishItem'
import {
  Api_Context,
  AppIcon,
  AuthInfo,
  CustomNavTitle,
  CustomToast,
  CustomVideo,
  DownloadToLocal,
  HomeApi,
  IconConstants,
  judgeCourseIsSP,
  judgeRoleHasCourseOperationWeight,
  PreferenceStorage,
  UserInfoModel,
  xyApiGet
} from '@xy/basic'

@Component
struct VideoResource {
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @StorageLink('PreferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage()
  @StorageLink('UserInfo') userInfo: UserInfoModel = new UserInfoModel()
  @State isRefreshing: boolean = false
  @State canDownload: boolean = false
  @State screenWidth: number = 0
  @State screenHeight: number = 0
  @State fullscreen: boolean = false
  @State authInfo: AuthInfo = new AuthInfo('', '', 0)
  @State recordInfo: Record<string, string> = {}
  private param: Record<string, string | number | boolean | Record<string, string>> = {}

  async getGroupNode() {
    const item = this.param.item as Record<string, string>
    const response =
      await xyApiGet(this.Api_Context.getApiPrefix('baseApi_inner') + HomeApi.classResourceInfo, { 'node_id': item.id })
    if (response.success) {
      const resource = (response.data as Record<string, Record<string, string>>).resource
      await this.getVideoInfo(resource.video_id, resource.id)
    }
  }

  async getSubGroupNode() {
    const item = this.param.item as Record<string, string>
    const response = await xyApiGet(this.Api_Context.getApiPrefix('baseApi_inner') + HomeApi.subgroupResourceInfo,
      { 'node_id': item.id })
    if (response.success) {
      const resource = (response.data as Record<string, Record<string, string>>).resource
      await this.getVideoInfo(resource.video_id, resource.id)
    }
  }

  async getDocumentNode() {
    const item = this.param.item as Record<string, string>
    const body: Record<string, string | number> = { 'node_id': item.id }
    if (item?.shared_from_type) {
      if (item.shared_from_type === 'scan') {
        body.from_type = 1;
        body.from_user_id = this.userInfo.id;
      }
      const response = await xyApiGet(this.Api_Context.getApiPrefix('baseApi_inner') + HomeApi.queryNodeAnyway, body)
      if (response.success) {
        const resource = (response.data as Record<string, Record<string, string>>).resource
        await this.getVideoInfo(resource.video_id, resource.id)
      } else {
        if (response.code === 50001) {
          CustomToast.toast_info('没有权限访问此资源');
        } else {
          CustomToast.toast_info('未找到目标资源，可能文件被已删除或任务被撤销');
        }
      }
    } else {
      const response = await xyApiGet(this.Api_Context.getApiPrefix('baseApi_inner') + HomeApi.queryNode, body)
      if (response.success) {
        const res = response.data as Record<string, string>
        await this.getVideoInfo(res.video_id, res.id)
      }
    }
  }

  async getVideoInfo(video_id: string, media_id: string, needRecord: boolean = true) {
    const response = await xyApiGet(this.Api_Context.getApiPrefix('baseApi_out') + HomeApi.video_auth + video_id)
    if (response.success) {
      const authInfo = response.data as Record<string, string>
      if (!authInfo.play_auth) {
        CustomToast.toast_info('视频转码中，可稍后刷新进行播放！')
        return
      }
      if (needRecord) {
        const response =
          await xyApiGet(this.Api_Context.getApiPrefix('baseApi_inner') + HomeApi.video_record + media_id)
        if (response.success) {
          const recordInfo = response.data as Record<string, string>
          this.recordInfo = recordInfo
        }
      }
      this.authInfo = new AuthInfo(authInfo.video_id, authInfo.play_auth, 0)
    }
  }

  async handleRefresh() {
    const item = this.param.item as Record<string, string>
    if (this.param.fromBridge) {
      this.getVideoInfo(item.video_id, item.quote_id, false)
    } else if (this.param.isSub) {
      this.getSubGroupNode()
    } else if (this.param.isCourse) {
      this.getGroupNode()
    } else if (this.param.isDocument) {
      this.getDocumentNode()
    }
  }

  async aboutToAppear(): Promise<void> {
    const currentTeam = this.preferenceStorage.currentTeam
    this.param = JSON.parse(String(this.pageInfos.getParamByName('videoResource')[0]))
    const item = this.param.item as Record<string, string | number>
    this.canDownload =
      judgeRoleHasCourseOperationWeight(this.param.loginRole as number) ||
        ((item.is_copyable || item.download === 2 || this.param.fromBridge || this.param.isDocument) &&
          (this.param.loginRole === 1 ||
            (judgeCourseIsSP(currentTeam as Record<string, number>) && this.param.loginRole !== 7))) as boolean
    this.screenWidth = px2vp(display.getDefaultDisplaySync().width)
    this.screenHeight = px2vp(display.getDefaultDisplaySync().height)
    this.handleRefresh()
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
        }
      })
    }
  }

  build() {
    NavDestination() {
      Refresh({ refreshing: $$this.isRefreshing }) {
        Column() {
          CustomVideo({
            authInfo: this.authInfo,
            onFullscreen: (v: boolean) => {
              this.fullscreen = v
            }
          })
          if (!this.fullscreen && !this.param.isSub && !this.param.isDocument && !this.param.fromBridge) {
            KnowledgeBar({ item: this.param.item as Record<string, string>, loginRole: this.param.loginRole as number })
          }
        }
      }
      .height(this.screenHeight)
      .onRefreshing(() => {
        this.handleRefresh()
        setTimeout(() => {
          this.isRefreshing = false
        }, 500)
      })

      if (!this.fullscreen && this.param.showFinish) {
        TaskFinishItem({
          imgOffSetX: this.screenWidth - 70,
          imgOffSetY: this.screenHeight - 260,
          isSub: this.param.isSub as boolean,
          item: this.param.item as Record<string, string>
        })
      }
    }
    .hideTitleBar(this.fullscreen)
    .title(CustomNavTitle((this.param.item as Record<string, string>).name, () => this.BuildNavRightBtn()))
  }
}

@Builder
export function VideoResourceBuilder() {
  VideoResource()
}