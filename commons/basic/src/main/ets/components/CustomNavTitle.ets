import { display } from "@kit.ArkUI"

@Component
struct NavTitle {
  /**
   * 展示文字
   */
  @Prop text: string = ''
  /**
   * 操作的builder
   */
  @BuilderParam rightBuilder?: CustomBuilder
  @State private screenWidth: number = 0

  aboutToAppear(): void {
    this.screenWidth = px2vp(display.getDefaultDisplaySync().width)
  }

  build() {
    Row() {
      Row() {
        Text(this.text)
          .fontSize(16)
          .fontColor('#404040')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .ellipsisMode(EllipsisMode.END)
      }
      .width(this.screenWidth - 112)
      .height(56)
      .justifyContent(FlexAlign.Center)

      if (typeof this.rightBuilder === 'function') {
        this.rightBuilder()
      }
    }
  }
}

@Builder
export function CustomNavTitle(text: string, rightBuilder?: CustomBuilder) {
  NavTitle({ text, rightBuilder })
}