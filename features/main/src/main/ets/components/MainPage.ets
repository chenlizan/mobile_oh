import { BreakpointUtil, CommonConstants } from '@xy/basic';
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
