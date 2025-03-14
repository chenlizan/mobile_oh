import {
  Api_Context,
  CCApi,
  ccApiGet,
  CustomField,
  IconConstants,
  verifyNameIsMobile,
  checkPhone,
  checkCode,
  checkPassWordSame,
  verifyPassWord,
  encryptDes,
  PreferenceStorage,
  ccApiPost,
  PARAMS
} from "@xy/basic"
import { promptAction } from "@kit.ArkUI"
import _ from "@wolfx/lodash";
import { PhoneCheckModal } from "./PhoneCheckModal";

@Component
export struct ResetPassword {
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack();
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @StorageLink('PreferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage();
  @State checkDialogVisible: boolean = false
  @State phone: string = ''
  @State code: string = ''
  @State disabledCode: boolean = true
  @State password1: string = ''
  @State password2: string = ''
  @State time: number = 60
  @State accounts: Array<PARAMS> = []
  private interval: number = 0

  async getMobileValidCode() {
    const response = await ccApiGet(this.Api_Context.getApiPrefix('ccApi') + CCApi.infraSendMobileCode,
      { 'phone': this.phone, },
    )
    if (response.code === 200) {
      promptAction.showToast({ alignment: Alignment.Center, message: `获取手机验证码成功` });
    } else {
      promptAction.showToast({ alignment: Alignment.Center, message: response.msg });
    }
  }

  async queryUserInfoUnionAccountsByPhone(phone: string | undefined) {
    const response = await ccApiGet(
      this.Api_Context.getApiPrefix('ccApi') + CCApi.queryUserInfoUnionAccountsByPhone,
      { 'phone': phone },
    )
    if (response.code === 200) {
      return response?.result ?? [];
    } else {
      return [];
    }
  }

  handleCode() {
    this.disabledCode = false
    this.getMobileValidCode()
    this.interval = setInterval(() => {
      if (this.time === 0) {
        clearInterval(this.interval);
        this.time = 60
      } else {
        this.time -= 1
      }
    }, 1000);
  }

  async handleSubmit() {
    if (!checkPhone(this.phone)) {
      return;
    }

    if (!verifyNameIsMobile(this.phone)) {
      promptAction.showToast({ alignment: Alignment.Center, message: `该手机号无效，请核查` });
      return;
    }

    if (!checkCode(this.code)) {
      return;
    }

    if (!checkPassWordSame(this.password1, this.password2)) {
      return;
    }

    if (!verifyPassWord(this.password1) || !verifyPassWord(this.password2)) {
      return;
    }

    const response = await this.queryUserInfoUnionAccountsByPhone(encryptDes(this.phone,
      this.preferenceStorage?.des_encrypt_key?.[0] ?? ''))

    if (!_.isEmpty(response) && _.size(response) === 1) {
      this.accounts = response as PARAMS[]
      this.checkDialogVisible = true
    } else {
      this.handleUpdate(
        encryptDes(this.phone, this.preferenceStorage?.des_encrypt_key?.[0] ?? ''),
        encryptDes(this.password1, this.preferenceStorage?.des_encrypt_key?.[2] ?? ''),
        this.code)
    }
  }

  async handleUpdate(phone: string | undefined, password: string | undefined, code: string) {
    const response = await ccApiPost(this.Api_Context.getApiPrefix('ccApi') + CCApi.updatePasswordByCode,
      { 'phone': phone, 'password': password, 'code': code }
    )
    if (response.code === 200) {
      promptAction.showToast({ alignment: Alignment.Center, message: `密码修改成功` });
      this.pageInfos.pop()
    } else {
      promptAction.showToast({ alignment: Alignment.Center, message: response.msg });
    }
  }

  build() {
    NavDestination() {
      Column() {
        Row() {
          Text('重置密码')
            .fontColor('#333333')
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)

        CustomField({
          value: $phone,
          iconCode: IconConstants.PHONE,
          placeholder: '请输入手机号',
        })

        Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
          CustomField({
            value: $code,
            iconCode: IconConstants.SAFETY,
            placeholder: '请输入验证码',
            disabled: this.disabledCode
          })
          Button(this.time === 60 ? '获取验证码' : `${this.time}s`,
            { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.NORMAL })
            .margin({ left: 8 })
            .width(this.time === 60 ? 170 : 80)
            .backgroundColor(Color.White)
            .borderWidth(1)
            .borderColor(verifyNameIsMobile(this.phone) ? '#40A9FF' : '#999999')
            .borderRadius(4)
            .fontColor(verifyNameIsMobile(this.phone) ? '#40A9FF' : '#999999')
            .fontSize(14)
            .enabled(verifyNameIsMobile(this.phone))
            .onClick(() => this.handleCode())
        }

        CustomField({
          value: $password1,
          iconCode: IconConstants.LOCK,
          placeholder: '请输入新密码',
          inputType: InputType.Password
        })
        CustomField({
          value: $password2,
          iconCode: IconConstants.LOCK,
          placeholder: '请再次输入密码',
          inputType: InputType.Password
        })

        Text('注意：找回密码必须通过手机找回。若未绑定手机号，需联系运维人员重置密码')
          .padding(10)
          .backgroundColor('#fef6e6')
          .fontColor('#fbad13')
          .fontSize(13)

        Button('确定', { type: ButtonType.Normal })
          .width('100%')
          .borderRadius(4)
          .backgroundColor('#40A9FF')
          .onClick(() => this.handleSubmit())
      }
      .height(480)
      .margin({
        left: 24, right: 24
      })
      .justifyContent(FlexAlign.SpaceBetween)

      PhoneCheckModal({
        accounts: $accounts,
        visible: $checkDialogVisible,
        onSubmit: () => {
          this.handleUpdate(
            encryptDes(this.phone, this.preferenceStorage?.des_encrypt_key?.[0] ?? ''),
            encryptDes(this.password1, this.preferenceStorage?.des_encrypt_key?.[2] ?? ''),
            this.code)
        }
      })
    }
  }
}

@Builder
export function ResetPasswordBuilder() {
  ResetPassword()
}