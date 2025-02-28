@Component
export struct CustomList {
  @BuilderParam defaultBuilder?: CustomBuilder;
  @Prop listWidth: string = '100%';

  build() {
    Column() {
      if (typeof this.defaultBuilder === 'function') {
        this.defaultBuilder()
      }
    }
    .width(this.listWidth)
  }
}

@Component
export struct CustomListItem {
  /**
   * 展示文字
   */
  @Prop text: string = '';
  /**
   * 外边距
   */
  @Prop itemMargin: Margin | Length | LocalizedMargin = ''
  /**
   * 边框圆角
   */
  @Prop itemRadius: Length | BorderRadiuses | LocalizedBorderRadiuses = ''
  /**
   * 边框样式
   */
  @Prop itemBorder: Length | EdgeWidths | LocalizedEdgeWidths = { top: '1vp' }
  /**
   * 文字行高
   */
  @Prop lineHeight: number | string | Resource = 30
  /**
   * 图标的builder
   */
  @BuilderParam iconBuilder?: CustomBuilder;
  /**
   * 操作的builder
   */
  @BuilderParam operateBuilder?: CustomBuilder;
  /**
   * 点击按钮
   */
  onClickBtn: (event: ClickEvent) => void = () => {
  }

  build() {
    Row() {
      Row() {
        if (typeof this.iconBuilder === 'function') {
          this.iconBuilder()
        }
        Text(this.text)
          .fontSize("16vp")
          .lineHeight(this.lineHeight)
          .fontWeight(500)
      }

      if (typeof this.operateBuilder === 'function') {
        this.operateBuilder()
      } else {
        BuildImageArrowRight()
      }
    }
    .width('100%')
    .padding('16')
    .margin(this.itemMargin)
    .backgroundColor(Color.White)
    .borderWidth(this.itemBorder)
    .borderRadius(this.itemRadius)
    .borderColor({ top: '#d9d9d9d9' })
    .justifyContent(FlexAlign.SpaceBetween)
    .onClick(this.onClickBtn)
  }
}

@Builder
export function BuildImageArrowRight() {
  Image($r('app.media.ic_public_arrow_right'))
    .width("12vp")
    .height("24vp")
    .fillColor("#999999")
}
