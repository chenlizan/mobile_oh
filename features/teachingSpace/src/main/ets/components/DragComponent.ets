@Component
export struct DragComponent {
  @Prop src: PixelMap | ResourceStr | DrawableDescriptor
  @Prop imgOffSetX: number = 0
  @Prop imgOffSetY: number = 0
  private preOffsetX: number = 0
  private preOffsetY: number = 0
  onClickBtn: () => void = () => {
  }

  build() {
    Image(this.src)
      .width(40)
      .height(40)
      .borderRadius(20)
      .shadow(ShadowStyle.OUTER_DEFAULT_SM)
      .position({ x: this.imgOffSetX, y: this.imgOffSetY })
      .gesture(
        PanGesture()
          .onActionStart(() => {
            this.preOffsetX = this.imgOffSetX;
            this.preOffsetY = this.imgOffSetY;
          })
          .onActionUpdate((event?: GestureEvent) => {
            if (event) {
              this.imgOffSetX = this.preOffsetX + event.offsetX;
              this.imgOffSetY = this.preOffsetY + event.offsetY;
            }
          }))
      .onClick(() => this.onClickBtn())
  }
}