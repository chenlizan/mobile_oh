import _ from '@wolfx/lodash'
import { deviceInfo } from '@kit.BasicServicesKit';
import { identifier } from '@kit.AdsKit';
import {
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
  getLoginAccounts,
  CustomToast,
} from '@xy/basic';
import { LoginAccountModal } from './LoginAccountModal';
import { LoginRemindModal } from './LoginRemindModal';


export enum LoginType {
  Id_Card = 1, // 账号密码  废弃
  Phone = 2, // 手机号 废弃
  Id_Auth = 3, // 统一身份认证
  Default = 4 // 账号密码&手机号
}

@Component
export struct LoginPage {
  @Link globalPageIndex: string;
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @StorageLink('PreferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage()
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context(this.preferenceStorage?.school?.domain)
  @State showIdAuth: boolean = false
  @State accountDialogVisible: boolean = false
  @State remindDialogVisible: boolean = false
  @State school_id: string = ''
  @State school_name: string | undefined = this.preferenceStorage?.school?.name
  @State school: string | undefined = this.preferenceStorage?.school?.name
  @State username: string = ''
  @State password: string = ''
  @State login_info: ObjectUtil<never> = new ObjectUtil({})
  @State accounts: Record<string, Record<string, string>>[] = []

  aboutToAppear() {
    this.checkImportUnifiedAuth(this.preferenceStorage?.school?.code)
    this.getSchoolList()
    this.username = this.preferenceStorage.saveUsername ?? ''
    this.password = this.preferenceStorage.savePassword ?? ''
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
      if (this.preferenceStorage) {
        if (this.preferenceStorage.school) {
          this.preferenceStorage.school.id = this.school_id
        }
      }
    }
  }

  async handleLogin(accountId: string | null = null) {
    if (!checkUserName(this.username)) {
      return;
    }
    if (!checkPassWord(this.password)) {
      return;
    }

    this.preferenceStorage.saveUsername = this.username
    this.preferenceStorage.savePassword = this.password

    CustomToast.toast_loading('登录中...')

    const response = await ccApiPost(this.Api_Context.getApiPrefix('ccApi') + CCApi.unifiedCheckInfraLogin,
      {
        'loginType': LoginType.Default,
        'weekNoLoginStatus': true,
        'schoolId': this.school_id,
        'password': encryptDes(this.password, this.preferenceStorage?.des_encrypt_key?.[2] ?? ''),
        'loginName': encryptDes(this.username, this.preferenceStorage?.des_encrypt_key?.[3] ?? ''),
        'xyAccountId': accountId,
      },
      {
        'mobile-device-id': await identifier.getOAID(),
        'mobile-brand': deviceInfo.brand,
        'mobile-model': deviceInfo.productModel,
      })
    if (response.code === 200) {
      this.login_info = new ObjectUtil(response.result as ObjectOption<never>)
      this.login_info.setValue('access_token', this.login_info.getValue('token'))
      this.login_info.setValue('refresh_token', this.login_info.getValue('refreshToken'))

      if (!_.isEmpty(this.login_info.getValue('accounts'))) {
        const accounts = getLoginAccounts(
          this.login_info.getValue('accounts') ?? [],
          this.preferenceStorage?.school?.code as number | string,
        );
        if (accounts.length === 1) {
          new ObjectUtil(accounts[0]).getValue('id')
          this.handleLogin(String(new ObjectUtil(accounts[0]).getValue('id')))
        } else {
          this.accountDialogVisible = true
          this.accounts = accounts
          CustomToast.hide()
          return
        }
      }

      if (!this.login_info.getValue('access_token')) {
        this.login_info.setValue('needActive', this.login_info.getValue('isUnSafePassword'))
      }

      if (!this.login_info.getValue('phoneStatus') ||
      this.login_info.getValue('isUnSafePassword') ||
      this.login_info.getValue('passwordExpiredStatus')) {
        this.remindDialogVisible = true
      } else {
        this.savaLoginInfo()
      }
    }
    CustomToast.hide()
  }

  savaLoginInfo() {
    this.preferenceStorage.access_token = this.login_info.getValue('access_token')
    this.preferenceStorage.refresh_token = this.login_info.getValue('refresh_token')
    this.preferenceStorage.refresh_token_state = '0'
    this.preferenceStorage.selectSpace = {
      type: 'teaching',
      title: '教学空间'
    }
    this.globalPageIndex = RouterConstants.IDENTITY_PAGE_URL
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
          this.preferenceStorage.saveUsername = undefined
          this.preferenceStorage.savePassword = undefined
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
          .onClick(() => this.pageInfos.pushPath({ name: 'resetPassword' }))

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
              this.pageInfos.pushPath({
                name: 'authLogin', onPop: (popInfo: PopInfo) => {
                  if (popInfo.result === RouterConstants.IDENTITY_PAGE_URL) {
                    this.globalPageIndex = RouterConstants.IDENTITY_PAGE_URL
                  }
                }
              })
            })
          }

        }
        .height(420)
        .margin({
          left: 24, right: 24
        })
        .justifyContent(FlexAlign.SpaceBetween)

      }
      .width('100%')
      .height('100%')

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
          this.remindDialogVisible = false
          this.savaLoginInfo()
        },
        onDeal: () => {
          this.remindDialogVisible = false
          this.savaLoginInfo()
          setTimeout(() => {
            this.pageInfos.pushPath({ name: 'userEdit' })
          }, 1500)
        }
      })

      LoginAccountModal({
        accounts: $accounts,
        visible: $accountDialogVisible,
        onSelect: (item) => {
          this.handleLogin(item?.id)
        }
      })
    }
  }
}
