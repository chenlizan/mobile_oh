import _ from "@wolfx/lodash";
import {
  Api_Context,
  CCApi,
  ccApiPost,
  checkPassWordSame,
  CustomField,
  CustomModalDialog,
  CustomToast,
  IconConstants,
  ObjectUtil,
  PARAMS,
  verifyPassWord
} from "@xy/basic";

@Component
export struct AccountActivation {
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack();
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @State title:string = '提示'
  @State accountDialogVisible: boolean = false
  @State username: string = ''
  @State password1: string = ''
  @State password2: string = ''
  @State accounts: PARAMS[] = []
  private param: ObjectUtil<never> = new ObjectUtil({})

  async userCheckRealnameByAT(realname: string, authToken: string): Promise<boolean> {
    const response = await ccApiPost(this.Api_Context.getApiPrefix('ccApi') + CCApi.userCheckRealnameByAT,
      { 'realname': realname, 'authToken': authToken })
    if (response.code === 200) {
      return true
    } else {
      return false
    }
  }

  async queryUserInfoUnionAccountsByAT(authToken: string) {
    const response = await ccApiPost(this.Api_Context.getApiPrefix('ccApi') + CCApi.queryUserInfoUnionAccountsByAT,
      { 'authToken': authToken },
    )
    if (response.code === 200) {
      return response?.result ?? [];
    } else {
      return [];
    }
  }

  async appActivationByAT(password: string, realname: string, token: string) {
    const response = await ccApiPost(this.Api_Context.getApiPrefix('ccApi') + CCApi.appActivationByAT,
      {
        "password": password,
        "realname": realname,
        "authToken": token,
      })
    if (response.code === 200) {
      CustomToast.toast_success(`账号激活成功`)
      this.pageInfos.pop()
    } else if (response.code === 5100051) {
      CustomToast.toast_fail(`真实姓名与账号不符`)
    } else {
      CustomToast.toast_fail(`密码重置失败`)
    }

  }

  async handleSubmit() {
    if (!_.trim(this.username)) {
      CustomToast.toast_fail('请输入真实姓名')
      return;
    }

    if (!checkPassWordSame(this.password1, this.password2)) {
      return;
    }

    if (!verifyPassWord(this.password1) || !verifyPassWord(this.password2)) {
      return;
    }
    const res = await this.userCheckRealnameByAT(this.username, this.param.getValue('infraAccessToken'))
    if (res) {
      const accounts = await this.queryUserInfoUnionAccountsByAT(this.param.getValue('infraAccessToken'))
      if (!_.isEmpty(accounts) && _.isArray(accounts) && accounts.length > 1) {
        this.accounts = accounts as PARAMS[];
        this.accountDialogVisible = true
      } else {
        this.appActivationByAT(this.password1, this.username, this.param.getValue('infraAccessToken'));
      }
    } else {
      CustomToast.toast_fail('真实姓名与账号不符')
    }
  }

  aboutToAppear(): void {
    this.param = new ObjectUtil(JSON.parse(String(this.pageInfos.getParamByName('accountActivation')[0])))
  }

  @Builder
  BuildModalContent(accounts: PARAMS[] | string[]) {
    Flex({ direction: FlexDirection.Column }) {
      Text('检测到当前手机号已绑定其他账号，继续操作将重置所有账号密码')
        .margin(10)
        .padding(10)
        .backgroundColor('#FFFBF3')
        .fontColor('#FF931E')
        .fontSize(13)
      List() {
        ForEach(accounts, (item: Record<string, string>) => {
          ListItem() {
            Row() {
              Image(item.schoolIcon)
                .width(48)
                .height(48)
                .margin({ left: 12, right: 12 })
              Column() {
                Text(item.schoolName)
                Text(item.loginName)
                  .margin({ top: 8 })
              }
            }
            .width('100%')
            .margin({ left: 8, bottom: 4 })
            .alignItems(VerticalAlign.Center)
          }
        })
      }
    }
  }

  @Builder
  BuildModalFooter() {
    Flex({ direction: FlexDirection.Row }) {
      Button('取消', { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.NORMAL })
        .margin({ left: 8, right: 8 })
        .backgroundColor('#f5f5f5')
        .border({ width: 1, color: '#999999' })
        .borderRadius(4)
        .fontColor('#999999')
        .flexGrow(1)
        .onClick(() => {
          this.accountDialogVisible = false
        })

      Button('确定', { type: ButtonType.Normal })
        .margin({ left: 8, right: 8 })
        .borderRadius(4)
        .flexGrow(1)
        .onClick(() => {
          this.appActivationByAT(this.password1, this.username, this.param.getValue('infraAccessToken'))
        })
    }
    .margin({ top: 8, bottom: 8 })
  }

  build() {
    NavDestination() {
      Column() {
        Row() {
          Text('设置密码')
            .fontColor('#333333')
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)

        Text('请设置本系统密码（非某学校的统一认证密码）')
          .padding(10)
          .backgroundColor('#fef6e6')
          .fontColor('#fbad13')
          .fontSize(12)

        CustomField({
          value: $username,
          iconCode: IconConstants.USER,
          placeholder: '请输入真实姓名',
        })
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

        Button('提交', { type: ButtonType.Normal })
          .width('100%')
          .borderRadius(4)
          .backgroundColor('#40A9FF')
          .onClick(() => this.handleSubmit())
      }
      .height(360)
      .margin({
        left: 24, right: 24
      })
      .justifyContent(FlexAlign.SpaceBetween)

      CustomModalDialog({
        visible: $accountDialogVisible,
        title: this.title,
        contentBuilder: () => this.BuildModalContent(this.accounts),
        footerBuilder: () => this.BuildModalFooter(),
      })
    }
  }
}

@Builder
export function AccountActivationBuilder() {
  AccountActivation()
}