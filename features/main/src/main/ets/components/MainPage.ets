import _ from '@wolfx/lodash';
import { Api_Context, BreakpointUtil,
  CCApi,
  ccApiGet, CommonConstants,
  ObjectOption,
  ObjectUtil,
  PreferenceStorage,
  RouterConstants,
  UserInfoModel,
  xyApiPost } from '@xy/basic';
import { HomePage } from '@xy/home'
import { MinePage } from '@xy/mine'


@Component
export struct MainPage {
  @Link globalPageIndex: string;
  @State backgroundImageY: number = 0;
  @State currentTabIndex: number = 0;
  @StorageProp('bottom') bottom: number = 0;
  @StorageLink('breakPoint') breakPoint: string = CommonConstants.BREAK_POINT_SM;
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack();
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context('ccnu')
  @StorageLink('UserInfo') userInfo: UserInfoModel = new UserInfoModel()
  @StorageLink('preferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage();

  aboutToAppear() {
    this.handleLogin()
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
    this.handleUserInfo()
  }

  async handleUserInfo() {
    const infra_userinfo_response = await ccApiGet(this.Api_Context.getApiPrefix('ccApi') + CCApi.queryInfraUserInfo)
    if (infra_userinfo_response.code === 200) {
      this.userInfo.mobile =
        new ObjectUtil(infra_userinfo_response.result as ObjectOption<never>).getValue('mobile')
    }

    const userinfo_response = await ccApiGet(this.Api_Context.getApiPrefix('ccApi') + CCApi.getUserInfo)
    if (userinfo_response.code === 200) {
      const res = new ObjectUtil(userinfo_response.result as ObjectOption<never>)
      this.userInfo.userId = res.getValue('id')
      this.userInfo.id = res.getValue('authorId')
      this.userInfo.nickname = res.getValue('nickname')
      this.userInfo.realname = res.getValue('realname')
      this.userInfo.avatar = res.getValue('headImageUrl') || res.getValue('avatar')
      this.userInfo.schools = res.getValue('schoolRoleInfos')
      this.userInfo.fileCapacity = res.getValue('userFileCapacityLevel')
      this.userInfo.isSchoolFellow = (res.getValue('schoolRoleInfos') ?? [].length ?? 0) !== 0;

      _.forEach(res.getValue('schoolRoleInfos'), (info: never) => {
        const _info = new ObjectUtil(info as ObjectOption<never>)
        _.map(_info.getValue('roleDepartmentList') ?? [], (depart: never) => {
          const _depart = new ObjectUtil(info as ObjectOption<never>)
          if (_depart.getValue('roleCode') === 'JS010' && _info.getValue('zsFlag') === 0) {
            this.userInfo.isSchoolFellow = true;
            this.userInfo.hasStudent = true;
          }

          if (_depart.getValue('roleCode') === 'JS005') {
            this.userInfo.hasStudent = true;
          }

          if (_depart.getValue('roleCode') !== 'JS005' && _depart.getValue('roleCode') !== 'JS010') {
            this.userInfo.isRealStudent = false;
          }
        });
      });

      this.preferenceStorage.access_token = 'access_token'
    }
  }


  getTabBarColor(index: number, currentTabIndex: number, breakPoint: string): ResourceColor {
    if (this.backgroundImageY < -20 && this.currentTabIndex === 0 && index === 0) {
      return $r('app.color.tab_choose_image')
    } else if (index === 0 && breakPoint === CommonConstants.BREAK_POINT_LG) {
      return currentTabIndex === index ? Color.White : $r('app.color.tab_un_image');
    }
    return currentTabIndex === index ? $r('app.color.tab_choose_image') : $r('app.color.tab_un_image');
  }

  @Builder
  BuildTabs(icon: Resource, title: ResourceStr, index: number) {
    Column() {
      Image(icon)
        .width($r('app.float.common_image_width'))
        .height($r('app.float.common_image_height'))
        .fillColor(this.getTabBarColor(index, this.currentTabIndex, this.breakPoint))
      Text(title)
        .fontSize($r('app.float.tab_text_size'))
        .lineHeight($r('app.float.tab_text_height'))
        .fontWeight(FontWeight.Regular)
        .fontColor(this.getTabBarColor(index, this.currentTabIndex, this.breakPoint))
    }
  }

  @Builder
  BuildTabsMine(icon: Resource, unIcon: Resource, title: ResourceStr, index: number) {
    Column() {
      Image(this.currentTabIndex === index ? icon : unIcon)
        .width($r('app.float.common_image_width'))
        .height($r('app.float.common_image_height'))
      Text(title)
        .fontSize($r('app.float.tab_text_size'))
        .lineHeight($r('app.float.tab_text_height'))
        .fontWeight(FontWeight.Regular)
        .fontColor(this.getTabBarColor(index, this.currentTabIndex, this.breakPoint))
    }
  }

  build() {
    NavDestination() {
      Row() {
        Column() {
          Tabs({
            barPosition: this.breakPoint === CommonConstants.BREAK_POINT_LG ? BarPosition.Start : BarPosition.End
          }) {
            TabContent() {
              HomePage()
            }
            .tabBar(this.BuildTabs($r('app.media.ic_public_home_filled'), $r('app.string.tab_bar_home'), 0))

            TabContent() {
              MinePage()
            }
            .tabBar(this.BuildTabsMine($r('app.media.ic_home_mine'), $r('app.media.ic_home_mine_filled'),
              $r('app.string.tab_bar_mine'), 1))
            .backgroundColor(Color.White)
          }
          .vertical(this.breakPoint === CommonConstants.BREAK_POINT_LG)
          .barWidth(this.breakPoint === CommonConstants.BREAK_POINT_LG ?
          $r('app.float.tab_bar_width') : CommonConstants.TAB_BAR_HEIGHT_PERCENT)
          .barHeight(this.breakPoint === CommonConstants.BREAK_POINT_LG ?
          CommonConstants.TAB_HEIGHT_PERCENT : $r('app.float.tab_bar_height'))
          .backgroundImage(this.currentTabIndex === 0 ? new BreakpointUtil({
            sm: $r('app.media.ic_home_phone_background'),
            md: $r('app.media.ic_home_fold_background'),
            lg: $r('app.media.ic_home_tablet_background')
          }).getValue(this.breakPoint) : $r('app.media.ic_home_not_background'))
          .backgroundImageSize(ImageSize.Contain)
          .backgroundImagePosition({
            y: this.backgroundImageY
          })
          .backgroundColor($r('app.color.home_background'))
          .scrollable(false)
          .onChange((index: number) => {
            this.currentTabIndex = index;
          })
          .padding({
            bottom: this.bottom
          })
        }
        .width('100%')
      }
      .height('100%')
    }
  }
}
