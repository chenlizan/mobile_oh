import _ from "@wolfx/lodash";
import { Api_Context, CCApi, ccApiPost, CustomNavTitle, CustomToast, UserInfoModel } from "@xy/basic"

@Component
struct UserNickname {
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @StorageLink('UserInfo') userInfo: UserInfoModel = new UserInfoModel()
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @State focus: boolean = false
  @State text: string = this.userInfo.nickname

  async handleUpdate() {
    if (!_.trim(this.text)) {
      CustomToast.toast_fail('昵称不能为空')
      return
    }

    if (this.text.length > 16) {
      CustomToast.toast_fail('昵称最长为16位')
      return
    }

    const response =
      await ccApiPost(this.Api_Context.getApiPrefix("ccApi") + CCApi.userUpdate, { 'nickname': this.text })
    if (response.code === 0) {
      CustomToast.toast_info("昵称设置成功")
      this.userInfo.nickname = this.text
      setTimeout(() => {
        this.pageInfos.pop()
      }, 1500)
    }
  }

  @Builder
  BuildNavRightBtn() {
    Button('完成', { buttonStyle: ButtonStyleMode.TEXTUAL })
      .margin({ left: -16 })
      .fontColor('#40A9FF')
      .onClick(() => this.handleUpdate())
  }

  build() {
    NavDestination() {
      TextInput({ placeholder: '请输入昵称', text: this.text })
        .margin({ left: 12, right: 12 })
        .backgroundColor(this.focus ? '#e4f2ff' : Color.White)
        .borderRadius(4)
        .borderWidth(1)
        .borderColor(this.focus ? '#40A9FF' : '#d9d9d9')
        .onFocus(() => this.focus = true)
        .onBlur(() => this.focus = false)
        .onChange((value: string) => this.text = value)
    }
    .title(CustomNavTitle('设置昵称', () => this.BuildNavRightBtn()))
    .backgroundColor("#f1f1f1")
  }
}

@Builder
export function UserNicknameBuilder() {
  UserNickname()
}