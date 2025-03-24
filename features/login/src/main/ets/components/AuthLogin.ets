import { deviceInfo } from "@kit.BasicServicesKit";
import { TextModifier } from "@kit.ArkUI";
import { identifier } from "@kit.AdsKit";
import {
  Api_Context,
  CCApi,
  ccApiPost,
  checkPassWord,
  checkUserName,
  CustomField,
  CustomToast,
  encryptDes,
  IconConstants,
  ObjectOption,
  ObjectUtil,
  PreferenceStorage,
  RouterConstants
} from "@xy/basic"
import { LoginType } from "./LoginPage";
import { LoginRemindModal } from "./LoginRemindModal";


@Component
export struct AuthLogin {
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack();
  @StorageLink('PreferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage();
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @State school: string | undefined = this.preferenceStorage?.school?.name
  @State school_id: string | undefined = this.preferenceStorage?.school?.id
  @State remindDialogVisible: boolean = false
  @State username: string = ''
  @State password: string = ''
  @State login_info: ObjectUtil<never> = new ObjectUtil({})

  async handleLogin() {
    if (!checkUserName(this.username)) {
      return;
    }
    if (!checkPassWord(this.password)) {
      return;
    }

    CustomToast.toast_loading('登录中...')

    const response = await ccApiPost(this.Api_Context.getApiPrefix('ccApi') + CCApi.unifiedCheckInfraLogin,
      {
        'loginType': LoginType.Id_Auth,
        'weekNoLoginStatus': true,
        'schoolId': this.school_id,
        'password': encryptDes(this.password, this.preferenceStorage?.des_encrypt_key?.[2] ?? ''),
        'loginName': encryptDes(this.username, this.preferenceStorage?.des_encrypt_key?.[3] ?? ''),
      },
      {
        'mobile-device-id': await identifier.getOAID(),
        'mobile-brand': deviceInfo.brand,
        'mobile-model': deviceInfo.productModel,
      })
    if (response.code === 200) {
      CustomToast.hide()
      this.login_info = new ObjectUtil(response.result as ObjectOption<never>)
      this.login_info.setValue('access_token', this.login_info.getValue('token'))
      this.login_info.setValue('refresh_token', this.login_info.getValue('refreshToken'))

      if (!this.login_info.getValue('access_token')) {
        this.login_info.setValue('needActive', this.login_info.getValue('isUnSafePassword'))

        if (!this.login_info.getValue('phoneStatus') ||
        this.login_info.getValue('isUnSafePassword') ||
        this.login_info.getValue('passwordExpiredStatus')) {
          this.remindDialogVisible = true
        }
        return
      } else {
        this.savaLoginInfo()
      }
    }
  }

  savaLoginInfo() {
    this.preferenceStorage.access_token = this.login_info.getValue('access_token')
    this.preferenceStorage.refresh_token = this.login_info.getValue('refresh_token')
    this.preferenceStorage.refresh_token_state = '0'
    this.pageInfos.pop(RouterConstants.IDENTITY_PAGE_URL)
  }

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
          .onClick(() => this.handleLogin())
      }
      .height(240)
      .margin({
        top: 50, left: 24, right: 24
      })
      .justifyContent(FlexAlign.SpaceBetween)

      LoginRemindModal({
        login_info: $login_info,
        visible: $remindDialogVisible,
        onActive: () => {
          this.remindDialogVisible = false
          this.pageInfos.pushPath({
            name: 'accountActivation',
            param: JSON.stringify({ infraAccessToken: this.login_info.getValue('infraAccessToken') })
          })
        },
        onLogin: () => {
          this.savaLoginInfo()
        },
        onDeal: () => {
          //去处理
        }
      })
    }
    .title('统一身份认证', {
      mainTitleModifier: new TextModifier().fontColor('#404040').fontSize(16).fontWeight(FontWeight.Normal)
    })
  }
}

@Builder
export function AuthLoginBuilder() {
  AuthLogin()
}