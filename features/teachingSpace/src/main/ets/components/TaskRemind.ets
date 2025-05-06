import { display } from "@kit.ArkUI"
import _ from "@wolfx/lodash"
import dayjs from "dayjs"
import {
  Api_Context,
  AppIcon,
  CustomDatePickerDialog,
  CustomList,
  CustomListItem,
  CustomNavTitle,
  CustomTag,
  CustomToast,
  getTypeByAssignToType,
  getTypeByTaskType,
  HomeApi,
  IconConstants,
  navigateToResourceDetails,
  UserInfoModel,
  xyApiGet
} from "@xy/basic"

@Component
struct TaskRemind {
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @StorageLink('UserInfo') userInfo: UserInfoModel = new UserInfoModel()
  @State isRefreshing: boolean = false
  @State screenWidth: number = 0
  @State screenHeight: number = 0
  @State fontColor: string = '#182431'
  @State selectedFontColor: string = '#40A9FF'
  @State currentIndex: number = 0
  @State title: string = '任务截止时间'
  @State datePickerVisible: boolean = false
  @State wait_check: Record<string, number>[] = []
  @State wait_finish: Record<string, number>[] = []
  @State wait_mark: Record<string, number>[] = []
  @State targetDate: Date | null = null
  @State onlyCanFinish: boolean = true
  @State sections: Record<string, string | number>[] = []

  async aboutToAppear(): Promise<void> {
    this.screenWidth = px2vp(display.getDefaultDisplaySync().width)
    this.screenHeight = px2vp(display.getDefaultDisplaySync().height)
    this.handleRefresh()
  }

  async handleRefresh() {
    await this.getUnDealTasks()
    this.sections = this.getSections()
    setTimeout(() => {
      this.isRefreshing = false
    }, 500)
  }

  async handleEnterTask(item: Record<string, string | number>) {
    const response = await xyApiGet(this.Api_Context.getApiPrefix('baseApi_inner') + HomeApi.classResourceInfo,
      { 'node_id': item.node_id })
    if (response.success) {
      item.published = 1
      if (_.isString(response.data)) {
        item.task_id = item.id;
        item.url = response.data;
        item.id = item.node_id;
      } else {
        item.task_id = item.id;
        item.paper_id = item.quote_id;
        item.id = item.node_id;
        item.type = (response.data as Record<string, string>)?.type || item.type;
      }
      navigateToResourceDetails(item, item?.task_role as number ?? 1)
    }
  }

  async getUnDealTasks() {
    let unCheck: Record<string, number>[] = []
    let unFinish: Record<string, number>[] = []
    let unFinishMark: Record<string, number>[] = []

    if (!this.userInfo.isRealStudent) {
      const response = await xyApiGet(this.Api_Context.getApiPrefix('statApi') + HomeApi.taskUnCheck)
      if (response.success) {
        unCheck = _.orderBy(
          _.filter(response.data as Record<string, number>[],
            task => task.task_type !== 5 && task.mark_mode !== 3 && task.mark_mode !== 4), ['end_time'], ['desc'])
      }
    }
    if (this.userInfo.hasStudent) {
      const response = await xyApiGet(this.Api_Context.getApiPrefix('statApi') + HomeApi.taskUnFinishMark)
      if (response.success) {
        unFinishMark = _.orderBy(response.data, ['mark_end_time'], ['desc'])
      }
    }
    const response = await xyApiGet(this.Api_Context.getApiPrefix('statApi') + HomeApi.taskUnFinish)
    if (response.success) {
      unFinish = _.orderBy(response.data, ['end_time'], ['desc'])
    }

    unCheck = _.map(unCheck, item => {
      item.task_role = 4
      return item
    })
    unFinish = _.map(unFinish, item => {
      item.task_role = 1
      return item
    })
    unFinishMark = _.map(unFinishMark, item => {
      item.task_role = 1
      return item
    })

    this.wait_check = _.filter(unCheck, item => {
      return dayjs(item.end_time).isBefore(dayjs())
    })
    this.wait_finish = _.filter(unFinish, item => {
      return dayjs(item.start_time).isBefore(dayjs())
    })
    this.wait_mark = _.filter(unFinishMark, item => {
      return dayjs(item.mark_end_time).isAfter(dayjs())
    })
  }

  getOnlyFinishData() {
    return _.filter(
      this.wait_finish ?? [],
      task =>
      dayjs(task.end_time).isAfter(dayjs()) ||
      task.is_allow_after_submitted,
    )
  }

  getFinishData() {
    let data = this.wait_finish
    if (this.onlyCanFinish) {
      data = this.getOnlyFinishData() as never
    }
    return _.filter(data, task => !this.targetDate || dayjs(task.end_time).isBefore(this.targetDate))
  }

  getCheckData() {
    return _.filter(
      this.wait_check,
      task => !this.targetDate || dayjs(task.end_time).isBefore(this.targetDate),
    )
  }

  getMarkData() {
    const rows = _.filter(
      this.wait_mark,
      task => !this.targetDate || dayjs(task.mark_end_time).isBefore(this.targetDate),
    )
    return _.orderBy(rows, ['mark_end_time'], ['asc'])
  }

  getSections() {
    const sections: Record<string, string | number>[] = []

    const finishes = this.getFinishData()
    if (!this.userInfo.isRealStudent) {
      const checks = this.getCheckData()
      if (!_.isEmpty(checks)) {
        sections.push({
          'title': `批阅提醒（${checks.length}）`,
          'type': 'check',
          'count': checks.length,
        })
      }
    }
    sections.push({
      'title': `学习任务（${finishes.length}）`,
      'type': 'exam',
      'count': finishes.length,
    })
    if (this.userInfo.hasStudent) {
      const marks = this.getMarkData()
      if (!_.isEmpty(marks)) {
        sections.push({
          'title': `自评/互评任务（${marks.length}）`,
          'type': 'mark',
          'count': marks.length,
        })
      }
    }

    return sections
  }

  getClassInfo() {
    let classInfo: Record<string, string | number>[] = []
    if (!this.userInfo.isRealStudent) {
      classInfo.push({
        'content': this.wait_check.length,
        'title': '待批阅任务',
      })
    }
    classInfo.push({
      'content': this.getOnlyFinishData().length,
      'title': '待完成学习任务',
    })
    if (this.userInfo.hasStudent) {
      classInfo.push({
        'content': this.wait_mark.length,
        'title': '待完成自评/互评任务',
      })
    }
    return classInfo
  }

  getListData(sections: Record<string, string | number>[]): Record<string, number>[] {
    if (_.isEmpty(sections)) {
      return []
    }
    if (sections[this.currentIndex]?.type === 'exam') {
      return this.getFinishData()
    } else if (sections[this.currentIndex]?.type === 'mark') {
      return this.getMarkData()
    }
    return this.getCheckData()
  }

  @Builder
  BuildNavRightBtn() {
    AppIcon({
      iconCode: IconConstants.INFO,
      iconColor: '#999999',
      iconSize: 16,
      onClickBtn: () => {
        CustomToast.toast_info('待批阅任务仅统计SPOC课程，MOOC课程任务暂未参与待批阅统计')
      }
    })
  }

  @Builder
  BuildChooseTime() {
    Row() {
      Text(this.targetDate ? dayjs(this.targetDate).format('YYYY-MM-DD') : '请选择时间')
        .margin({ right: 8 })
        .fontColor(this.targetDate ? '#40A9FF' : '#999999')
      AppIcon({ iconCode: IconConstants.RIGHT })
    }
  }

  @Builder
  BuildTabBar(index: number, name: string) {
    Column() {
      Text(name)
        .fontColor(this.currentIndex === index ? this.selectedFontColor : this.fontColor)
        .fontSize(16)
        .fontWeight(this.currentIndex === index ? 500 : 400)
        .lineHeight(22)
        .margin({ top: 10, bottom: 10 })
      Divider()
        .width('80%')
        .strokeWidth(2)
        .color('#40A9FF')
        .opacity(this.currentIndex === index ? 1 : 0)
    }.width('100%')
  }

  build() {
    NavDestination() {
      Refresh({ refreshing: $$this.isRefreshing }) {
        Column() {
          Row() {
            ForEach(this.getClassInfo(), (item: Record<string, string>) => {
              Column() {
                Text(String(item.content))
                  .fontColor('#ff931e')
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                Text(item.title)
                  .margin({ top: 8 })
                  .fontColor('#a8a8a8')
                  .fontSize(14)
              }
              .padding(16)
            })
          }
          .width(this.screenWidth - 24)
          .margin({ left: 12, right: 12 })
          .justifyContent(FlexAlign.SpaceEvenly)
          .backgroundColor(Color.White)
          .borderRadius(4)

          CustomList({ listPadding: 12 }) {
            CustomListItem({
              text: '截止时间早于:',
              operateBuilder: () => this.BuildChooseTime(),
              fontColor: this.targetDate ? '#40A9FF' : '#333333',
              itemBorder: {},
              itemRadius: 4,
              onClickBtn: () => {
                this.datePickerVisible = true
              }
            })
          }

          Tabs({ barPosition: BarPosition.Start }) {
            ForEach(this.sections, (item: Record<string, string | number>, index: number) => {
              TabContent() {
                Column() {
                  if (this.sections[this.currentIndex]?.type === 'exam') {
                    Row() {
                      Checkbox({})
                        .margin({ left: 12 })
                        .shape(CheckBoxShape.ROUNDED_SQUARE)
                        .select($$this.onlyCanFinish)
                        .selectedColor('#40A9FF')
                      Text('仅显示可完成任务')
                        .fontColor('#40A9FF')
                        .fontSize(14)
                    }
                    .width('100%')
                    .justifyContent(FlexAlign.Start)
                  }

                  List() {
                    ForEach(this.getListData(this.sections), (item: Record<string, string | number>) => {
                      ListItem() {
                        Column() {
                          Row() {
                            Text(item.name as string)
                            AppIcon({ iconCode: IconConstants.RIGHT, iconColor: '#a8a8a8' })
                          }
                          .width('100%')
                          .justifyContent(FlexAlign.SpaceBetween)

                          Flex() {
                            Row() {
                              Text('来自')
                                .fontColor('#a8a8a8')
                                .fontSize(12)
                                .margin({ right: 4 })
                              Text(item.group_name as string)
                                .fontColor('#666666')
                                .fontSize(12)
                                .width(this.screenWidth / 2.2)
                                .maxLines(1)
                                .textOverflow({ overflow: TextOverflow.Ellipsis })
                                .ellipsisMode(EllipsisMode.END)
                                .wordBreak(WordBreak.BREAK_ALL)
                            }
                            .flexGrow(2)

                            Row() {
                              if (item.mark_mode === 3 || item.mark_mode === 4) {
                                CustomTag({ text: item.mark_mode === 3 ? '自评' : '互评' })
                              } else {
                                CustomTag({
                                  text: getTypeByAssignToType(item.assign_to_type as number,
                                    item.finish_type as number),
                                  tagMargin: { right: 8 }
                                })
                                CustomTag({ text: getTypeByTaskType(item.task_type as number) })
                              }
                            }
                            .justifyContent(FlexAlign.End)
                            .flexGrow(1)
                          }
                          .width('100%')
                          .padding({ top: 8, bottom: 8 })

                          Row() {
                            AppIcon({ iconCode: IconConstants.TIME, iconColor: '#a8a8a8' })
                            Text(`截止时间：${dayjs(item.mark_mode === 3 || item.mark_mode === 4 ? item.mark_end_time :
                            item.end_time).format(
                              'YYYY/MM/DD HH:mm',
                            )}`)
                              .margin({ left: 4 })
                              .fontColor('#a8a8a8')
                              .fontSize(12)
                            if (item.mark_mode === 3 || item.mark_mode === 4) {
                              Text(`任务进度：${item.finished_count}/${item.distribute_count}`)
                                .fontColor('#a8a8a8')
                                .fontSize(12)
                            }
                          }
                          .width('100%')
                          .justifyContent(FlexAlign.Start)
                        }
                        .padding(12)
                        .borderWidth({ bottom: 1 })
                        .borderColor({ bottom: '#ebebeb' })
                      }
                      .onClick(() => {
                        this.handleEnterTask(item)
                      })
                    })
                  }
                  .width(this.screenWidth - 24)
                  .height(this.screenHeight - (this.currentIndex === 0 ? 346 : 376))
                }
                .width('100%')
                .height('100%')
              }
              .tabBar(this.BuildTabBar(index, item.title as string))
            })
          }
          .barMode(this.sections.length > 2 ? BarMode.Scrollable : BarMode.Fixed)
          .width(this.screenWidth - 24)
          .height(this.screenHeight - 290)
          .backgroundColor(Color.White)
          .borderRadius(4)
          .onChange((index: number) => {
            this.currentIndex = index
          })

          CustomDatePickerDialog({
            visible: $datePickerVisible,
            title: this.title,
            onOkBtn: (value: Date) => {
              this.targetDate = value
              this.handleRefresh()
            }
          })
        }
      }
      .onRefreshing(() => {
        this.handleRefresh()
      })
    }
    .title(CustomNavTitle('任务提醒', () => this.BuildNavRightBtn()))
    .backgroundColor("#f1f1f1")
  }
}

@Builder
export function TaskRemindBuilder() {
  TaskRemind()
}