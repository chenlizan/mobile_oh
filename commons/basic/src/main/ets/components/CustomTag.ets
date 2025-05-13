@Component
export struct CustomTag {
  /**
   * 展示文字
   */
  @Prop text: string = ''
  /**
   * 文字颜色
   */
  @Prop fontColor: ResourceColor = '#a8a8a8'
  /**
   * 文字大小
   */
  @Prop fontSize: number | string | Resource = 12
  /**
   * 背景色
   */
  tagBackgroundColor: ResourceColor = ''
  /**
   * 边框颜色
   */
  @Prop tagBorderColor: ResourceColor | EdgeColors | LocalizedEdgeColors = "#ebebeb"
  /**
   * 外边距
   */
  @Prop tagMargin: Margin | Length | LocalizedMargin = ''
  /**
   * 点击按钮
   */
  onClickBtn: (event: ClickEvent) => void = () => {
  }

  build() {
    Text(this.text)
      .margin(this.tagMargin)
      .padding({
        left: 8,
        right: 8,
        top: 4,
        bottom: 4
      })
      .backgroundColor(this.tagBackgroundColor)
      .borderWidth(1)
      .borderColor(this.tagBorderColor)
      .fontColor(this.fontColor)
      .fontSize(this.fontSize)
      .onClick(this.onClickBtn)
  }
}