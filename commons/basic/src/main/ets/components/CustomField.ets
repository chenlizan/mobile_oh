import { IconConstants } from "../constants/IconConstants"
import { AppIcon } from "./AppIcon"

@Component
export struct CustomField {
  /**
   * 图标
   */
  @Prop iconCode: IconConstants = ''
  /**
   * 输入框占位提示文字
   */
  @Prop placeholder: string = ''
  /**
   * 是否禁用
   */
  @Prop disabled: boolean = false
  /**
   * 输入框类型
   */
  @Prop inputType: InputType = InputType.Normal
  /**
   * 当前输入的值, 支持双向绑定
   */
  @Link value: string
  /**
   * value变化时触发
   */
  onChange: (value: string) => void = () => {}

  build() {
    Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center }) {
      AppIcon({
        iconCode: this.iconCode,
        iconColor: '#40A9FF',
        iconSize: 16,
        iconMargin: { left: 12, right: 0.5 },
      })
      TextInput({ text: $$this.value, placeholder: this.placeholder })
        .enabled(!this.disabled)
        .borderRadius(0)
        .backgroundColor(this.disabled ? '#00ffffff' : Color.White)
        .placeholderColor('#99999999')
        .fontColor('#999999')
        .type(this.inputType)
        .onChange((value: string) => {
          this.onChange(this.value)
        })
    }
    .backgroundColor(this.disabled ? '#4ddfe3ea' : Color.White)
    .borderColor('#dfe3ea')
    .borderRadius(4)
    .borderWidth(1)
  }
}