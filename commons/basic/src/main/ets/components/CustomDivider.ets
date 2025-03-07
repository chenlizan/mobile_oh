@Component
export struct CustomDivider {
  /**
   * 展示文字
   */
  @Prop text: string = '';

  build() {
    Row() {
      Row() {
      }
      .height(1)
      .borderWidth({ top: 1 })
      .layoutWeight(1)
      .borderColor('#33999999')

      Text(this.text)
        .margin(10)
        .fontSize(13)
        .fontColor('#999999')

      Row() {
      }
      .height(1)
      .borderWidth({ top: 1 })
      .layoutWeight(1)
      .borderColor('#33999999')
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }
}