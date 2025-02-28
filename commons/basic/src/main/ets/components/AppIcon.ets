@Component
export struct AppIcon {
  /**
   * 图标编码
   */
  @Prop iconCode: string = '';
  /**
   * 外边距
   */
  @Prop itemMargin: Margin | Length | LocalizedMargin = ''
  /**
   * 图标大小
   */
  @Prop iconSize: number = 12
  /**
   * 图标颜色
   */
  @Prop iconColor: string = 'rgba(0, 0, 0, 0.45)';
  /**
   * 点击按钮
   */
  onClickBtn: (event: ClickEvent) => void = () => {
  }

  build() {
    Text(this.iconCode)
      .fontFamily('IconFont')
      .fontSize(this.iconSize)
      .fontColor(this.iconColor)
      .margin(this.itemMargin)
      .onClick(this.onClickBtn)
  }
}