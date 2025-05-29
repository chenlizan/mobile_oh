import { display } from "@kit.ArkUI"
import _ from "@wolfx/lodash"
import {
  Api_Context,
  AppIcon,
  CustomNavTitle,
  CustomToast,
  HomeApi,
  IconConstants,
  PreferenceStorage,
  transTimeHm,
  xyApiGet
} from "@xy/basic"

@Component
struct StudyTime {
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @StorageLink('PreferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage()
  @State screenWidth: number = 0
  @State isRefreshing: boolean = false
  @State totalTime: number = 0
  @State totalRecord: Record<string, string>[] = []
  @State searchText: string = ''
  @State filterType: number = 5
  private courseInfo = this.preferenceStorage.currentTeam ?? {}
  private param: Record<string, string | boolean | number | Record<string, boolean>> = {}

  async queryResourceLearnTotal() {
    const response = await xyApiGet(this.Api_Context.getApiPrefix('statApi') + HomeApi.queryResourceLearnTotal,
      { 'group_id': this.courseInfo.id, 'resource_id': this.param.id })
    if (response.success) {
      this.totalTime = (response.data as Record<string, number>).duration ?? 0
    }
  }

  async queryResourceEveryStudy() {
    const response = await xyApiGet(this.Api_Context.getApiPrefix('statApi') + HomeApi.queryResourceEveryStudy,
      { 'group_id': this.courseInfo.id, 'resource_id': this.param.id })
    if (response.success) {
      this.totalRecord = response.data as Record<string, string>[]
    }
  }

  getDataSourceByFilter = (searchText: string, filterType: number, dataSource: Record<string, string>[]) => {
    let rows = dataSource

    if (_.trim(searchText)) {
      rows = rows.filter(
        item =>
        item?.nickname?.indexOf(searchText) > -1 ||
          item?.class_name?.indexOf(searchText) > -1 ||
          item?.student_number?.indexOf(searchText) > -1,
      )
    }

    if (filterType === 0) {
      // 按班级正序
      rows = _.orderBy(rows, ['class_name'], ['asc'])
    } else if (filterType === 1) {
      // 按班级倒序
      rows = _.orderBy(rows, ['class_name'], ['desc'])
    } else if (filterType === 2) {
      // 按一卡通号正序
      rows = _.orderBy(rows, ['student_number'], ['asc'])
    } else if (filterType === 3) {
      // 按一卡通号倒序
      rows = _.orderBy(rows, ['student_number'], ['desc'])
    } else if (filterType === 4) {
      // 按学习时长正序
      rows = _.orderBy(rows, ['duration'], ['asc'])
    } else if (filterType === 5) {
      // 按学习时长倒序
      rows = _.orderBy(rows, ['duration'], ['desc'])
    }

    return rows
  }

  aboutToAppear(): void {
    this.screenWidth = px2vp(display.getDefaultDisplaySync().width)
    this.param = JSON.parse(String(this.pageInfos.getParamByName('studyTime')[0]))
    this.queryResourceLearnTotal()
    this.queryResourceEveryStudy()
  }

  build() {
    NavDestination() {
      Refresh({ refreshing: $$this.isRefreshing }) {
        Flex({ direction: FlexDirection.Column }) {
          Column() {
            Row() {
              AppIcon({
                iconCode: IconConstants.INFO,
                iconColor: '#40A9FF',
                iconSize: 20,
                iconMargin: { right: 8 }
              })
              Text(`本资源所有学生的学习时长：${transTimeHm(this.totalTime, 'minutes', '分钟')}`)
                .fontSize(14)
            }
            .width('100%')
            .margin({ left: 8 })

            Row() {
              Row()
                .width(8)
                .height(8)
                .margin({ right: 4 })
                .borderRadius(4)
                .backgroundColor(this.param.public === 2 ? '#1EB38F' : '#FF4040')
              Text(`资源学生${this.param.public === 2 ? '可见' : '不可见'}`)
                .fontColor('#999999')
                .fontSize(14)
            }
            .justifyContent(FlexAlign.End)
            .width('100%')
            .margin({ top: 8, right: 8 })
            .visibility(this.param.type !== 7 ? Visibility.Visible : Visibility.None)
            .onClick(() => {
              CustomToast.toast_info('资源必须发布成任务，或者设置为学生可见，学生才能查看并学习')
            })
          }
          .flexShrink(0)
          .width('100%')
          .padding(12)
          .backgroundColor('#E6F7FF')
          .border({ color: '#C9ECFF', width: 1 })
          .borderRadius(8)

          Row() {
            Text('请注意：学习时长数据为次日更新')
              .fontColor('#999999')
              .fontSize(13)
          }
          .flexShrink(0)
          .justifyContent(FlexAlign.End)
          .width('100%')
          .padding(8)

          Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
            Search({ placeholder: '姓名|一卡通号|班级' })
              .placeholderColor('#999999')
              .placeholderFont({ size: 14 })
              .width((this.screenWidth - 36) / 2)
              .borderRadius(4)
              .onChange((value: string) => {
                this.searchText = value
              })
            Select([
              { value: '按班级正序' },
              { value: '按班级倒序' },
              { value: '按一卡通号正序' },
              { value: '按一卡通号倒序' },
              { value: '按学习时长正序' },
              { value: '按学习时长倒序' }])
              .font({ size: 14 })
              .fontColor('#999999')
              .selected(5)
              .value('按学习时长倒序')
              .width((this.screenWidth - 36) / 2)
              .borderRadius(4)
              .onSelect((index: number) => {
                this.filterType = index
              })
          }
          .flexShrink(0)

          List() {
            ForEach(this.getDataSourceByFilter(this.searchText, this.filterType, this.totalRecord),
              (item: Record<string, string>) => {
                ListItem() {
                  Column() {
                    Row() {
                      Text(item.nickname)
                        .fontSize(13)
                      Text(`${item.student_number ?? ''}`)
                        .fontColor('#999999')
                        .fontSize(13)
                    }
                    .justifyContent(FlexAlign.SpaceBetween)
                    .width('100%')

                    Row() {
                      Text(item.class_name)
                        .fontColor('#999999')
                        .fontSize(13)
                      Text(`学习时长：${transTimeHm(Number(item.duration), 'minutes')}`)
                        .fontColor('#999999')
                        .fontSize(13)
                    }
                    .justifyContent(FlexAlign.SpaceBetween)
                    .width('100%')
                    .margin({ top: 10 })
                  }
                  .padding(12)
                }
              })
          }
          .divider({
            color: '#d9d9d9',
            strokeWidth: 1,
            startMargin: 8,
            endMargin: 8
          })
          .flexGrow(1)
          .margin({ top: 12 })
          .backgroundColor(Color.White)
          .borderRadius(8)
        }
        .height('100%')
        .margin(12)
      }
      .onRefreshing(() => {
        this.queryResourceLearnTotal()
        this.queryResourceEveryStudy()
        setTimeout(() => {
          this.isRefreshing = false
        }, 500)
      })
    }
    .title(CustomNavTitle('资源学习时长'))
    .backgroundColor('#f1f1f1')
  }
}

@Builder
export function StudyTimeBuilder() {
  StudyTime()
}