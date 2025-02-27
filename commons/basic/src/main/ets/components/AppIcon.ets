@Component
export struct AppIcon {
  /**
   * 图标编码
   */
  @Prop icon: string = '';
  /**
   * 图标大小
   */
  @Prop iconSize: number = 12
  /**
   * 图标颜色
   */
  @Prop iconColor: string = 'rgba(0, 0, 0, 0.45)';

  build() {
    Text(this.icon)
      .fontFamily('IconFont')
      .fontSize(this.iconSize)
      .fontColor(this.iconColor)
  }
}