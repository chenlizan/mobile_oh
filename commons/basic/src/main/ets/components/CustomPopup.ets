
@Component
export struct CustomPopup {
  /**
   * 内容 builder
   */
  @BuilderParam contentBuilder?: CustomBuilder
  /**
   * 显示文字
   */
  @Prop text: string = ''
  /**
   * tips 文字
   */
  @Prop tips: string = ''
  /**
   * tips 文字颜色
   */
  @Prop tipsColor: ResourceColor = Color.White;
  /**
   * 背景颜色
   */
  @Prop bgColor: ResourceColor = Color.White;
  /**
   * 气泡的背景色
   */
  @Prop popupColor: ResourceColor = Color.Black;
  /**
   * 气泡的方向
   */
  @Prop placement: Placement = Placement.Bottom;

  @State showPopup: boolean = false;

  build() {
    Button(this.text) {
      if (typeof this.contentBuilder === 'function') {
        this.contentBuilder()
      }
    }
    .backgroundColor(this.bgColor)
    .onClick(() => {
      this.showPopup = !this.showPopup;
    })
    .bindPopup(this.showPopup, {
      message: this.tips,
      popupColor: this.popupColor,
      messageOptions: {
        textColor: this.tipsColor
      },
      placement: this.placement,
      backgroundBlurStyle: BlurStyle.NONE
    })
  }
}