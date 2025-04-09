import { display } from "@kit.ArkUI"
import { emitter } from "@kit.BasicServicesKit";
import _ from "@wolfx/lodash";
import { PhoneCheckModal } from "./PhoneCheckModal";
import {
  Api_Context,
  CCApi,
  ccApiGet,
  ccApiPost,
  checkPassWord,
  checkPassWordSame,
  CustomField,
  CustomNavTitle,
  CustomToast,
  encryptDes,
  IconConstants,
  PARAMS,
  PreferenceStorage,
  verifyPassWord
} from "@xy/basic"

@Component
struct UserPassword {
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @StorageLink('PreferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage()
  @State accounts: Array<PARAMS> = []
  @State checkDialogVisible: boolean = false
  @State password0: string = ''
  @State password1: string = ''
  @State password2: string = ''
  @State screenWidth: number = 0
  @State platform: string = ''

  aboutToAppear(): void {
    this.screenWidth = px2vp(display.getDefaultDisplaySync().width)
    this.getPlatformConfigBySchoolCertify()
  }

  async getPlatformConfigBySchoolCertify() {
    const schoolCertify = this.preferenceStorage.school?.code
    const response = await ccApiGet(this.Api_Context.getApiPrefix('ccApi') + CCApi.gainSchoolId, {
      'schoolCertify': schoolCertify,
    })
    if (response.code === 200) {
      const school = _.find(response.result as Record<string, string>[], { schoolCertify })
      if (school) {
        this.platform = (school as Record<string, string>)?.projectTitle ?? ''
      }
    }
  }

  async queryUserInfoUnionAccounts() {
    const response = await ccApiPost(this.Api_Context.getApiPrefix('ccApi') + CCApi.queryUserInfoUnionAccounts)
    if (response.code === 200) {
      return response?.result ?? [];
    } else {
      return [];
    }
  }

  async handleUpdate(phone0: string, phone1: string,) {
    const response = await ccApiPost(this.Api_Context.getApiPrefix('ccApi') + CCApi.changePassword,
      {
        'old_password': encryptDes(phone0, this.preferenceStorage?.des_encrypt_key?.[2] ?? ''),
        'new_password': encryptDes(phone1, this.preferenceStorage?.des_encrypt_key?.[2] ?? '')
      }
    )
    if (response.code === 200) {
      CustomToast.toast_success(`密码修改成功，请使用新密码重新登入`)
      emitter.emit('loginOut')
    } else {
      if (response.code === 10001) {
        CustomToast.toast_fail('密码错误');
      }
    }
  }

  async handleSubmit() {
    if (!checkPassWord(this.password0, '旧密码')) {
      return
    }

    if (!checkPassWordSame(this.password1, this.password2, '新密码')) {
      return
    }

    if (!verifyPassWord(this.password1) || !verifyPassWord(this.password2)) {
      return
    }

    this.accounts = await this.queryUserInfoUnionAccounts() as PARAMS[]
    if (!_.isEmpty(this.accounts) && _.isArray(this.accounts) && this.accounts.length > 1) {
      this.checkDialogVisible = true
    } else {
      this.handleUpdate(this.password0, this.password1)
    }
  }

  @Builder
  BuildNavRightBtn() {
    Button('找回密码', { buttonStyle: ButtonStyleMode.TEXTUAL })
      .margin({ left: -36 })
      .fontColor('#FCBB34')
      .onClick(() => this.pageInfos.pushPath({ name: 'resetPassword' }))
  }

  build() {
    NavDestination() {
      Column() {
        Column() {
          CustomField({
            value: $password0,
            iconCode: IconConstants.LOCK,
            placeholder: `请输入${this.platform}旧密码`,
            inputType: InputType.Password
          })
          CustomField({
            value: $password1,
            iconCode: IconConstants.LOCK,
            placeholder: `请输入${this.platform}新密码`,
            inputType: InputType.Password
          })
          CustomField({
            value: $password2,
            iconCode: IconConstants.LOCK,
            placeholder: `请再次输入${this.platform}新密码`,
            inputType: InputType.Password
          })

          Row() {
            Text('注意：修改后，已绑定账号需要使用新密码登录')
              .fontColor('#FF4040')
              .fontSize(12)
          }
          .width('100%')
          .height(40)
          .justifyContent(FlexAlign.End)
          .alignItems(VerticalAlign.Bottom)

          Button('确定', { type: ButtonType.Normal })
            .width('100%')
            .borderRadius(4)
            .backgroundColor('#40A9FF')
            .onClick(() => this.handleSubmit())
        }
        .height(320)
        .margin({
          left: 12, right: 12
        })
        .justifyContent(FlexAlign.SpaceEvenly)
      }
      .width(this.screenWidth - 24)
      .margin({ left: 12, right: 12 })
      .backgroundColor(Color.White)
      .borderRadius(4)

      PhoneCheckModal({
        accounts: $accounts,
        visible: $checkDialogVisible,
        onSubmit: () => {
          this.handleUpdate(this.password0, this.password1)
        }
      })
    }
    .title(CustomNavTitle('更新密码', () => this.BuildNavRightBtn()))
    .backgroundColor("#f1f1f1")
  }
}

@Builder
export function UserPasswordBuilder() {
  UserPassword()
}