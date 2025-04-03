import _ from "@wolfx/lodash";
import {
  Api_Context,
  CustomField,
  CustomNavTitle,
  CustomToast,
  IconConstants,
  passwordRules,
  PreferenceStorage,
  SystemApi,
  xyApiPut
} from "@xy/basic"
import { RSA_OAEP_ENCRYPT } from "./RSA_OAEP";

@Component
struct UserDocumentChangePassword {
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @StorageLink('PreferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage()
  @State password0: string = ''
  @State password1: string = ''
  @State password2: string = ''

  passwordRules(password: string, placeholder: string): boolean | undefined {
    if (!_.trim(password)) {
      CustomToast.toast_info(`${placeholder}不能为空`);
      return;
    }
    return passwordRules(password);
  };

  async handleSubmit() {
    if (!this.passwordRules(this.password0, '旧密码')) {
      return
    }

    if (!this.passwordRules(this.password1, '新密码')) {
      return
    }

    if (!this.passwordRules(this.password2, '新密码')) {
      return
    }

    if (this.password0 === this.password1) {
      CustomToast.toast_fail('提供的新、旧密码重复')
    }

    const encrypt_old_node_key = RSA_OAEP_ENCRYPT(this.password0)
    const encrypt_new_node_key = RSA_OAEP_ENCRYPT(this.password1)

    const response = await xyApiPut(
      this.Api_Context.getApiPrefix('baseApi_inner') + SystemApi.updateDocumentKey,
      {
        'old_node_key': encrypt_old_node_key,
        'new_node_key': encrypt_new_node_key,
      },
    )
    if (response.success) {
      CustomToast.toast_info('修改阅读密码成功')
      this.preferenceStorage.node_key = (response.data as Record<string, string>).node_key
      this.pageInfos.pop()
    }
  }

  build() {
    NavDestination() {
      Column() {
        CustomField({
          value: $password0,
          iconCode: IconConstants.LOCK,
          placeholder: '请输入旧密码',
          inputType: InputType.Password,
        })
        CustomField({
          value: $password1,
          iconCode: IconConstants.LOCK,
          placeholder: '请输入新密码',
          inputType: InputType.Password,
        })
        CustomField({
          value: $password2,
          iconCode: IconConstants.LOCK,
          placeholder: '请再次输入新密码',
          inputType: InputType.Password,
        })
        Button('确定', { type: ButtonType.Normal })
          .width('100%')
          .margin({ top: 20 })
          .borderRadius(4)
          .backgroundColor('#40A9FF')
          .onClick(() => this.handleSubmit())
      }
      .height(300)
      .margin({
        left: 12, right: 12
      })
      .justifyContent(FlexAlign.SpaceEvenly)
    }
    .title(CustomNavTitle('修改阅读密码'))
    .backgroundColor("#f1f1f1")
  }
}

@Builder
export function UserDocumentChangePasswordBuilder() {
  UserDocumentChangePassword()
}