import { display, window } from "@kit.ArkUI"
import { common } from "@kit.AbilityKit"
import {
  Api_Context,
  AppIcon,
  CustomNavTitle,
  decryptOffice365DES,
  DownloadToLocal,
  HomeApi,
  IconConstants,
  judgeCourseIsSP,
  judgeRoleHasCourseOperationWeight,
  PreferenceStorage,
  UserInfoModel,
  xyApiGet
} from "@xy/basic"
import { KnowledgeBar } from "./KnowledgeBar"
import { TaskFinishItem } from "./TaskFinishItem"
import { image } from "@kit.ImageKit"
import axios, { AxiosResponse } from "@ohos/axios"

const context: Context = getContext(this)

@Component
struct ImageResource {
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @StorageLink('PreferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage()
  @StorageLink('UserInfo') userInfo: UserInfoModel = new UserInfoModel()
  @State canDownload: boolean = false
  @State screenWidth: number = 0
  @State screenHeight: number = 0
  @State imageData: PixelMap | ResourceStr | DrawableDescriptor | null = null
  @State imageWHRatio: number = 0
  @State preAngle: number = 0
  @State preScale: number = 1
  private param: Record<string, string | number | boolean | Record<string, string>> = {}
  private windowClass = (context as common.UIAbilityContext).windowStage.getMainWindowSync()

  aboutToAppear(): void {
    const currentTeam = this.preferenceStorage.currentTeam
    this.param = JSON.parse(String(this.pageInfos.getParamByName('imageResource')[0]))
    const item = this.param.item as Record<string, string | number>
    this.canDownload =
      judgeRoleHasCourseOperationWeight(this.param.loginRole as number) ||
        ((item.is_copyable || item.download === 2 || this.param.fromBridge || this.param.isDocument) &&
          (this.param.loginRole === 1 ||
            (judgeCourseIsSP(currentTeam as Record<string, number>) && this.param.loginRole !== 7))) as boolean
    this.screenWidth = px2vp(display.getDefaultDisplaySync().width)
    this.screenHeight = px2vp(display.getDefaultDisplaySync().height)
    this.queryResourceInfo()
  }

  async queryResourceInfo() {
    const item = this.param.item as Record<string, string | number>
    if (item.url) {
      this.imageData = item.url as ResourceStr
      this.initCurrentImageInfo()
    } else {
      const response =
        await xyApiGet(this.Api_Context.getApiPrefix('baseApi_out') + HomeApi.cloudFileUrl + item.quote_id)
      if (response?.success) {
        const data = (response?.data ?? {}) as Record<string, string>
        if (data?.audio_transcode_url) {
          data.real_url = data?.is_encryption
            ? decryptOffice365DES(data.audio_transcode_url)
            : data.audio_transcode_url
        } else if (data?.url) {
          data.real_url = data?.is_encryption
            ? decryptOffice365DES(data.url)
            : data.url
        } else {
          data.real_url = ''
        }
        this.imageData = data.real_url
        this.initCurrentImageInfo()
      }
    }
  }

  initCurrentImageInfo() {
    axios<string, AxiosResponse<string>, null>({
      url: this.imageData as string,
      method: 'get',
      responseType: 'array_buffer',
    }).then((res: AxiosResponse) => {
      const imageSource = image.createImageSource(res.data)
      imageSource.getImageInfo(0)
        .then((data: image.ImageInfo) => {
          this.imageWHRatio = data.size.width / data.size.height;
        })
    })
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
          this.preAngle = 0
          this.preScale = 1
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
        Column() {
          Image(this.imageData)
            .width(this.screenWidth / 2)
            .height((this.screenWidth / 2) / this.imageWHRatio)
            .rotate({ angle: this.preAngle })
            .scale({ x: this.preScale, y: this.preScale })
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .flexGrow(1)
        .parallelGesture(
          GestureGroup(GestureMode.Exclusive,
            PinchGesture()
              .onActionUpdate((event?: GestureEvent) => {
                if (event) {
                  this.preScale = event.scale
                }
              }),
            RotationGesture()
              .onActionUpdate((event?: GestureEvent) => {
                if (event) {
                  this.preAngle = event.angle
                }
              })
          ))
        .backgroundColor(Color.Black)

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
export function ImageResourceBuilder() {
  ImageResource()
}