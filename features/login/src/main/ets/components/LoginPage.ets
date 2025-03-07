import _ from '@wolfx/lodash'
import {
  xyApiPost,
  RouterConstants,
  Api_Context,
  UserInfoModel,
  ccApiGet,
  ObjectUtil,
  CCApi,
  ObjectOption,
  PreferenceStorage,
  School,
  AppIcon,
  IconConstants,
  CustomDivider,
} from '@xy/basic';

@Component
export struct LoginPage {
  @Link globalPageIndex: string;
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @StorageLink('preferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage();
  @State school_name: string | undefined = this.preferenceStorage?.school?.name

  aboutToAppear() {
  }

  handleLogin = async () => {
    const res = await xyApiPost(this.Api_Context.getApiPrefix('baseApi') + 'oauth2/public/login/byid',
      { 'id': '5524075382300476791' },
      {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': 'Basic YWlzdGFybW9vYzoyN2E5NWUxYjExMDQ3MGExNWQ5NTQzNmY5ZWRmZDk4Mg=='
      },)
    if (res) {
      if (res.success) {
        this.globalPageIndex = RouterConstants.MAIN_PAGE_URL
      }
    }
  }

  @Builder
  BuildField(iconCode: string = '', text: string = '', placeholder: string = '', enabled: boolean = true,
    inputType: InputType = InputType.Normal) {
    Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center }) {
      AppIcon({
        iconCode: iconCode,
        iconColor: '#40A9FF',
        iconSize: 16,
        iconMargin: { left: 12, right: 0.5 },
      })
      TextInput({ text: text, placeholder })
        .enabled(enabled)
        .borderRadius(0)
        .backgroundColor(enabled ? Color.White : '#33dfe3ea')
        .placeholderColor('#99999999')
        .fontColor('#999999')
        .type(inputType)
    }
    .backgroundColor(enabled ? Color.White : '#33dfe3ea')
    .borderColor('#dfe3ea')
    .borderRadius(4)
    .borderWidth(1)
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
          this.BuildField(IconConstants.HOME, this.preferenceStorage?.school?.name, '', false)
          this.BuildField(IconConstants.USER, '', '请输入手机号/账号')
          this.BuildField(IconConstants.LOCK, '', '请输入密码', true, InputType.Password)

          Button('登录', { type: ButtonType.Normal })
            .width('100%')
            .borderRadius(4)
            .backgroundColor('#40A9FF')
            .onClick(this.handleLogin)

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

        }
        .height('60%')
        .margin({
          left: 24, right: 24
        })
        .justifyContent(FlexAlign.SpaceBetween)

      }
      .width('100%')
      .height('100%')
    }
  }
}
