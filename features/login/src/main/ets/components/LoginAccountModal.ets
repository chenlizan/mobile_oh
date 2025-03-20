import { CustomModalDialog } from "@xy/basic";

interface Account extends Record<string, Record<string, string>> {
  id,
  loginName,
  status
}

@Component
export struct LoginAccountModal {
  @Link visible: boolean
  @Link accounts: Account[]
  @State selectItem: Account | null = null
  @State title: string = '选择账号登录'
  onSelect: (selectItem: Account | null) => void = () => {
  }

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

  @Builder
  BuildModalContent(accounts: Account[]) {
    Column() {
      List() {
        ForEach(accounts, (item: Account) => {
          ListItem() {
            Row() {
              Image(item?.school?.icon)
                .width(48)
                .height(48)
                .margin({ left: 12, right: 12 })
              Column() {
                Text(item?.school?.displayName)
                Text(item?.loginName)
                  .margin({ top: 8 })
              }
            }
            .width('100%')
            .margin({ left: 8, bottom: 4 })
            .alignItems(VerticalAlign.Center)
            .backgroundColor(this.handleBackgroundColor(item, this.selectItem?.id === item.id))
            .borderColor(this.handleBackgroundColor(item, this.selectItem?.id === item.id))
            .onClick(() => {
              this.handleSelect(item)
            })
          }
        })
      }
    }
  }

  @Builder
  BuildModalFooter() {
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

  build() {
    CustomModalDialog({
      dialogHeight: 360,
      visible: $visible,
      title: this.title,
      contentBuilder: () => this.BuildModalContent(this.accounts),
      footerBuilder: () => this.BuildModalFooter(),
    })
  }
}