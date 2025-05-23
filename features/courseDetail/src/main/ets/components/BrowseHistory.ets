import { display, LengthMetrics } from "@kit.ArkUI"
import _ from "@wolfx/lodash"
import dayjs from "dayjs"
import {
  Api_Context,
  AppIcon,
  CustomNavTitle,
  CustomToast,
  getIconByFileType,
  getResourcePath,
  getTypeByAssignToType,
  getTypeByTaskType,
  HomeApi,
  IconConstants,
  navigateToResourceDetails,
  PreferenceStorage,
  transTimeHm,
  UserInfoModel,
  xyApiGet
} from "@xy/basic"

@Component
struct BrowseHistory {
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @StorageLink('UserInfo') userInfo: UserInfoModel = new UserInfoModel()
  @StorageLink('PreferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage()
  @State screenWidth: number = 0
  @State isRefreshing: boolean = false
  @State selectIndex: number = 0
  @State orderType1: boolean | "asc" | "desc" = 'desc'
  @State orderType2: boolean | "asc" | "desc" = 'desc'
  @State filterType: number = 4
  @State rootResources: Record<string, string | number | boolean> [] = []
  @State subResources: Record<string, string | number | boolean> [] = []
  @State learning_record: Record<string, string>[] = []
  @State resource_durations: Record<string, string>[] = []
  @State resource_total_duration: number = 0
  @State total_duration: number = 0
  @State resource_count: number = 0
  private courseInfo = this.preferenceStorage.currentTeam ?? {}
  private showStudyRecord = this.courseInfo.role === 1 || this.courseInfo.role === 7
  private param: Record<string, string> = {}

  async getResourceRecordHistory() {
    const response = await xyApiGet(this.Api_Context.getApiPrefix('baseApi_inner') + HomeApi.getResourceRecordHistory, {
      'group_id': this.param.id,
    })
    if (response.success) {
      this.learning_record = response?.data as Record<string, string>[]
    }
  }

  async queryStudentResourceStudyLearn() {
    const response = await xyApiGet(this.Api_Context.getApiPrefix('statApi') + HomeApi.queryStudentResourceStudyLearn, {
      'group_id': this.param.id,
    })
    if (response.success) {
      const data = response.data as Record<string, number | Record<string, string>[]>
      this.resource_durations = data.resource_durations as Record<string, string>[]
      this.resource_total_duration = data.resource_total_duration as number
      this.total_duration = data.total_duration as number
      this.resource_count = data.resource_count as number
    }
  }

  async queryVisitorResourceStudyLearn() {
    const response = await xyApiGet(this.Api_Context.getApiPrefix('statApi') + HomeApi.queryVisitorResourceStudyLearn, {
      'group_id': this.param.id,
    })
    if (response.success) {
      const data = response.data as Record<string, number | Record<string, string>[]>
      this.resource_durations = data.resource_durations as Record<string, string>[]
      this.resource_total_duration = data.resource_total_duration as number
      this.total_duration = data.total_duration as number
      this.resource_count = data.resource_count as number
    }
  }

  async queryCourseResources() {
    const response = await xyApiGet(this.Api_Context.getApiPrefix('baseApi_inner') + HomeApi.queryCourseResources, {
      'group_id': this.courseInfo.id,
    })
    if (response.success) {
      const rootSource = _.filter(response.data as Record<string, string>[], res => res.parent_id === '1')[0]
      const resources =
        _.filter(response.data as Record<string, string | number>[], res => res.parent_id !== '1' && res.del !== 2)
      const real_resources = _.orderBy(
        _.map(resources, (item: Record<string, string | number | boolean>) => {
          if (item.task_id) {
            item._formatKey = Number(this.courseInfo.role) === 1 ? 'student' : 'teacher'
            item._isSurveyTask = item.task_type >= 2 && item.task_type <= 6
            item._assignTypeText = getTypeByAssignToType(item.assign_to_type as number, item.finish_type as number)
            item._taskTypeText = getTypeByTaskType(item.task_type as number)
          }
          item._formatKey = Number(this.courseInfo.role) === 1 ? 'student' : 'teacher'
          return item
        }),
        ['sort_position'],
        ['asc']
      )
      this.rootResources = _.filter(
        real_resources,
        res => res.parent_id === rootSource.id,
      )
      this.subResources = _.filter(
        real_resources,
        res => res.parent_id !== rootSource.id,
      )
    }
  }

  handleShowResource(item: Record<string, string>) {
    const resource = _.find(this.rootResources, { id: item.id })
    if (resource) {
      navigateToResourceDetails(resource as Record<string, string | number>, Number(this.courseInfo?.role ?? 1))
    } else {
      const resource = _.find(this.subResources, { id: item.id })
      if (resource) {
        navigateToResourceDetails(resource as Record<string, string | number>, Number(this.courseInfo?.role ?? 1))
      } else {
        CustomToast.toast_info('未找到目标资源，可能文件被已删除或任务被撤销')
      }
    }
  }

  getData() {
    this.queryCourseResources()
    this.getResourceRecordHistory()
    if (this.courseInfo.role === 1) {
      this.queryStudentResourceStudyLearn()
    } else if (this.courseInfo.role === 7) {
      this.queryVisitorResourceStudyLearn()
    }
  }

  aboutToAppear(): void {
    this.screenWidth = px2vp(display.getDefaultDisplaySync().width)
    this.param = JSON.parse(String(this.pageInfos.getParamByName('browseHistory')[0]))
    this.getData()
  }

  build() {
    NavDestination() {
      Refresh({ refreshing: $$this.isRefreshing }) {
        Flex({ direction: FlexDirection.Column }) {
          if (this.showStudyRecord) {
            if (this.total_duration) {
              Flex({ alignItems: ItemAlign.Center }) {
                Text(`${this.userInfo.realname}，你好！\n` +
                  `你已在当前课程学习了${transTimeHm(this.total_duration, 'minutes', '分钟')}。\n` +
                  `在这期间，你一共学习了${this.resource_count}个课件资源，资源学习时长为${transTimeHm(this.resource_total_duration,
                    'minutes', '分钟')}。`)
                  .margin({ left: 12 })
                  .fontColor('#d9999999')
                Image((() => {
                  if (this.total_duration) {
                    if (this.total_duration <= 10 * 60) {
                      return $r('app.media.study_1')
                    } else if (this.total_duration <= 20 * 60) {
                      return $r('app.media.study_2')
                    } else if (this.total_duration <= 50 * 60) {
                      return $r('app.media.study_3')
                    } else {
                      return $r('app.media.study_4')
                    }
                  }
                  return null
                })())
                  .flexShrink(0)
                  .width(64)
                  .height(64)
                  .margin({ right: 12 })
              }

              Flex() {
                Button('学习记录', { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.TEXTUAL })
                  .flexGrow(1)
                  .backgroundColor(this.selectIndex === 0 ? '#40A9FF' : '#f1f1f1')
                  .borderColor(this.selectIndex === 0 ? '' : '#999999')
                  .borderRadius({ topLeft: 20, bottomLeft: 20 })
                  .borderWidth(this.selectIndex === 0 ? 0 : { top: 1, bottom: 1, left: 1 })
                  .fontColor(this.selectIndex === 0 ? Color.White : '#999999')
                  .onClick(() => {
                    this.selectIndex = 0
                  })
                Button('资源时长', { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.TEXTUAL })
                  .flexGrow(1)
                  .backgroundColor(this.selectIndex === 1 ? '#40A9FF' : '#f1f1f1')
                  .borderColor(this.selectIndex === 1 ? '' : '#999999')
                  .borderRadius({ topRight: 20, bottomRight: 20 })
                  .borderWidth(this.selectIndex === 1 ? 0 : { top: 1, bottom: 1, right: 1 })
                  .fontColor(this.selectIndex === 1 ? Color.White : '#999999')
                  .onClick(() => {
                    this.selectIndex = 1
                  })
              }
              .margin(12)
            }
          }

          if (this.selectIndex === 0) {
            Flex({ alignItems: ItemAlign.Center }) {
              AppIcon({
                iconCode: this.orderType1 === 'desc' ? IconConstants.ARROW_DOWN : IconConstants.ARROW_UP,
                iconSize: 16,
                iconColor: '#999999',
                iconPadding: 8,
                onClickBtn: () => {
                  this.orderType1 = this.orderType1 === 'desc' ? 'asc' : 'desc'
                }
              })
              Select([
                { value: '按资源名称排序' },
                { value: '按资源类型排序' },
                { value: '按最近查看时间' },
              ])
                .flexGrow(1)
                .selected(2)
                .value('按最近查看时间')
                .onSelect((index: number) => {
                  switch (index) {
                    case 0:
                      this.filterType = 1
                      break
                    case 1:
                      this.filterType = 3
                      break
                    case 2:
                      this.filterType = 4
                      break
                  }
                })
            }
            .margin({ left: 12, right: 12, bottom: 12 })

            List({ space: 12 }) {
              ForEach((() => {
                let data = this.learning_record
                if (this.filterType === 1) {
                  data = _.orderBy(data, ['name'], [this.orderType1]);
                } else if (this.filterType === 2) {
                  data = _.orderBy(data, [""], [this.orderType1]);
                } else if (this.filterType === 3) {
                  data = _.orderBy(data, ['type'], [this.orderType1]);
                } else if (this.filterType === 4) {
                  data = _.orderBy(data, ['view_time'], [this.orderType1]);
                }
                return data
              })(), (item: Record<string, string>) => {
                ListItem() {
                  Flex({ direction: FlexDirection.Column }) {
                    Row() {
                      AppIcon(getIconByFileType(Number(item.type), item.name, item.mimetype))
                      Text(item.name)
                        .margin({ left: 12 })
                        .fontColor('#40A9FF')
                        .fontSize(14)
                    }
                    .margin(12)

                    Row() {
                      Text(`最近观看时间：${dayjs(item.view_time).format('YYYY-MM-DD HH:mm:ss')}`)
                        .margin({ left: 12 })
                        .fontColor('#d9999999')
                        .fontSize(12)
                    }
                    .width('100%')

                    Row() {
                      Text(`位置：${getResourcePath(item.parent_id, this.rootResources, this.subResources)}`)
                        .fontColor('#d9999999')
                        .fontSize(12)
                    }
                    .margin(12)
                  }
                }
                .margin({ left: 12, right: 12 })
                .backgroundColor(Color.White)
                .borderRadius(4)
                .onClick(() => this.handleShowResource(item))
              })
            }
          }
          if (this.selectIndex === 1) {
            Flex({ justifyContent: FlexAlign.End, alignItems: ItemAlign.Center }) {
              Text('学习时长')
                .fontColor('#40A9FF')
                .fontSize(14)
              AppIcon({
                iconCode: this.orderType2 === 'desc' ? IconConstants.ARROW_DOWN : IconConstants.ARROW_UP,
                iconSize: 16,
                iconColor: '#40A9FF',
                iconPadding: 8,
                onClickBtn: () => {
                  this.orderType2 = this.orderType2 === 'desc' ? 'asc' : 'desc'
                }
              })
            }
            .margin({ left: 12, right: 12, bottom: 8 })

            List({ space: 12 }) {
              ForEach((() => {
                return _.orderBy(this.resource_durations, ['duration'], [this.orderType2])
              })(), (item: Record<string, string>) => {
                ListItem() {
                  Flex({ direction: FlexDirection.Column }) {
                    Flex({ justifyContent: FlexAlign.SpaceBetween }) {
                      Row() {
                        AppIcon(getIconByFileType(Number(item.type), item.name, item.mimetype))
                        Text(item.name)
                          .margin({ left: 12 })
                          .fontColor('#40A9FF')
                          .fontSize(14)
                      }

                      Text(`${transTimeHm(Number(item.duration ?? 0), 'minutes', '分钟')}`)
                        .fontColor('#d9999999')
                        .fontSize(12)
                    }
                    .margin(12)

                    Row() {
                      Text(`资源位置：${item.path ?? ''}`)
                        .fontColor('#d9999999')
                        .fontSize(12)
                    }
                    .margin({ left: 12, right: 12, bottom: 12 })
                  }
                }
                .margin({ left: 12, right: 12 })
                .backgroundColor(Color.White)
                .borderRadius(4)
                .onClick(() => this.handleShowResource(item))
              })
            }
          }
        }
      }
      .onRefreshing(() => {
        this.getData()
        setTimeout(() => {
          this.isRefreshing = false
        }, 500)
      })
    }
    .title(CustomNavTitle(this.showStudyRecord ? `【${this.courseInfo.name}】学习记录` : '查看记录'))
    .backgroundColor('#f1f1f1')
  }
}

@Builder
export function BrowseHistoryBuilder() {
  BrowseHistory()
}