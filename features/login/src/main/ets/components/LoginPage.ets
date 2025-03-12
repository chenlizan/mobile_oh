import _ from '@wolfx/lodash'
import {
  xyApiPost,
  RouterConstants,
  Api_Context,
  PreferenceStorage,
  AppIcon,
  IconConstants,
  CustomDivider,
  CustomField,
  checkUserName,
  checkPassWord,
  ccApiPost,
  CCApi,
  ccApiGet,
  encryptDes,
  ObjectUtil,
  ObjectOption,
  CustomModalDialog,
  getIdentityList,
} from '@xy/basic';


class Login_Info {
  username?: string
  password?: string
  type?: string
}

@Component
export struct LoginPage {
  @Link globalPageIndex: string;
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack();
  @StorageLink('PreferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage();
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context(this.preferenceStorage?.school?.domain)
  @State showIdAuth: boolean = false
  @State remindDialogVisible: boolean = false
  @State school_id: string = ''
  @State school_name: string | undefined = this.preferenceStorage?.school?.name
  @State school: string | undefined = this.preferenceStorage?.school?.name
  @State username: string = ''
  @State password: string = ''
  @State login_info: ObjectUtil<never> = new ObjectUtil({})

  aboutToAppear() {
    this.getDesEncryptKey(['1', '2', '5', '6'])
    this.checkImportUnifiedAuth(this.preferenceStorage?.school?.code)
    this.getSchoolList()
  }

  async getDesEncryptKey(params: Array<string>) {
    const response = await ccApiPost(this.Api_Context.getApiPrefix('ccApi') + CCApi.queryDesEncryptKey, params)
    if (response.code === 200) {
      this.preferenceStorage.des_encrypt_key = response.result as Array<string>
    }
  }

  async checkImportUnifiedAuth(schoolCertify: string | number | undefined) {
    const response = await ccApiGet(this.Api_Context.getApiPrefix('ccApi') + CCApi.checkImportUnifiedAuth,
      { 'schoolCertify': schoolCertify })
    if (response.code === 200) {
      this.showIdAuth = true
    }
  }

  async getSchoolList() {
    const response = await ccApiPost(this.Api_Context.getApiPrefix('ccApi') + CCApi.getSchoolList, {},)
    if (response.code === 200) {
      const schoolList = response.result
      let school_info =
        _.find(schoolList, (o: object) => {
          if (o['schoolCertify'] === this.preferenceStorage.school?.code) {
            return true
          }
          return false
        })
      const school_info_obj = new ObjectUtil(school_info ?? {} as ObjectOption<never>)
      this.school_id = school_info_obj.getValue('id') as string
    }
  }

  async currentUserInfo() {
    const response = await ccApiGet(this.Api_Context.getApiPrefix('ccApi') + CCApi.getUserInfo)
    if (response.code === 200) {
    }
  }

  async handleLogin() {
    if (!checkUserName(this.username)) {
      return;
    }
    if (!checkPassWord(this.password)) {
      return;
    }

    if (_.isEmpty(this.preferenceStorage.des_encrypt_key)) {

    } else {
      const response = await ccApiPost(this.Api_Context.getApiPrefix('ccApi') + CCApi.unifiedCheckInfraLogin,
        {
          'loginType': 4,
          'weekNoLoginStatus': true,
          'schoolId': this.school_id,
          'password': encryptDes(this.password, this.preferenceStorage?.des_encrypt_key?.[2] ?? ''),
          'loginName': encryptDes(this.username, this.preferenceStorage?.des_encrypt_key?.[3] ?? ''),
          'login_info': {
            username: this.username,
            password: this.password,
            type: 'xiaoya',
          } as Login_Info,
        },
        {
          'mobile-device-id': '',
          'mobile-brand': '',
          'mobile-model': '',
        })
      if (response.code === 200) {
        this.login_info = new ObjectUtil(response.result as ObjectOption<never>)
        this.login_info.setValue('access_token', this.login_info.getValue('token'))
        this.login_info.setValue('refresh_token', this.login_info.getValue('refreshToken'))

        if (!_.isEmpty(this.login_info.getValue('accounts'))) {
          // 如果用户手机号绑定多账号，需要选择账号重新登录
          return
        }

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

    // const res = await xyApiPost(this.Api_Context.getApiPrefix('baseApi') + 'oauth2/public/login/byid',
    //   { 'id': '5524075382300476791' },
    //   {
    //     'Content-Type': 'application/x-www-form-urlencoded',
    //     'Authorization': 'Basic YWlzdGFybW9vYzoyN2E5NWUxYjExMDQ3MGExNWQ5NTQzNmY5ZWRmZDk4Mg=='
    //   },)
    // if (res) {
    //   if (res.success) {
    //     this.globalPageIndex = RouterConstants.MAIN_PAGE_URL
    //   }
    // }
  }

  savaLoginInfo() {
    const manageSpaces = getIdentityList(this.login_info)
    this.preferenceStorage.access_token = this.login_info.getValue('access_token')
    this.preferenceStorage.refreshToken = this.login_info.getValue('refresh_token')
    this.preferenceStorage.refresh_token_state = '0'
    this.preferenceStorage.need_select_space = manageSpaces.length > 0
  }

  getQuestionText = () => {
    const data = this.login_info
    let remind: Array<string> = []
    if (!data.getValue('phoneStatus')) {
      remind.push('账号未绑定手机号');
    }
    if (data.getValue('isUnSafePassword')) {
      remind.push('账号的密码安全性较低');
      if (data.getValue('over90DaysNoLogin')) {
        remind.push('账号超过90天未登录');
      }
    }
    if (data.getValue('passwordExpiredStatus')) {
      remind.push('账号的密码超过90天未更换');
    }
    return remind;
  };

  @Builder
  BuildRemindText(data: ObjectUtil<never>, phoneRemind: string, bufferCount: number, activeText: string) {
    Column() {
      if (data.getValue('isUnSafePassword') && data.getValue('isUseBuffer')) {
        if ((data.getValue('totalBufferCount') - data.getValue('useBufferCount')) > 0) {
          Text(`注意：${phoneRemind}当前密码为弱密码，以弱密码登录次数剩余${bufferCount}次。用尽后，系统将强制修改密码。为保障账号安全，请${activeText}修改本系统密码（注意：不是修改学校统一身份认证的密码）。`)
            .fontSize(13)
            .fontColor('#FF4040')
        } else {
          Text(`注意：${phoneRemind}当前密码为弱密码，以弱密码登录次数剩余0次。为保障账号安全，请${activeText}修改本系统密码（注意：不是修改学校统一身份认证的密码）。`)
            .fontSize(13)
            .fontColor('#FF4040')
        }
      } else if (data.getValue('isUnSafePassword')) {
        Text(`注意：${phoneRemind}为保障账号安全，请${activeText}修改本系统密码（注意：不是修改学校统一身份认证的密码）。`)
          .fontSize(13)
          .fontColor('#FF4040')
      } else if (!data.getValue('isUnSafePassword')) {
        if (!data.getValue('phoneStatus') && !data.getValue('passwordExpiredStatus')) {
          Text(`注意：${phoneRemind}`)
            .fontSize(13)
            .fontColor('#FF4040')
        } else if (data.getValue('passwordExpiredStatus')) {
          Text(`注意：${phoneRemind}为保障账号安全，请${activeText}修改本系统密码（注意：不是修改学校统一身份认证的密码）。`)
            .fontSize(13)
            .fontColor('#FF4040')
        }
      } else {
        Text(null)
      }
    }
  }

  @Builder
  BuildModalContent(login_info: ObjectUtil<never>) {
    Column() {
      Flex({ direction: FlexDirection.Column }) {
        Text('检测到当前登录账号存在以下安全问题:')
          .fontSize(14)
        Column() {
          ForEach(this.getQuestionText(), (item: string) => {
            Text(item)
              .fontSize(14)
              .fontColor('#999999')
          })
        }
        .margin({ top: 12, bottom: 12 })

        this.BuildRemindText(login_info,
          login_info.getValue('phoneStatus') ? '为了通过手机号找回密码，请及时绑定手机号。' : '',
          login_info.getValue('totalBufferCount') - login_info.getValue('useBufferCount'),
          login_info.getValue('needActive') ? '立即' : '及时')
      }
      .margin(16)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  BuildModalFooter(login_info: ObjectUtil<never>) {
    Row() {
      if (login_info.getValue('needActive')) {
        Button('修改密码', { type: ButtonType.Normal })
          .margin({ right: 8 })
          .borderRadius(4)
          .onClick(() => {
            this.remindDialogVisible = false
            this.pageInfos.pushPath({
              name: 'accountActivation',
              param: JSON.stringify({ infraAccessToken: login_info.getValue('infraAccessToken') })
            })
          })
      } else {
        Button('继续登录', { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.NORMAL })
          .margin({ right: 8 })
          .backgroundColor(Color.White)
          .border({ width: 1, color: '#999999' })
          .borderRadius(4)
          .fontColor('#999999')
          .onClick(() => {
            this.savaLoginInfo()
          })

        Button('去处理', { type: ButtonType.Normal })
          .margin({ right: 8 })
          .borderRadius(4)
          .onClick(() => {
            // const {navigation} = this.props;
            // this.onSaveAuth(data);
            //
            // // 默认 教学空间
            // this.onSetDefaultSpace();
            //
            // navigation.replace('root');
            // navigation.push('userEdit', {
            //   title: t('auth:sign_in.handle_deal.user_edit'),
            // });
          })
      }
    }
    .width('100%')
    .margin({ bottom: 8 })
    .justifyContent(FlexAlign.End)
  }

  build() {
    NavDestination() {
      Column() {
        Row() {
          AppIcon({
            iconCode: IconConstants.CHOOSE_SCHOOL,
            iconColor: '#40A9FF',
            iconSize: 16,
            iconMargin: { left: 16 },
          })
          Text('选择学校')
            .margin({ left: 8 })
            .fontColor('#40A9FF')
            .fontWeight(FontWeight.Medium)
        }
        .width('100%')
        .margin(24)
        .justifyContent(FlexAlign.Start)
        .onClick(() => {
          this.globalPageIndex = RouterConstants.SCHOOL_PAGE_URL
        })

        Column() {
          Image(this.preferenceStorage?.school?.logo)
            .width(76)
            .height(76)
          Text(this.preferenceStorage?.school?.banner_name)
            .margin({ top: 16, bottom: 16 })
        }

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

          Row() {
            Text('忘记密码')
              .fontColor('#40A9FF')
              .fontSize(14)
            AppIcon({
              iconCode: IconConstants.RIGHT,
              iconColor: '#40A9FF',
            })
          }
          .width('100%')
          .margin({ bottom: 12 })
          .justifyContent(FlexAlign.End)

          CustomDivider({ text: '其他登录方式' })

          if (this.showIdAuth) {
            Column() {
              AppIcon({
                iconCode: IconConstants.AUTH,
                iconColor: '#0ABCD6',
                iconSize: 24
              })
              Text('统一身份认证')
                .lineHeight(20)
                .fontSize(12)
                .fontColor('#999999')
            }
            .onClick(() => {
              this.pageInfos.pushPath({ name: 'authLogin' })
            })
          }

        }
        .height('60%')
        .margin({
          left: 24, right: 24
        })
        .justifyContent(FlexAlign.SpaceBetween)

      }
      .width('100%')
      .height('100%')

      CustomModalDialog({
        visible: $remindDialogVisible,
        title: '账号安全提示',
        contentBuilder: () => this.BuildModalContent(this.login_info),
        footerBuilder: () => this.BuildModalFooter(this.login_info),
      })
    }
  }
}
