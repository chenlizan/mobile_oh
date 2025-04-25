import { display } from "@kit.ArkUI"
import { media } from "@kit.MediaKit"
import { request } from "@kit.BasicServicesKit"
import { common } from "@kit.AbilityKit"
import { fileIo } from "@kit.CoreFileKit"
import {
  Api_Context,
  AppIcon,
  CustomAudio,
  CustomNavTitle,
  CustomToast,
  DownloadToLocal,
  IconConstants,
  judgeCourseIsSP,
  judgeRoleHasCourseOperationWeight,
  PreferenceStorage,
  queryResourceInfo,
  UserInfoModel
} from "@xy/basic"
import { KnowledgeBar } from "./KnowledgeBar"
import { TaskFinishItem } from "./TaskFinishItem"

enum AvplayerStatus {
  IDLE = 'idle',
  INITIALIZED = 'initialized',
  PREPARED = 'prepared',
  PLAYING = 'playing',
  PAUSED = 'paused',
  COMPLETED = 'completed',
  STOPPED = 'stopped',
  RELEASED = 'released',
  ERROR = 'error'
}

enum Events {
  STATE_CHANGE = 'stateChange',
  TIME_UPDATE = 'timeUpdate',
  ERROR = 'error'
}

function fill(value: number): string {
  return value.toString().padStart(2, '0')
}

function msToCountdownTime(ms: number): string {
  if (!ms) {
    return '00:00'
  }

  const days = Math.floor(ms / (1000 * 60 * 60 * 24))
  const hours = Math.floor((ms % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60))
  const minutes = Math.floor((ms % (1000 * 60 * 60)) / (1000 * 60))
  const seconds = Math.floor((ms % (1000 * 60)) / 1000)
  return `${(days ? fill(days) + ':' : '')}${(hours ? fill(hours) + ':' : '')}
      ${fill(minutes)}:${fill(seconds)} `.trim()
}

@Component
struct AudioResource {
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @StorageLink('PreferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage()
  @StorageLink('UserInfo') userInfo: UserInfoModel = new UserInfoModel()
  @State canDownload: boolean = false
  @State screenWidth: number = 0
  @State screenHeight: number = 0
  @State url: string = ''
  private param: Record<string, string | number | boolean | Record<string, string>> = {}
  private avPlayer: media.AVPlayer | null = null
  private fdPath: string = 'fd://'
  @State currentTime: string = '00:00'
  @State totalTime: string = '00:00'
  @State progress: number = 0
  @State progressMax: number = 0
  @State playing: boolean = false

  async createAVPlayer() {
    this.avPlayer = await media.createAVPlayer()
    await this.bindState()
  }

  async bindState() {
    if (this.avPlayer === null) {
      return
    }
    this.avPlayer.on(Events.STATE_CHANGE, async (state: media.AVPlayerState) => {
      let avplayerStatus: string = state
      if (this.avPlayer === null) {
        return
      }
      switch (avplayerStatus) {
        case AvplayerStatus.IDLE:
          this.avPlayer.release()
          break
        case AvplayerStatus.INITIALIZED:
          this.avPlayer.prepare()
          break
        case AvplayerStatus.PREPARED:
          this.totalTime = msToCountdownTime(this.avPlayer.duration)
          this.progressMax = this.avPlayer.duration
          break
        case AvplayerStatus.PLAYING:
          break
        case AvplayerStatus.PAUSED:
          break
        case AvplayerStatus.COMPLETED:
          this.playing = false
          this.avPlayer.seek(0)
          break
        case AvplayerStatus.RELEASED:
          this.avPlayer.release()
          break
        default:
          break
      }
    })
    this.avPlayer.on(Events.TIME_UPDATE, (time: number) => {
      this.setProgress(time)
    })
    this.avPlayer.on(Events.ERROR, () => {
      CustomToast.toast_fail('播放失败')
    })
  }

  setProgress(time: number) {
    this.currentTime = msToCountdownTime(time)
    this.progress = time
  }

  async downloadFile() {
    const item = this.param.item as Record<string, string | number>
    const data = await queryResourceInfo(item.quote_id as string)
    if (data !== null) {
      try {
        const context = getContext() as common.UIAbilityContext
        const filesDir = context.filesDir
        const filePath = filesDir + '/' + item.name

        if (fileIo.accessSync(filePath)) {
          fileIo.unlinkSync(filePath)
        }

        const downloadTask: request.DownloadTask = await request.downloadFile(context, {
          url: data.real_url,
          filePath: filePath
        })

        await new Promise<void>((resolve, reject) => {
          downloadTask.on('complete', () => resolve())
          downloadTask.on('fail', (err) => reject(err))
        })

        const file = await fileIo.open(filePath)
        this.fdPath = this.fdPath + '' + file.fd
      } catch (e) {
      }
    }
  }

  async aboutToAppear(): Promise<void> {
    const currentTeam = this.preferenceStorage.currentTeam
    this.param = JSON.parse(String(this.pageInfos.getParamByName('audioResource')[0]))
    const item = this.param.item as Record<string, string | number>
    this.canDownload =
      judgeRoleHasCourseOperationWeight(this.param.loginRole as number) ||
        ((item.is_copyable || item.download === 2 || this.param.fromBridge || this.param.isDocument) &&
          (this.param.loginRole === 1 ||
            (judgeCourseIsSP(currentTeam as Record<string, number>) && this.param.loginRole !== 7))) as boolean
    this.screenWidth = px2vp(display.getDefaultDisplaySync().width)
    this.screenHeight = px2vp(display.getDefaultDisplaySync().height)
    await this.downloadFile()
    await this.createAVPlayer()
    if (this.avPlayer) {
      this.avPlayer.url = this.fdPath
    }
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
          this.playing = false
          this.avPlayer?.pause()
          this.avPlayer?.seek(0)
        }
      })
    }
  }

  build() {
    NavDestination() {
      Flex({ direction: FlexDirection.Column }) {
        CustomAudio({
          currentTime: $currentTime,
          totalTime: $totalTime,
          value: $progress,
          max: $progressMax,
          playing: $playing,
          onPlay: () => {
            this.avPlayer?.play()
          },
          onPause: () => {
            this.avPlayer?.pause()
          },
          onChange: (value: number, mode: SliderChangeMode) => {
            if (mode === SliderChangeMode.End || mode === SliderChangeMode.Begin) {
              this.avPlayer?.seek(value)
            }
          }
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
      this.avPlayer?.release()
      return false
    })
  }
}

@Builder
export function AudioResourceBuilder() {
  AudioResource()
}