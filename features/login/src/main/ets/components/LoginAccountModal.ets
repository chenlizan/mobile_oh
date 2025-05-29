import { AppIcon, IconConstants } from "@xy/basic";

interface Account extends Record<string, Record<string, string>> {
  id,
  loginName,
  status
}

@Component
export struct LoginAccountModal {
  @Link @Watch("visibleChange") visible: boolean
  @Link accounts: Account[]
  onSelect: (selectItem: Account | null) => void = () => {
  }

  visibleChange() {
    if (this.visible) {
      this.dialogController?.open()
    } else {
      this.dialogController?.close()
    }
  }

  dialogController: CustomDialogController = new CustomDialogController({
    builder: CustomModalDialogView({
      accounts: this.accounts,
      onCloseBtn: () => {
        this.visible = false
      },
      onSelect: (item: Account | null) => {
        this.onSelect(item)
        this.visible = false
      }
    }),
    autoCancel: false,
    customStyle: true,
    isModal: true,
  })

  build() {
  }
}

@CustomDialog
struct CustomModalDialogView {
  @State selectItem: Account | null = null
  @State selectItemId: string = ''
  accounts: Account[] = []
  controller?: CustomDialogController
  onCloseBtn: () => void = () => {}
  onSelect: (item: Account | null) => void = () => {}

  handleSelect(item: Account) {
    this.selectItem = item
  }

  handleBackgroundColor(item: Account, isSelect: boolean) {
    const isEnabled = item.status === 'enabled' && !!item?.isInCurrentInstance;
    const itemBGColor = isEnabled
      ? isSelect
        ? '#FF931E'
        : '#FFFFFF'
      : '#F1F1F1';
    return itemBGColor
  }

  build() {
    Column() {
      RelativeContainer() {
        Row() {
          Text('选择账号登录')
            .fontWeight(FontWeight.Bold)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)

        Row() {
          AppIcon({
            iconCode: IconConstants.CLOSE,
            iconSize: 20,
            iconColor: '#999999',
            onClickBtn: this.onCloseBtn
          })
        }
        .alignRules({
          top: { anchor: "__container__", align: VerticalAlign.Top },
          right: { anchor: "__container__", align: HorizontalAlign.End },
        })
        .padding({ top: 12, right: 12 })
      }
      .flexBasis(42)
      .height(42)

      Row() {
        Row() {
        }
        .height(1)
        .borderWidth({ top: 1 })
        .layoutWeight(1)
        .borderColor('#33999999')
      }
      .width('100%')
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)

      Column() {
        List() {
          ForEach(this.accounts, (item: Account) => {
            ListItem() {
              Row() {
                Image(item?.school?.icon)
                  .width(48)
                  .height(48)
                  .margin({ right: 12 })
                  .borderRadius(24)
                Column() {
                  Text(item?.school?.displayName)
                  Text(item?.loginName)
                    .margin({ top: 8 })
                }
                .alignItems(HorizontalAlign.Start)
              }
              .width('100%')
              .padding(8)
              .alignItems(VerticalAlign.Center)
              .backgroundColor(this.handleBackgroundColor(item, this.selectItem?.id === item.id))
              .borderColor(this.handleBackgroundColor(item, this.selectItem?.id === item.id))
              .borderRadius(4)
              .onClick(() => {
                this.handleSelect(item)
              })
            }
          })
        }
        .padding(16)
      }
      .flexGrow(1)

      Column() {
        Button('确定', { type: ButtonType.Normal })
          .width('100%')
          .height(40)
          .borderRadius(4)
          .onClick(() => {
            this.onSelect(this.selectItem)
          })
      }
      .padding({ left: 16, right: 16, bottom: 16 })
    }
    .margin(16)
    .borderRadius(8)
    .backgroundColor(Color.White)
  }
}