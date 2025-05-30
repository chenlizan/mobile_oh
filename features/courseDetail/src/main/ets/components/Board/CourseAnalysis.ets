import _ from "@wolfx/lodash"
import dayjs from "dayjs"
import { Api_Context, AppIcon, CustomNavTitle, HomeApi, IconConstants, PreferenceStorage, xyApiGet } from "@xy/basic"

@Component
struct CourseAnalysis {
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @StorageLink('PreferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage()
  @State isRefreshing: boolean = false
  @State sections: Record<string, string | Record<string, string>[]>[] = []
  @State showYear: boolean = false
  private courseInfo = this.preferenceStorage.currentTeam ?? {}

  async queryCourseAnalysisList() {
    const response = await xyApiGet(this.Api_Context.getApiPrefix('statApi') + HomeApi.getCourseAnalysisList + '/' +
    this.courseInfo.id)
    if (response.success) {
      const data = response.data
      if (!_.isEmpty(data)) {
        const sections = _.map(data as Record<string, Record<string, string>>, (item) => {
          item.date = dayjs(item.begin_time).format('YYYY/MM月/DD日')
          return item
        })
        const groups = _.groupBy(
          _.orderBy(sections, ['begin_time'], ['desc']),
          'date',
        )
        const keys = _.keys(groups)
        const _keys = _.map(keys, key => (key?.split('/') ?? [])[0])
        this.sections = _.map(keys, key => {
          return {
            'title': key,
            'data': _.orderBy(groups[key], ['begin_time'], ['asc']),
          } as Record<string, string | Record<string, string>[]>
        })
        this.showYear = Array.from(new Set(_keys)).length > 1
      }
    }
  }

  aboutToAppear(): void {
    this.queryCourseAnalysisList()
  }

  build() {
    NavDestination() {
      Refresh({ refreshing: $$this.isRefreshing }) {
        Flex({ direction: FlexDirection.Column }) {
          List() {
            ForEach(this.sections, (group: Record<string, string | Record<string, string>[]>) => {
              ListItem() {
                Column() {
                  Row() {
                    Column()
                      .height(20)
                      .border({ color: '#40A9FF', width: { left: 2 } })
                    Text((() => {
                      const parts = (group.title as string)?.split('/');
                      return parts[1] + '/' + parts[2]
                    })())
                      .margin({ left: 8 })
                      .fontColor('#999999')
                      .fontSize(13)
                  }
                  .width('100%')

                  ForEach((group.data as Record<string, string>[]), (item: Record<string, string>, index: number) => {
                    Row() {
                      Column() {
                        Column()
                          .border({ color: '#d9d9d9', width: { left: 1.2 } })
                          .layoutWeight(1)
                          .visibility(index === 0 ? Visibility.Hidden : Visibility.Visible)
                        Column()
                          .width(10)
                          .height(10)
                          .margin({ left: 2 })
                          .border({ color: '#FCBB34', width: 2 })
                          .borderRadius(10)
                        Column()
                          .border({ color: '#d9d9d9', width: { left: 1.2 } })
                          .layoutWeight(1)
                          .visibility(group.data.length === index + 1 ? Visibility.Hidden : Visibility.Visible)
                      }
                      .flexShrink(0)
                      .width(30)
                      .height(74)

                      Row() {
                        Text(`${dayjs(item.begin_time).format('HH:mm')} — ${dayjs(item.end_time).format('HH:mm')}`)
                          .fontColor('#40A9FF')
                          .fontSize(14)
                        AppIcon({
                          iconCode: IconConstants.RIGHT,
                          iconBackgroundColor: '#40A9FF',
                          iconColor: Color.White,
                          iconSize: 8,
                          iconRadius: 18,
                          iconPadding: 5
                        })
                      }
                      .flexGrow(1)
                      .justifyContent(FlexAlign.SpaceBetween)
                      .margin({ top: 12, bottom: 12 })
                      .padding({
                        left: 12,
                        right: 12,
                        top: 16,
                        bottom: 16
                      })
                      .backgroundColor('#BEE2FF')
                      .borderRadius(4)
                    }
                    .width('100%')
                    .onClick(() => {
                      const path =
                        `#/groupAnalysis?document_id=${item.document_id}&group_id=${item.group_id}&client_name=${item.client_name}&end_time=${item.end_time}&begin_time=${item.begin_time}`
                      this.pageInfos?.pushPath({
                        name: 'h5Resource',
                        param: JSON.stringify({
                          hideNav: true,
                          source_url: path,
                        })
                      })
                    })
                  })
                }
              }
              .margin({ left: 12, right: 12 })
            })
          }
        }
        .margin({ left: 12, right: 12 })
      }
      .onRefreshing(() => {
        this.queryCourseAnalysisList()
        setTimeout(() => {
          this.isRefreshing = false
        }, 500)
      })
    }
    .title(CustomNavTitle('课堂实录分析'))
    .backgroundColor('#f1f1f1')
  }
}

@Builder
export function CourseAnalysisBuilder() {
  CourseAnalysis()
}