import { CustomField, IconConstants, PreferenceStorage } from "@xy/basic"

@Component
export struct AuthLogin {
  @StorageLink('PreferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage();
  @State school: string | undefined = this.preferenceStorage?.school?.name
  @State username: string = ''
  @State password: string = ''

  build() {
    NavDestination() {
      Column() {
        CustomField({
          value: this.school,
          iconCode: IconConstants.HOME,
          disabled: true
        })
        CustomField({
          value: $username,
          iconCode: IconConstants.USER,
          placeholder: '请输入手机号/账号',
        })
        CustomField({
          value: $password,
          iconCode: IconConstants.LOCK,
          placeholder: '请输入密码',
          inputType: InputType.Password
        })

        Button('登录', { type: ButtonType.Normal })
          .width('100%')
          .borderRadius(4)
          .backgroundColor('#40A9FF')
        // .onClick(() => this.handleLogin())
      }
      .height(240)
      .margin({
        top: 50, left: 24, right: 24
      })
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .title('统一身份认证')
  }
}

@Builder
export function AuthLoginBuilder() {
  AuthLogin()
}