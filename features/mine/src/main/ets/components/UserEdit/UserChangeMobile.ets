import { display } from "@kit.ArkUI"
import _ from "@wolfx/lodash"
import {
  Api_Context,
  CCApi,
  ccApiGet,
  ccApiPost,
  checkCode,
  checkPhone,
  CustomField,
  CustomNavTitle,
  CustomToast,
  encryptDes,
  IconConstants,
  PARAMS,
  PreferenceStorage,
  UserInfoModel,
  verifyNameIsMobile
} from "@xy/basic"
import { PhoneCompareModal } from "./PhoneCompareModal"

@Component
struct UserChangeMobile {
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @StorageLink('UserInfo') userInfo: UserInfoModel = new UserInfoModel()
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @StorageLink('PreferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage()
  @State mobile: string = this.userInfo.mobile
  @State accounts: Array<PARAMS> = []
  @State compareDialogVisible: boolean = false
  @State disabledCode: boolean = true
  @State canSubmit: boolean = false
  @State time: number = 60
  @State @Watch("inputChange") phone: string = ''
  @State @Watch("inputChange") password: string = ''
  @State @Watch("inputChange") code: string = ''
  @State screenWidth: number = 0
  private interval: number = 0

  aboutToAppear(): void {
    this.screenWidth = px2vp(display.getDefaultDisplaySync().width)
  }

  async getMobileValidCode() {
    const response = await ccApiGet(this.Api_Context.getApiPrefix('ccApi') + CCApi.infraSendMobileCode,
      { 'phone': this.phone, },
    )
    if (response.code === 200) {
      CustomToast.toast_success(`获取手机验证码成功`)
    } else {
      CustomToast.toast_fail(response.msg as string);
    }
  }

  async updateMobile(body: Record<string, string | undefined>) {
    const response = await ccApiPost(this.Api_Context.getApiPrefix('ccApi') + CCApi.infraChangeMobile, body)
    if (response.code === 200) {
      this.userInfo.mobile = this.phone
      CustomToast.toast_success('手机号绑定成功')
      this.pageInfos.popToName('userEdit')
    } else {
      CustomToast.toast_fail(response.msg || '')
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

    if (!checkCode(this.code)) {
      return;
    }

    const body: Record<string, string | undefined> = {
      'phone': encryptDes(this.phone, this.preferenceStorage?.des_encrypt_key?.[0] ?? ''),
      'password': encryptDes(this.password, this.preferenceStorage?.des_encrypt_key?.[2] ?? ''),
      'authorId': this.userInfo.id,
      'code': this.code
    }

    const response = await ccApiPost(this.Api_Context.getApiPrefix('ccApi') + CCApi.infraPreChangeMobile, body)
    if (response.code === 200) {
      const result = response.result
      if (!_.isEmpty(result) && (result as Record<string, boolean>).needMerge) {
        this.accounts = result as PARAMS[]
        this.compareDialogVisible = true
      } else {
        this.updateMobile(body)
      }
    }
  }

  handleOk() {
    const body: Record<string, string | undefined> = {
      'phone': encryptDes(this.phone, this.preferenceStorage?.des_encrypt_key?.[0] ?? ''),
      'password': encryptDes(this.password, this.preferenceStorage?.des_encrypt_key?.[2] ?? ''),
      'authorId': this.userInfo.id,
      'code': this.code
    }
    this.updateMobile(body)
  }

  inputChange() {
    this.canSubmit = !!_.trim(this.phone) && !!_.trim(this.password) && !!_.trim(this.code)
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
              disabled: this.disabledCode,
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

          Button('确定', { type: ButtonType.Normal })
            .width('100%')
            .fontColor(this.canSubmit ? Color.White : '#999999')
            .borderRadius(4)
            .borderWidth(1)
            .borderColor(this.canSubmit ? '#40A9FF' : '#999999')
            .backgroundColor(this.canSubmit ? '#40A9FF' : Color.White)
            .enabled(this.canSubmit)
            .onClick(() => this.handleSubmit())

        }
        .height(350)
        .margin({
          left: 12, right: 12
        })
        .justifyContent(FlexAlign.SpaceEvenly)
      }
      .width(this.screenWidth - 24)
      .margin({ left: 12, right: 12 })
      .backgroundColor(Color.White)
      .borderRadius(4)

      PhoneCompareModal({
        accounts: $accounts,
        visible: $compareDialogVisible,
        onSubmit: (): void => this.handleOk()
      })

    }
    .title(CustomNavTitle('更换手机号'))
    .backgroundColor("#f1f1f1")
  }
}

@Builder
export function UserChangeMobileBuilder() {
  UserChangeMobile()
}