import { CustomField, CustomModalDialog, IconConstants } from "@xy/basic"

@Component
export struct SetDocumentPasswordModal {
  @Link @Watch("visibleChange") visible: boolean
  @Link title: string
  @Link oper: string
  @State password: string = ''
  onSubmit: (password: string, oper: string) => void = () => {
  }

  visibleChange() {
    this.password = ''
  }

  @Builder
  BuildModalContent() {
    Row() {
      CustomField({
        value: $password,
        iconCode: IconConstants.LOCK,
        placeholder: '请输入阅读密码',
        inputType: InputType.Password,
      })
    }
    .padding({ left: 12, right: 12, top: 24 })
  }

  @Builder
  BuildModalFooter() {
    Row() {
      Button('取消', { type: ButtonType.Normal })
        .height(40)
        .fontColor('#999999')
        .backgroundColor(Color.White)
        .borderWidth({ top: 1 })
        .borderColor('#33999999')
        .borderRadius({
          topLeft: 0,
          topRight: 0,
          bottomLeft: 8,
          bottomRight: 0
        })
        .flexGrow(1)
        .onClick(() => this.visible = false)
      Button('确定', { type: ButtonType.Normal })
        .height(40)
        .backgroundColor('#40A9FF')
        .borderWidth({ top: 1 })
        .borderColor('#40A9FF')
        .borderRadius({
          topLeft: 0,
          topRight: 0,
          bottomLeft: 0,
          bottomRight: 8
        })
        .flexGrow(1)
        .onClick(() => this.onSubmit(this.password, this.oper))
    }
    .width('100%')
  }

  build() {
    CustomModalDialog({
      dialogHeight: 180,
      visible: $visible,
      title: $title,
      contentBuilder: () => this.BuildModalContent(),
      footerBuilder: () => this.BuildModalFooter(),
      hideCloseBtn: Visibility.Hidden,
      hideDivider: Visibility.Hidden
    })
  }
}