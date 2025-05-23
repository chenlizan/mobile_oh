import { IconConstants } from "../constants/IconConstants"
import { AppIcon } from "./AppIcon"

@Component
export struct CustomList {
  /**
   * 内容区域的builder
   */
  @BuilderParam defaultBuilder?: CustomBuilder
  @Prop listPadding: Padding | Length | LocalizedPadding

  build() {
    Column() {
      if (typeof this.defaultBuilder === 'function') {
        this.defaultBuilder()
      }
    }
    .padding(this.listPadding)

  }
}

@Component
export struct CustomListItem {
  /**
   * 展示文字
   */
  @Prop text: string = ''
  /**
   * 背景色
   */
  @Prop itemBackgroundColor: ResourceColor = Color.White
  /**
   * 外边距
   */
  @Prop itemMargin: Margin | Length | LocalizedMargin = ''
  /**
   * 内边距
   */
  @Prop itemPadding: Padding | Length | LocalizedPadding = '16'
  /**
   * 边框圆角
   */
  @Prop itemRadius: Length | BorderRadiuses | LocalizedBorderRadiuses = ''
  /**
   * 边框样式
   */
  @Prop itemBorder: BorderOptions = { width: { top: 1 } }
  /**
   * 文字颜色
   */
  @Prop fontColor: ResourceColor
  /**
   * 文字大小
   */
  @Prop fontSize: number | string | Resource = 16
  /**
   * 文字粗细
   */
  @Prop fontWeight: FontWeight = FontWeight.Normal
  /**
   *
   */
  @Prop required: boolean = false
  /**
   * 图标的builder
   */
  @BuilderParam iconBuilder?: CustomBuilder
  /**
   * 操作的builder
   */
  @BuilderParam operateBuilder?: CustomBuilder
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
        if (this.required) {
          Text('*')
            .fontColor(Color.Red)
            .fontSize(this.fontSize)
            .fontWeight(this.fontWeight)
        }
        Text(this.text)
          .fontColor(this.fontColor)
          .fontSize(this.fontSize)
          .fontWeight(this.fontWeight)
      }
      .alignItems(VerticalAlign.Center)

      if (typeof this.operateBuilder === 'function') {
        this.operateBuilder()
      } else {
        AppIcon({ iconCode: IconConstants.RIGHT })
      }
    }
    .width('100%')
    .padding(this.itemPadding)
    .margin(this.itemMargin)
    .backgroundColor(this.itemBackgroundColor)
    .border(this.itemBorder)
    .borderRadius(this.itemRadius)
    .borderColor({ top: '#d9d9d9d9' })
    .justifyContent(FlexAlign.SpaceBetween)
    .onClick(this.onClickBtn)
  }
}
