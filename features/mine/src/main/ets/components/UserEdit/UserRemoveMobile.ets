import {
  CustomAlertDialog,
  CustomField,
  CustomNavTitle,
  IconConstants,
  UserInfoModel,
  AlertDialogParam,
  checkPassWord
} from "@xy/basic"
import { display } from "@kit.ArkUI"

@Component
struct UserRemoveMobile {
  @StorageLink('UserInfo') userInfo: UserInfoModel = new UserInfoModel()
  @State screenWidth: number = 0
  @State mobile: string = this.userInfo.mobile
  @State password: string = ''

  aboutToAppear(): void {
    this.screenWidth = px2vp(display.getDefaultDisplaySync().width)
  }

  handleSubmit() {
    if (!checkPassWord(this.password)) {
      return;
    }

    new CustomAlertDialog({
      title: '注意',
      message: '移除后，已绑定账号将不再支持手机密码登录',
      onClickBtn: () => {
        console.log('')
      },
      onCloseBtn: () => {
        console.log('')
      },
    } as AlertDialogParam)
  }

  build() {
    NavDestination() {
      Column() {
        Column() {
          CustomField({
            value: this.mobile,
            iconCode: IconConstants.PHONE,
            disabled: true
          })
          CustomField({
            value: this.password,
            iconCode: IconConstants.LOCK,
            placeholder: `请输入账号密码`,
            inputType: InputType.Password
          })

          Column() {
            Text('注意：移除后，已绑定账号将不再支持手机密码登录')
              .margin({ top: 12, bottom: 12 })
              .fontColor('#FF4040')
              .fontSize(12)
            Button('确定', { type: ButtonType.Normal })
              .width('100%')
              .borderRadius(4)
              .backgroundColor('#40A9FF')
              .onClick(() => this.handleSubmit())
          }
          .width('100%')
        }
        .height(260)
        .margin({
          left: 12, right: 12
        })
        .justifyContent(FlexAlign.SpaceEvenly)
      }
      .width(this.screenWidth - 24)
      .margin({ left: 12, right: 12 })
      .backgroundColor(Color.White)
      .borderRadius(4)
    }
    .title(CustomNavTitle('移除手机'))
    .backgroundColor("#f1f1f1")
  }
}

@Builder
export function UserRemoveMobileBuilder() {
  UserRemoveMobile()
}