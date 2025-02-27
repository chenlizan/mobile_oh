import { CommonConstants, RouterConstants } from '@xy/basic';
import { LoginPage } from '@xy/login'
import { MainPage } from '@xy/main'


@Entry
@Component
struct Index {
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack();
  @State globalPageIndex: string = RouterConstants.LOGIN_PAGE_URL

  @Builder
  PagesMap(name: string, param?: object) {

  }

  build() {
    Navigation(this.pageInfos) {
      if (this.globalPageIndex === RouterConstants.LOGIN_PAGE_URL) {
        LoginPage({ globalPageIndex: this.globalPageIndex })
      } else if (this.globalPageIndex = RouterConstants.MAIN_PAGE_URL) {
        MainPage({ globalPageIndex: this.globalPageIndex })
      }
    }
    .mode(NavigationMode.Stack)
    .navDestination(this.PagesMap)
    .height(CommonConstants.FULL_HEIGHT_PERCENT)
    .hideTitleBar(true)
    .hideToolBar(true)
  }
}