import { display } from "@kit.ArkUI"
import dayjs from "dayjs"
import {
  Api_Context,
  AppIcon,
  CustomNavTitle,
  HomeApi,
  IconConstants,
  PreferenceStorage,
  translateRichText,
  xyApiGet
} from "@xy/basic"

@Component
struct CourseNotice {
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @StorageLink('PreferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage()
  @State screenWidth: number = 0
  @State isRefreshing: boolean = false
  @State notices: Record<string, string> [] = []
  @State pageNum: number = 1
  @State total_num: number = 0
  private courseInfo = this.preferenceStorage.currentTeam ?? {}
  private requesting: boolean = false

  async getData() {
    if (this.requesting) {
      return
    }
    this.requesting = true
    const response = await xyApiGet(this.Api_Context.getApiPrefix('baseApi_inner') + HomeApi.queryAnnouncementList, {
      'group_id': this.courseInfo.id,
      'page_index': this.pageNum,
      'page_size': 10,
    })
    if (response.success) {
      const data = response.data as Record<string, Record<string, string>[] | number>
      this.notices = this.notices.concat(data.data as Record<string, string>[])
      this.pageNum += 1
      this.total_num = data.count as number
    }
    this.requesting = false
  }

  async aboutToAppear(): Promise<void> {
    this.screenWidth = px2vp(display.getDefaultDisplaySync().width)
  }

  @Builder
  BuildNavRightBtn() {
    AppIcon({
      iconCode: IconConstants.ADD,
      iconColor: '#41A9FF',
      iconPadding: 4,
      iconSize: 16,
      onClickBtn: () =>
      this.pageInfos.pushPath({
        name: 'createCourseNotice', onPop: async () => {
          this.notices = []
          this.pageNum = 1
          await this.getData()
        }
      })
    })
  }

  build() {
    NavDestination() {
      Refresh({ refreshing: $$this.isRefreshing }) {
        Flex({ direction: FlexDirection.Column }) {
          List({ space: 12 }) {
            ForEach(this.notices, (item: Record<string, string>) => {
              ListItem() {
                Flex() {
                  Column() {
                    Text(translateRichText(item.content))
                      .padding({ bottom: 12 })
                      .fontSize(14)
                    Text(dayjs(item.created_at).format('YYYY-MM-DD HH:mm'))
                      .fontColor('#d9999999')
                      .fontSize(12)
                  }
                  .padding(12)
                  .alignItems(HorizontalAlign.Start)
                }
                .margin({ left: 12, right: 12 })
                .backgroundColor(Color.White)
                .borderRadius(4)
              }
              .onClick(() => this.pageInfos.pushPath({
                name: 'editCourseNotice', param: JSON.stringify(item), onPop: async () => {
                  this.notices = []
                  this.pageNum = 1
                  await this.getData()
                }
              }))
            })
          }
          .onReachEnd(async () => {
            await this.getData()
          })

          if (this.notices.length === 0) {
            Column() {
              Text('暂无数据')
                .fontColor('#999999')
            }
            .flexGrow(1)
            .justifyContent(FlexAlign.Center)
            .width(this.screenWidth)
          }
        }
      }
      .onRefreshing(async () => {
        this.notices = []
        this.pageNum = 1
        await this.getData()
        setTimeout(() => {
          this.isRefreshing = false
        }, 500)
      })
    }
    .title(CustomNavTitle(`课程公告（${this.total_num}）`, () => this.BuildNavRightBtn()))
    .backgroundColor('#f1f1f1')
  }
}

@Builder
export function CourseNoticeBuilder() {
  CourseNotice()
}