import { vibrator } from "@kit.SensorServiceKit"

@Component
export struct CustomDatePickerDialog {
  @BuilderParam titleBuilder?: CustomBuilder
  @BuilderParam contentBuilder?: CustomBuilder
  @Link @Watch("visibleChange") visible: boolean
  @Link title: string
  @Prop dialogHeight: Length = 280
  onOkBtn: (value: Date) => void = () => {
  }
  onCloseBtn: () => void = () => {
  }
  dialogController: CustomDialogController = new CustomDialogController({
    builder: CustomDatePickerDialogView({
      titleBuilder: this.titleBuilder,
      contentBuilder: this.contentBuilder,
      visible: this.visible,
      title: this.title,
      dialogHeight: this.dialogHeight,
      onOkBtn: this.onOkBtn,
      onCloseBtn: this.onCloseBtn
    }),
    alignment: DialogAlignment.Bottom,
    customStyle: true,
    cancel: () => this.visible = false,
    closeAnimation: { duration: 0 }
  })

  visibleChange() {
    if (this.visible) {
      this.dialogController?.open()
    } else {
      this.dialogController?.close()
    }
  }

  build() {
  }
}

@CustomDialog
struct CustomDatePickerDialogView {
  @BuilderParam titleBuilder?: CustomBuilder
  @BuilderParam contentBuilder?: CustomBuilder
  @Link visible: boolean
  title?: string
  dialogHeight?: Length
  onOkBtn: (value: Date) => void = () => {
  }
  onCloseBtn: () => void = () => {
  }
  private controller?: CustomDialogController
  private value: Date = new Date()

  build() {
    Column() {
      if (typeof this.titleBuilder === 'function') {
        this.titleBuilder()
      } else {
        Row() {
          Button('取消', { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.TEXTUAL })
            .height(40)
            .fontColor('#40A9FF')
            .onClick(() => {
              this.visible = false
              this.onCloseBtn()
            })

          Text(this.title)

          Button('确定', { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.TEXTUAL })
            .height(40)
            .fontColor('#40A9FF')
            .onClick(() => {
              this.visible = false
              this.onOkBtn(this.value)
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceAround)
      }

      Row() {
        Row() {
        }
        .height(1)
        .borderWidth({ top: 1 })
        .layoutWeight(1)
        .borderColor('#33999999')
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      DatePicker()
        .padding({
          left: 30,
          right: 30,
          top: 20,
          bottom: 20
        })
        .onDateChange((value: Date) => {
          this.value = value
          vibrator.startVibration({ type: 'preset', effectId: 'haptic.effect.soft' }, { id: 0, usage: 'touch' })
        })
    }
    .height(this.dialogHeight)
    .borderRadius(8)
    .backgroundColor(Color.White)
    .transition(TransitionEffect.move(TransitionEdge.BOTTOM).animation({ duration: 300 }))
  }
}