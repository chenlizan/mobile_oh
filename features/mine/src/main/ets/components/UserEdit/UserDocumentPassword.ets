import { display } from "@kit.ArkUI"
import _ from "@wolfx/lodash"
import { CryptoJS } from '@ohos/crypto-js'
import {
  Api_Context,
  CustomNavTitle,
  CustomToast,
  passwordRules,
  PreferenceStorage,
  SystemApi,
  UserInfoModel,
  xyApiPost,
  xyApiPut
} from "@xy/basic"
import { SetDocumentPasswordModal } from "./SetDocumentPasswordModal"
import { RSA_OAEP_ENCRYPT } from "./RSA_OAEP"

@Component
struct UserDocumentPassword {
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @StorageLink('PreferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage()
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @StorageLink('UserInfo') userInfo: UserInfoModel = new UserInfoModel()
  @State screenWidth: number = 0
  @State dialogVisible: boolean = false
  @State dialogTitle: string = ''
  @State dialogOper: string = 'set' || 'remove'

  aboutToAppear(): void {
    this.screenWidth = px2vp(display.getDefaultDisplaySync().width)
  }

  async handleSubmit(password: string, oper: string) {
    if (!_.trim(password)) {
      CustomToast.toast_info('阅读密码不能为空')
      return
    }

    if (!passwordRules(password)) {
      return
    }

    if (this.preferenceStorage.node_key && this.preferenceStorage.node_key !== CryptoJS.MD5(password).toString()) {
      CustomToast.toast_info('您输入的密码不对')
      return
    }

    const encrypt_node_key = RSA_OAEP_ENCRYPT(password)
    const url = oper === 'set' ? SystemApi.setDocumentKey : SystemApi.removeDocumentKey
    const response =
      await xyApiPut(this.Api_Context.getApiPrefix('baseApi_inner') + url,
        { 'node_key': encrypt_node_key })
    if (response.success) {
      CustomToast.toast_info(oper === 'set' ? '设置阅读密码成功' : '移除阅读密码成功')
      this.preferenceStorage.node_key = oper === 'set' ? (response.data as Record<string, string>).node_key : undefined
      this.dialogVisible = false
    }
  }

  async handleRestPassword() {
    if (!_.trim(this.userInfo.mobile)) {
      CustomToast.toast_info('未绑定手机号码，无法找回密码，请先绑定手机号码')
      return
    }

    const response = await xyApiPost(this.Api_Context.getApiPrefix("baseApi_inner") + SystemApi.resetDocumentKey,
      { 'mobile': this.userInfo.mobile })
    if (response.success) {
      CustomToast.toast_info('密码已发送至您的手机，请注意查收')
    } else {
      CustomToast.toast_fail('操作过于频繁：一个手机号一分钟内只能发送一条密码重置短信')
    }
  }

  @Builder
  BuildNavRightBtn() {
    if (this.preferenceStorage.node_key) {
      Button('移除密码', { buttonStyle: ButtonStyleMode.TEXTUAL })
        .margin({ left: -36 })
        .fontColor('#999999')
        .onClick(() => {
          this.dialogTitle = '移除密码'
          this.dialogOper = 'remove'
          this.dialogVisible = true
        })
    }
  }

  build() {
    NavDestination() {
      Column() {
        if (!this.preferenceStorage.node_key) {
          Button('设置密码', { type: ButtonType.Normal })
            .margin(32)
            .width(this.screenWidth - 64)
            .height(40)
            .backgroundColor('#40A9FF')
            .borderRadius(4)
            .onClick(() => {
              this.dialogTitle = '设置密码'
              this.dialogOper = 'set'
              this.dialogVisible = true
            })
        } else {
          Button('密码找回', { type: ButtonType.Normal })
            .margin({ left: 32, right: 32 })
            .width(this.screenWidth - 64)
            .height(40)
            .backgroundColor('#40A9FF')
            .borderRadius(4)
            .onClick(() => this.handleRestPassword())
          Button('修改密码', { type: ButtonType.Normal })
            .margin({ left: 32, right: 32, top: 32 })
            .width(this.screenWidth - 64)
            .height(40)
            .backgroundColor('#40A9FF')
            .borderRadius(4)
            .onClick(() => this.pageInfos.pushPath({ name: 'userDocumentChangePassword' }))
        }
      }
      .height('100%')
      .justifyContent(FlexAlign.Center)

      SetDocumentPasswordModal({
        title: $dialogTitle,
        visible: $dialogVisible,
        oper: $dialogOper,
        onSubmit: (p, o): Promise<void> => this.handleSubmit(p, o)
      })
    }
    .title(CustomNavTitle('阅读密码', () => this.BuildNavRightBtn()))
    .backgroundColor("#f1f1f1")
  }
}

@Builder
export function UserDocumentPasswordBuilder() {
  UserDocumentPassword()
}