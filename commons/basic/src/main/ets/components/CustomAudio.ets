@Component
export struct CustomAudio {
  @Link currentTime: string
  @Link totalTime: string
  @Link value: number
  @Link max: number
  @Link playing: boolean
  onPlay: () => void = () => {
  }
  onPause: () => void = () => {
  }
  onChange: (value: number, mode: SliderChangeMode) => void = () => {
  }

  build() {
    Flex({ direction: FlexDirection.Column }) {
      Column() {
        Image($r('app.media.audio_bg'))
          .width(100)
      }
      .width('100%')
      .flexGrow(2)
      .justifyContent(FlexAlign.Center)

      Column() {
        Slider({ value: this.value, max: this.max })
          .margin({ left: 24, right: 24 })
          .blockSize({ width: 20, height: 20 })
          .blockColor('#40A9FF')
          .selectedColor('#40A9FF')
          .trackThickness(6)
          .onChange((value: number, mode: SliderChangeMode) => {
            this.onChange(value, mode)
          })

        Row() {
          Text(this.currentTime)
            .fontColor("#999999")
            .fontSize(10)
            .fontFamily('HarmonyHeiTi')
            .lineHeight('14vp')
          Text(this.totalTime)
            .fontColor("#999999")
            .fontSize(10)
            .fontFamily('HarmonyHeiTi')
            .lineHeight('14vp')
        }
        .padding({ left: 30, right: 30 })
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)

        Image(this.playing ? $r('app.media.audio_pause') : $r('app.media.audio_play'))
          .width(80)
          .margin({ top: 60 })
          .onClick(() => {
            if (this.playing) {
              this.onPause()
              this.playing = false
            } else {
              this.onPlay()
              this.playing = true
            }
          })
      }
      .flexGrow(1)
    }
    .height('100%')
    .backgroundColor(Color.White)
  }
}