import { xyApiPost, RouterConstants, Api_Context } from '@xy/basic';

interface REQUEST_PARAM {
  'id': string;
  'Content-Type': string
  'Authorization': string
}

@Component
export struct LoginPage {
  @Link globalPageIndex: string;
  private domain: string = 'ccnu'
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context(this.domain)

  async aboutToAppear() {
  }

  handleLogin = async () => {
    const res = await xyApiPost(this.Api_Context.getApiPrefix('baseApi') + 'oauth2/public/login/byid',
      { 'id': '5524075382300476791' } as REQUEST_PARAM,
      {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': 'Basic YWlzdGFybW9vYzoyN2E5NWUxYjExMDQ3MGExNWQ5NTQzNmY5ZWRmZDk4Mg=='
      } as REQUEST_PARAM,)
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
