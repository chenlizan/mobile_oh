
@Component
export struct CustomPopup {
  /**
   * 内容 builder
   */
  @BuilderParam contentBuilder?: CustomBuilder
  /**
   * 展示文字
   */
  @Prop text: string = ''
  /**
   * 文字颜色
   */
  @Prop textColor: ResourceColor = Color.White;
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
    Button() {
      if (typeof this.contentBuilder === 'function') {
        this.contentBuilder()
      }
    }
    .backgroundColor(this.bgColor)
    .onClick(() => {
      this.showPopup = !this.showPopup;
    })
    .bindPopup(this.showPopup, {
      message: this.text,
      popupColor: this.popupColor,
      messageOptions: {
        textColor: this.textColor
      },
      placement: this.placement,
      backgroundBlurStyle: BlurStyle.NONE
    })
  }
}