import { emitter } from '@kit.BasicServicesKit';
import _ from '@wolfx/lodash';
import {
  Api_Context,
  CCApi,
  ccApiGet,
  CommonConstants,
  HomeApi,
  MessageApi,
  MessageCountModel,
  PreferenceStorage,
  RouterConstants,
  SystemApi,
  xyApiGet
} from '@xy/basic';
import { HomePage } from '@xy/home'
import { MessagePage } from '@xy/message';
import { MinePage } from '@xy/mine'
import { SystemNoticeModal } from './SystemNoticeModal';

@Component
export struct MainPage {
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @StorageLink('PreferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage()
  @StorageLink('messageCount') messageCount: MessageCountModel = new MessageCountModel()
  @Link globalPageIndex: string;
  @State backgroundImageY: number = 0;
  @State currentTabIndex: number = 0;
  @StorageProp('bottom') bottom: number = 0;
  @StorageLink('breakPoint') breakPoint: string = CommonConstants.BREAK_POINT_SM;

  aboutToAppear(): void {
    emitter.on("loginOut", async () => {
      await ccApiGet(this.Api_Context.getApiPrefix('ccApi') + CCApi.logout)
      this.preferenceStorage.access_token = undefined
      this.preferenceStorage.refresh_token = undefined
      this.globalPageIndex = RouterConstants.LOGIN_PAGE_URL
    })
    this.getAuthStore()
    this.getConfigCenter()
    this.getMessageUnReadCount()
  }

  async getAuthStore() {
    const response = await xyApiGet(this.Api_Context.getApiPrefix("baseApi_inner") + SystemApi.authStore)
    if (response.success) {
      const profile = (response.data as Record<string, Record<string, Record<string, string>>>).auth.profile
      this.preferenceStorage.node_key = profile.node_key
    }
  }

  async getConfigCenter() {
    const response =
      await xyApiGet(this.Api_Context.getApiPrefix("baseApi_out") + HomeApi.configSearch, { 'tags': 'front-end' })
    if (response.success) {
      const data = response.data as Record<string, string>[]
      this.preferenceStorage.configCenter = data
    }
  }

  async getMessageUnReadCount() {
    // const response = await xyApiGet(this.Api_Context.getApiPrefix("baseApi_out") + MessageApi.msgUnReadCount)
    // if (response.success) {
    //   const data = (response.data as Record<string, number>).un_read_count
    //   this.messageCount.total_un_read_count = data
    // }
  }

  @Builder
  BuildTabs(icon: Resource, unIcon: Resource, title: ResourceStr, index: number) {
    Column() {
      Image(this.currentTabIndex === index ? icon : unIcon)
        .width(this.currentTabIndex === index ? $r('app.float.common_select_image_width') :
        $r('app.float.common_image_width'))
        .height(this.currentTabIndex === index ? $r('app.float.common_select_image_height') :
        $r('app.float.common_image_height'))

      if (this.currentTabIndex !== index) {
        Text(title)
          .fontSize($r('app.float.tab_text_size'))
          .lineHeight($r('app.float.tab_text_height'))
          .fontWeight(FontWeight.Regular)
          .fontColor($r('app.color.tab_un_text'))
      }
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
              HomePage({ globalPageIndex: this.globalPageIndex })
            }
            .tabBar(this.BuildTabs($r('app.media.tab_home_active'), $r('app.media.tab_home'),
              $r('app.string.tab_bar_home'), 0))

            TabContent() {
              MessagePage({ globalPageIndex: this.globalPageIndex })
            }
            .tabBar(this.BuildTabs($r('app.media.tab_message_active'), $r('app.media.tab_message'),
              $r('app.string.tab_bar_message'), 1))
            .backgroundColor(Color.White)

            TabContent() {
              MinePage({ globalPageIndex: this.globalPageIndex })
            }
            .tabBar(this.BuildTabs($r('app.media.tab_profile_active'), $r('app.media.tab_profile'),
              $r('app.string.tab_bar_mine'), 2))

          }
          .vertical(this.breakPoint === CommonConstants.BREAK_POINT_LG)
          .barWidth(this.breakPoint === CommonConstants.BREAK_POINT_LG ?
          $r('app.float.tab_bar_width') : CommonConstants.TAB_BAR_HEIGHT_PERCENT)
          .barHeight(this.breakPoint === CommonConstants.BREAK_POINT_LG ?
          CommonConstants.TAB_HEIGHT_PERCENT : $r('app.float.tab_bar_height'))
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

      SystemNoticeModal()
    }
  }
}
