import _ from '@wolfx/lodash'
import { AppIcon, CustomModalDialog, IconConstants } from '@xy/basic'

@Component
export struct PhoneCompareModal {
  @Link @Watch("visibleChange") visible: boolean
  @Link accounts: Record<string, Record<string, Record<string, string>[]>>
  @State title: string = '手机号绑定提示'
  @State old_accounts: string = '-'
  @State new_accounts: string = '-'
  onSubmit: () => void = () => {
  }

  visibleChange() {
    this.old_accounts = _.map(this.accounts.old.xyAccounts, (item) => {
      return item.loginName
    }).join(" ")
    this.new_accounts = _.map(this.accounts.new.xyAccounts, (item) => {
      return item.loginName
    }).join(" ")
  }

  @Builder
  BuildModalContent() {
    Column() {
      Row() {
        Column() {
          AppIcon({
            iconCode: IconConstants.RIGHT_GOING,
            iconColor: '#FF931E',
            iconSize: 16,
            iconMargin: { top: 10 }
          })
          Column() {
          }
          .margin({ top: 10 })
          .width(1)
          .borderColor('#FF931E')
          .borderWidth({ left: 1 })
          .borderStyle(BorderStyle.Dashed)
          .layoutWeight(1)
        }
        .width(36)

        Column() {
          Text('绑定前')
            .fontColor('#FF931E')
            .fontSize(20)
            .lineHeight(32)
          Text(`手机号：${this.accounts.old.mobile || '-'}`)
            .lineHeight(32)
            .fontColor('#999999')
          Text(`微信：${_.find(this.accounts.old.thirdPartyLogins, { type: 'wechat' })?.nickname || '-'}`)
            .lineHeight(32)
            .fontColor('#999999')
          Text(`QQ：${_.find(this.accounts.old.thirdPartyLogins, { type: 'qq' })?.nickname || '-'}`)
            .lineHeight(32)
            .fontColor('#999999')
          Text(`账号：${this.old_accounts}`)
            .lineHeight(32)
            .fontColor('#999999')
        }
        .alignItems(HorizontalAlign.Start)
      }
      .margin({ left: 16, right: 16, top: 16 })
      .height(160)
      .alignItems(VerticalAlign.Top)

      Row() {
        Column() {
          AppIcon({
            iconCode: IconConstants.AGREE,
            iconColor: '#FF931E',
            iconSize: 16,
            iconMargin: { top: 10 }
          })
        }
        .width(36)

        Column() {
          Text('绑定后')
            .fontColor('#FF931E')
            .fontSize(20)
            .lineHeight(32)
          Text(`手机号：${this.accounts.new.mobile || '-'}`)
            .lineHeight(32)
          Text(`微信：${_.find(this.accounts.new.thirdPartyLogins, { type: 'wechat' })?.nickname || '-'}`)
            .lineHeight(32)
          Text(`QQ：${_.find(this.accounts.new.thirdPartyLogins, { type: 'qq' })?.nickname || '-'}`)
            .lineHeight(32)
          Text(`账号：${this.old_accounts + ' ' + this.new_accounts}`)
            .lineHeight(32)
        }
        .alignItems(HorizontalAlign.Start)
      }
      .margin({ left: 16, right: 16, bottom: 16 })
      .height(160)
      .alignItems(VerticalAlign.Top)
    }
    .alignItems(HorizontalAlign.Start)

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
        .onClick(() => {
          this.onSubmit()
        })
    }
    .width('100%')
  }

  build() {
    CustomModalDialog({
      visible: $visible,
      title: this.title,
      contentBuilder: () => this.BuildModalContent(),
      footerBuilder: () => this.BuildModalFooter(),
    })
  }
}