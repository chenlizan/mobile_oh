import { IconConstants } from "../constants/IconConstants"
import { AppIcon } from "./AppIcon"

@Component
export struct CustomModalDialog {
  /**
   * 标题区域的builder
   */
  @BuilderParam titleBuilder?: CustomBuilder
  /**
   * 内容区域的builder
   */
  @BuilderParam contentBuilder?: CustomBuilder
  /**
   * 底部区域的builder
   */
  @BuilderParam footerBuilder?: CustomBuilder
  /**
   * 展示状态
   */
  @Link @Watch("visibleChange") visible: boolean
  /**
   * 启用模态框
   */
  @Prop isModal: boolean = true
  /**
   * 对话框高度
   */
  @Prop dialogHeight: Length = '30%'
  /**
   * 隐藏关闭按钮
   */
  @Prop hideCloseBtn: Visibility = Visibility.Visible
  /**
   * 隐藏分割线
   */
  @Prop hideDivider: Visibility = Visibility.Visible
  /**
   * 标题
   */
  @Link title: string
  /**
   * 弹框开启回调
   */
  onOpen: () => void = () => {
  }
  /**
   * 弹框关闭回调
   */
  onClose: () => void = () => {
  }
  /**
   * 关闭按钮
   */
  onCloseBtn: () => void = () => {
    this.visible = false
  }
  dialogController: CustomDialogController = new CustomDialogController({
    builder: CustomModalDialogView({
      titleBuilder: this.titleBuilder,
      contentBuilder: this.contentBuilder,
      footerBuilder: this.footerBuilder,
      title: this.title,
      dialogHeight: this.dialogHeight,
      hideCloseBtn: this.hideCloseBtn,
      hideDivider: this.hideDivider,
      onCloseBtn: this.onCloseBtn
    }),
    autoCancel: false,
    customStyle: true,
    isModal: this.isModal,
  })

  visibleChange() {
    if (this.visible) {
      this.dialogController?.open()
      this.onOpen()
    } else {
      this.dialogController?.close()
      this.onClose()
    }
  }

  build() {
  }
}

@CustomDialog
struct CustomModalDialogView {
  controller?: CustomDialogController;
  @BuilderParam titleBuilder?: CustomBuilder
  @BuilderParam contentBuilder?: CustomBuilder
  @BuilderParam footerBuilder?: CustomBuilder
  title?: string
  dialogHeight?: Length = '30%'
  hideCloseBtn?: Visibility = Visibility.Visible
  hideDivider?: Visibility = Visibility.Visible
  onCloseBtn: () => void = () => {
  }

  build() {
    Flex({ direction: FlexDirection.Column }) {
      if (typeof this.titleBuilder === 'function') {
        this.titleBuilder()
      } else {
        RelativeContainer() {
          Row() {
            Text(this.title)
              .fontWeight(FontWeight.Bold)
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)

          Row() {
            AppIcon({
              iconCode: IconConstants.CLOSE,
              iconSize: 20,
              iconColor: '#999999',
              onClickBtn: this.onCloseBtn
            })
              .visibility(this.hideCloseBtn)
          }
          .alignRules({
            top: { anchor: "__container__", align: VerticalAlign.Top },
            right: { anchor: "__container__", align: HorizontalAlign.End },
          })
          .padding({ top: 12, right: 12 })
        }
        .flexBasis(42)
        .height(42)
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
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)
      .visibility(this.hideDivider)

      if (typeof this.contentBuilder === 'function') {
        Column() {
          this.contentBuilder()
        }
        .flexGrow(1)
      }

      if (typeof this.footerBuilder === 'function') {
        this.footerBuilder()
      }
    }
    .height(this.dialogHeight)
    .margin(16)
    .borderRadius(8)
    .backgroundColor(Color.White)
  }
}