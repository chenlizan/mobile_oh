import { CommonConstants, PreferenceStorage, RouterConstants, SelectSpace } from '@xy/basic';
import { IdentityPage, LoginPage } from '@xy/login'
import { MainPage } from '@xy/main'
import { AgreementPage } from '@xy/agreement'
import { SchoolPage } from '@xy/school';

@Entry
@Component
struct Index {
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack();
  @StorageLink('PreferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage();
  @StorageLink('globalPageIndex') globalPageIndex: string = RouterConstants.LOGIN_PAGE_URL
  @State private showSplash: boolean = true

  async aboutToAppear() {
    // 判断页面
    if (this.preferenceStorage.is_agreement) {
      if (this.preferenceStorage?.school) {
        if (this.preferenceStorage?.access_token) {
          this.jumpToRoot()
        } else {
          // 本地没有 auth，则跳转到登录页
          this.jumpToLogin()
        }
      } else {
        this.jumpToSchool()
      }
    } else {
      this.jumpToAgreement()
    }
  }

  // 跳转首页
  jumpToRoot() {
    // 判断身份
    if (this.preferenceStorage?.need_select_space) {
      if (this.preferenceStorage?.selectSpace) {
        this.globalPageIndex = RouterConstants.MAIN_PAGE_URL
      } else {
        this.globalPageIndex = RouterConstants.IDENTITY_PAGE_URL
      }
    } else {
      this.preferenceStorage.selectSpace = {
        type: 'teaching',
        title: '教学空间',
        role: '',
        schoolId: '',
        schoolName: '',
      } as SelectSpace

      this.globalPageIndex = RouterConstants.MAIN_PAGE_URL
    }
  };

  jumpToLogin() {
    if (this.preferenceStorage?.school?.is_other) {
      // signOther
      this.globalPageIndex = RouterConstants.LOGIN_PAGE_URL
    } else {
      this.globalPageIndex = RouterConstants.LOGIN_PAGE_URL
    }
  };

  // 跳转到学校选择
  jumpToSchool() {
    this.globalPageIndex = RouterConstants.SCHOOL_PAGE_URL
  };

  jumpToAgreement() {
    this.globalPageIndex = RouterConstants.AGREEMENT_PAGE_URL
  }

  @Builder
  PagesMap(name: string, param?: object) {
  }

  @Builder
  BuildSplash() {
    Column() {
      Image($r('app.media.splash'))
        .width(300)
        .height(273)
        .margin({ top: 146 })
      Column() {
        Text('小雅')
          .margin({ bottom: 12 })
        Text('Copyright © 2015-2021 版权所有: 华中师范大学')
          .fontSize(12)
        Text('鄂ICP备 05003325号-10')
          .fontSize(12)
      }
      .margin({ bottom: 20 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .backgroundColor('#eff9ff')
    .transition(TransitionEffect.OPACITY.animation({ duration: 2000, playMode: PlayMode.Reverse }), () => {
      this.showSplash = false
    })
  }

  build() {
    Navigation(this.pageInfos) {
      if (this.showSplash) {
        this.BuildSplash()
      } else {
        if (this.globalPageIndex === RouterConstants.AGREEMENT_PAGE_URL) {
          AgreementPage({ globalPageIndex: this.globalPageIndex })
        } else if (this.globalPageIndex === RouterConstants.SCHOOL_PAGE_URL) {
          SchoolPage({ globalPageIndex: this.globalPageIndex })
        } else if (this.globalPageIndex === RouterConstants.LOGIN_PAGE_URL) {
          LoginPage({ globalPageIndex: this.globalPageIndex })
        } else if (this.globalPageIndex = RouterConstants.MAIN_PAGE_URL) {
          MainPage({ globalPageIndex: this.globalPageIndex })
        } else if (this.globalPageIndex = RouterConstants.IDENTITY_PAGE_URL) {
          IdentityPage({ globalPageIndex: this.globalPageIndex })
        }
      }
    }
    .mode(NavigationMode.Stack)
    .navDestination(this.PagesMap)
    .height(CommonConstants.FULL_HEIGHT_PERCENT)
    .hideTitleBar(true)
    .hideToolBar(true)
  }
}