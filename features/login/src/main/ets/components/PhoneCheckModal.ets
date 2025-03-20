import { CustomModalDialog } from "@xy/basic";

@Component
export struct PhoneCheckModal {
  @Link visible: boolean
  @Link accounts: Record<string, string>[]
  @State title: string = '重置密码提示'
  onSubmit: () => void = () => {
  }

  @Builder
  BuildModalContent(accounts: Record<string, string>[]) {
    Column() {
      Text('注意：修改后，以下账号均需使用新密码登录')
        .padding(10)
        .backgroundColor('#fef6e6')
        .fontColor('#fbad13')
        .fontSize(13)

      List() {
        ForEach(accounts, (item: Record<string, string>) => {
          ListItem() {
            Row() {
              Image(item.schoolIcon)
                .width(48)
                .height(48)
                .margin({ left: 12, right: 12 })
              Column() {
                Text(item.schoolName)
                Text(item.loginName)
                  .margin({ top: 8 })
              }
            }
            .width('100%')
            .margin({ left: 8, bottom: 4 })
            .alignItems(VerticalAlign.Center)
          }
        })
      }
      .width('100%')
      .padding(16)
    }
  }

  @Builder
  BuildModalFooter() {
    Flex({ direction: FlexDirection.Row }) {
      Button('取消', { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.NORMAL })
        .margin({ left: 8, right: 8 })
        .backgroundColor('#f5f5f5')
        .border({ width: 1, color: '#999999' })
        .borderRadius(4)
        .fontColor('#999999')
        .flexGrow(1)
        .onClick(() => {
          this.visible = false
        })

      Button('确定', { type: ButtonType.Normal })
        .margin({ left: 8, right: 8 })
        .borderRadius(4)
        .flexGrow(1)
        .onClick(() => {
          this.onSubmit()
        })
    }
    .margin({ top: 8, bottom: 8 })
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