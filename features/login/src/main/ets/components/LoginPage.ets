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
} from '@xy/basic';

@Component
export struct LoginPage {
  @Link globalPageIndex: string;
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @StorageLink('preferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage();

  aboutToAppear() {
    // const res = new ObjectUtil(this.preferenceStorage.school as ObjectOption<never>)
    // console.log('school_code', res.getValue('code'))
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

  build() {
    NavDestination() {
      Row() {
        Column() {
          Button('登陆')
            .fontSize(50)
            .fontWeight(FontWeight.Bold)
            .buttonStyle(ButtonStyleMode.TEXTUAL)
            .onClick(this.handleLogin)
        }
        .width('100%')
      }
      .height('100%')
    }
  }
}
