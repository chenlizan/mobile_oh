import { display, window } from '@kit.ArkUI'
import { AliPlayerFactory, AliPlayer, InfoBean, InfoCode, VidAuth } from 'premierlibrary'
import { UrlSource } from 'premierlibrary/src/main/ets/com/aliyun/player/source/UrlSource'
import { CustomToast } from '../../../../Index'

function fill(value: number): string {
  return value.toString().padStart(2, '0')
}

function msToCountdownTime(ms: number): string {
  if (!ms) {
    return '00:00:00'
  }

  const days = Math.floor(ms / (1000 * 60 * 60 * 24))
  const hours = Math.floor((ms % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60))
  const minutes = Math.floor((ms % (1000 * 60 * 60)) / (1000 * 60))
  const seconds = Math.floor((ms % (1000 * 60)) / 1000)
  return `${(days ? fill(days) + ':' : '')}${(fill(hours))}:${fill(minutes)}:${fill(seconds)} `.trim()
}

@Observed
export class AuthInfo {
  public videoId: string = ''
  public playAuth: string = ''
  public position: number = 0

  constructor(videoId: string, playAuth: string, position: number) {
    this.videoId = videoId
    this.playAuth = playAuth
    this.position = position
  }
}

@Component
export struct CustomVideo {
  private xComponentController = new XComponentController()
  private aliPlayer: AliPlayer = AliPlayerFactory.createAliPlayer(getContext(), '')
  @State screenWidth: number = 0
  @State screenHeight: number = 0
  @State currentTime: string = '00:00:00'
  @State totalTime: string = '00:00:00'
  @State progress: number = 0
  @State progressMax: number = 0
  @State playing: boolean = false
  @State speed: number = 1.0
  @State fullscreen: boolean = false
  @State showBar: boolean = true
  @ObjectLink @Watch('onAuthInfoChange') authInfo: AuthInfo
  onFullscreen: (v: boolean) => void = () => {
  }

  initPlayerEventListeners() {
    if (this.aliPlayer) {
      this.aliPlayer.setOnInfoListener({
        onInfo: (bean: InfoBean) => {
          if (bean.getCode() === InfoCode.CurrentPosition) {
            let time: number = bean.getExtraValue()
            this.currentTime = msToCountdownTime(time)
            this.progress = time
          }
        }
      })
      this.aliPlayer.setOnStateChangedListener({
        onStateChanged: (status: number) => {
          let toastStatus: string = ""
          switch (status) {
            case -1:
              toastStatus = "未知"
              break
            case 0:
              toastStatus = "空状态"
              break
            case 1:
              toastStatus = "初始化"
              CustomToast.toast_loading('')
              break
            case 2:
              toastStatus = "准备成功"
              this.totalTime = msToCountdownTime(this.aliPlayer.getDuration())
              this.progressMax = this.aliPlayer.getDuration()
              CustomToast.hide()
              break
            case 3:
              toastStatus = "正在播放"
              this.playing = true
              this.hideBar()
              break
            case 4:
              toastStatus = "已暂停"
              this.playing = false
              break
            case 5:
              toastStatus = "已停止"
              break
            case 6:
              toastStatus = "播放完成"
              this.playing = false
              this.aliPlayer.seekTo(0, 1)
              break
            case 7:
              toastStatus = "播放出错"
              break
            default:
              toastStatus = "未知"
              break
          }
        }
      })
    }
  }

  hideBar() {
    setTimeout(() => {
      this.showBar = false
    }, 4000)
  }

  onAuthInfoChange() {
    const vidAuthSource: VidAuth = new VidAuth()
    vidAuthSource.setVid(this.authInfo.videoId)
    vidAuthSource.setPlayAuth(this.authInfo.playAuth)
    this.aliPlayer.setVidAuthDataSource(vidAuthSource)
    this.aliPlayer.prepare()
  }

  aboutToAppear(): void {
    this.screenWidth = px2vp(display.getDefaultDisplaySync().width)
    this.screenHeight = px2vp(display.getDefaultDisplaySync().height)
    display.on('change', () => {
      this.screenWidth = px2vp(display.getDefaultDisplaySync().width)
      this.screenHeight = px2vp(display.getDefaultDisplaySync().height)
    })
    this.initPlayerEventListeners()
  }

  build() {
    Column() {
      Stack({ alignContent: Alignment.Bottom }) {
        XComponent({
          id: '0',
          type: XComponentType.SURFACE,
          libraryname: 'premierlibrary',
          controller: this.xComponentController,
        })
          .onLoad(async () => {
            this.aliPlayer.setSurfaceId('0')
            this.aliPlayer.setAutoPlay(true)
          })
          .width(this.screenWidth)
          .height(this.fullscreen ? this.screenHeight : (this.screenWidth * 9) / 16)
        Flex({ alignItems: ItemAlign.Center }) {
          Image(this.playing ? $r('app.media.pause') : $r('app.media.play'))
            .flexBasis(50)
            .onClick(() => {
              if (this.playing) {
                this.aliPlayer.pause()
              } else {
                this.aliPlayer.start()
              }
            })
          Text(this.currentTime)
            .fontColor(Color.White)
            .fontSize(10)
            .flexBasis(80)
            .textAlign(TextAlign.Center)
          Slider({ value: this.progress, max: this.progressMax })
            .selectedColor(Color.White)
            .onChange((value: number, mode: SliderChangeMode) => {
              if (mode === SliderChangeMode.End || mode === SliderChangeMode.Begin) {
                this.aliPlayer?.seekTo(value, 1)
              }
            })
            .flexGrow(1)
          Text(this.totalTime)
            .fontColor(Color.White)
            .fontSize(10)
            .flexBasis(80)
            .textAlign(TextAlign.Center)
          Text(this.speed === 1.0 ? '倍数' : this.speed.toFixed(1))
            .fontColor(Color.White)
            .fontSize(12)
            .flexBasis(80)
            .textAlign(TextAlign.Center)
            .onClick(() => {
              let currSpeed = this.speed
              let newSpeed: number = 1.0
              if (currSpeed == 1.0) {
                newSpeed = 1.5
              } else if (currSpeed == 1.5) {
                newSpeed = 2.0
              } else if (currSpeed == 2.0) {
                newSpeed = 0.5
              } else if (currSpeed == 0.5) {
                newSpeed = 1.0
              }
              this.speed = newSpeed
              this.aliPlayer.setSpeed(newSpeed)
            })
          Image(this.fullscreen ? $r('app.media.exitfullscreen') : $r('app.media.fullscreen'))
            .flexBasis(50)
            .onClick(async () => {
              const windowClass = await window.getLastWindow(getContext())
              if (this.fullscreen) {
                windowClass.setPreferredOrientation(window.Orientation.PORTRAIT)
                windowClass.setWindowSystemBarEnable(['navigation', 'status'])
              } else {
                windowClass.setPreferredOrientation(window.Orientation.LANDSCAPE)
                windowClass.setWindowSystemBarEnable([])
              }
              this.fullscreen = !this.fullscreen
              this.onFullscreen(this.fullscreen)
            })
        }
        .margin({ left: 8, right: 8 })
        .visibility(this.showBar ? Visibility.Visible : Visibility.Hidden)
      }
      .gesture(
        TapGesture({ count: 1 })
          .onAction((event: GestureEvent) => {
            if (event) {
              this.showBar = true
              this.hideBar()
            }
          })
      )
    }
  }

  aboutToDisappear(): void {
    if (this.aliPlayer) {
      this.aliPlayer.stop()
      this.aliPlayer.release()
    }
  }
}