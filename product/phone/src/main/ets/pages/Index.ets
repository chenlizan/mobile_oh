import { CommonConstants,
  ObjectOption,
  ObjectUtil, PreferenceStorage, RouterConstants,
  SelectSpace } from '@xy/basic';
import { IdentitySelectPage, LoginPage } from '@xy/login'
import { MainPage } from '@xy/main'
import { AgreementPage } from '@xy/agreement'
import { SchoolPage } from '@xy/school';

@Entry
@Component
struct Index {
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack();
  @StorageLink('preferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage();
  @StorageLink('globalPageIndex') globalPageIndex: string = RouterConstants.LOGIN_PAGE_URL

  async  aboutToAppear() {
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
  jumpToRoot = () => {
    // 判断身份
    if (this.preferenceStorage?.need_select_space) {
      if (this.preferenceStorage?.selectSpace) {
        this.globalPageIndex = RouterConstants.MAIN_PAGE_URL
      } else {
        this.globalPageIndex = RouterConstants.IDENTITY_PAGE_URL
      }
    } else {
      let spaceData: SelectSpace = {
        type: 'teaching',
        title: '教学空间',
        role: '',
        schoolId: '',
        schoolName: '',
      };
      this.preferenceStorage.selectSpace = spaceData

      this.globalPageIndex = RouterConstants.MAIN_PAGE_URL
    }
  };

  jumpToLogin = () => {
    const school = new ObjectUtil(this.preferenceStorage?.school as ObjectOption<never>)
    if (school.getValue('is_other')) {
      // signOther
      this.globalPageIndex = RouterConstants.LOGIN_PAGE_URL
    } else {
      this.globalPageIndex = RouterConstants.LOGIN_PAGE_URL
    }
  };

  // 跳转到学校选择
  jumpToSchool = () => {
    this.globalPageIndex = RouterConstants.SCHOOL_PAGE_URL
  };

  jumpToAgreement = () => {
    this.globalPageIndex = RouterConstants.AGREEMENT_PAGE_URL
  }

  @Builder
  PagesMap(name: string, param?: object) {

  }

  build() {
    Navigation(this.pageInfos) {
      if (this.globalPageIndex === RouterConstants.AGREEMENT_PAGE_URL) {
        AgreementPage({ globalPageIndex: this.globalPageIndex })
      } else if (this.globalPageIndex === RouterConstants.SCHOOL_PAGE_URL) {
        SchoolPage({ globalPageIndex: this.globalPageIndex })
      } else if (this.globalPageIndex === RouterConstants.LOGIN_PAGE_URL) {
        LoginPage({ globalPageIndex: this.globalPageIndex })
      } else if (this.globalPageIndex = RouterConstants.MAIN_PAGE_URL) {
        MainPage({ globalPageIndex: this.globalPageIndex })
      } else if (this.globalPageIndex = RouterConstants.IDENTITY_PAGE_URL) {
        IdentitySelectPage({ globalPageIndex: this.globalPageIndex })
      }
    }
    .mode(NavigationMode.Stack)
    .navDestination(this.PagesMap)
    .height(CommonConstants.FULL_HEIGHT_PERCENT)
    .hideTitleBar(true)
    .hideToolBar(true)
  }
}