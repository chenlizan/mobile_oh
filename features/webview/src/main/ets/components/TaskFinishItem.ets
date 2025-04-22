import _ from "@wolfx/lodash"
import dayjs from "dayjs"
import {
  Api_Context,
  AlertDialogParam,
  CustomAlertDialog,
  CustomToast,
  getTimeState,
  HomeApi,
  judgeGroupIsEnd,
  PreferenceStorage,
  xyApiGet,
  CustomModalDialog,
  xyApiPost
} from "@xy/basic"

@Component
export struct TaskFinishItem {
  private preOffsetX: number = 0
  private preOffsetY: number = 0
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @StorageLink('PreferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage()
  @Prop imgOffSetX: number = 0
  @Prop imgOffSetY: number = 0
  @Prop isSub: boolean = false
  @Prop item: Record<string, string | number> = {}
  @Prop isAutocomplete: boolean = false
  @Prop watchLimit: boolean = false
  @Prop media_id: string = ''
  @State finish: boolean = false
  @State is_latest: boolean = false
  @State assign_id: string = ''
  @State watchRemindVisible: boolean = false
  @State meet_watch: boolean = false
  @State meet_watch_time: number = 0
  @State interval: number = 0

  async queryStudentFinishInfo() {
    const response = await xyApiGet(this.Api_Context.getApiPrefix('baseApi_inner') + HomeApi.queryStudentFinishInfo,
      { 'node_id': this.item.node_id, 'group_id': this.item.group_id })
    if (response.success) {
      const res = response.data as Record<string, string | boolean>
      this.finish = res.finished as boolean
      this.is_latest = (res?.finish_time && dayjs(res.finish_time as string).isAfter(this.item.end_time)) as boolean
      this.assign_id = res.assign_id as string
    }
    if (this.watchLimit) {
      const watch_time = (this.item.watch_min_minutes ?? 0) as number * 60
      if (watch_time) {
        this.interval = setInterval(() => {
          if (this.meet_watch_time + 1 === watch_time) {
            this.meet_watch_time = 0
            this.meet_watch = true
          } else {
            this.meet_watch_time = this.meet_watch_time + 1
          }
        }, 1000)
      } else {
        this.meet_watch = true
      }
    } else {
      this.meet_watch = true
    }
  }

  aboutToAppear(): void {
    this.queryStudentFinishInfo()
  }

  aboutToDisappear(): void {
    if (this.interval) {
      clearInterval(this.interval)
    }
  }

  handleFinishTask() {
    const currentTeam = this.preferenceStorage.currentTeam
    if (!_.isEmpty(currentTeam) && judgeGroupIsEnd(currentTeam as Record<string, string>)) {
      return
    }
    if (this.finish) {
      CustomToast.toast_info('任务已完成')
      return
    }
    if (getTimeState(this.item, 'cn') === '未开始') {
      CustomToast.toast_fail('任务还未开始')
      return
    }
    if (getTimeState(this.item, 'cn') === '已截止') {
      if (this.item.is_allow_after_submitted) {
        CustomAlertDialog({
          title: '提示',
          message: '任务已截止。本次任务允许截止后补交，是否补交？',
          onClickBtn: () => {
            this.toFinishTask()
          }
        } as AlertDialogParam)
      }
    } else {
      this.toFinishTask()
    }
  }

  toFinishTask = () => {
    if (!this.meet_watch) {
      this.watchRemindVisible = true
      return
    }
    if (this.isAutocomplete) {
      this.onAutoFinishTask()
    } else {
      this.onFinishTask()
    }
  }

  async onAutoFinishTask() {
    if (_.isEmpty(this.media_id)) {
      const response = await xyApiPost(this.Api_Context.getApiPrefix('baseApi_inner') + HomeApi.checkVodTaskStatus, {
        'group_id': this.item.group_id,
        'task_id': this.item.task_id,
        'assign_id': this.assign_id,
        'media_id': this.media_id
      })
      if (response.success) {
        this.finish = true
        this.is_latest = dayjs().isAfter(this.item.end_time)
        CustomToast.toast_success('任务已完成')
      }
    }
  }

  async onFinishTask() {
    const response = await xyApiPost(this.Api_Context.getApiPrefix('baseApi_inner') + HomeApi.finishActivity, {
      'group_id': this.item.group_id,
      'task_id': this.item.task_id,
      'node_id': this.item.id,
    })
    if (response.success) {
      this.finish = true
      this.is_latest = dayjs().isAfter(this.item.end_time)
      CustomToast.toast_success(getAutocompleteTaskStatus((response.data as Record<string, number>).status,
        this.item.type as number))
    }
  }

  build() {
    Column() {
      Text(this.finish ? '已完成\n（补交）' : '点我\n完成任务')
        .width(40)
        .height(40)
        .borderRadius(20)
        .fontSize(8)
        .fontColor(Color.White)
        .textAlign(TextAlign.Center)
        .backgroundColor(this.finish ? '#1EB38F' : '#FCBB34')
        .shadow(ShadowStyle.OUTER_DEFAULT_SM)
      WatchRemindModal({
        visible: $watchRemindVisible,
        time: this.meet_watch_time,
        min_minutes: this.item?.watch_min_minutes as number ?? 0
      })
    }
    .borderRadius(20)
    .position({ x: this.imgOffSetX, y: this.imgOffSetY })
    .gesture(
      PanGesture()
        .onActionStart(() => {
          this.preOffsetX = this.imgOffSetX
          this.preOffsetY = this.imgOffSetY
        })
        .onActionUpdate((event?: GestureEvent) => {
          if (event) {
            this.imgOffSetX = this.preOffsetX + event.offsetX
            this.imgOffSetY = this.preOffsetY + event.offsetY
          }
        }))
    .onClick(() => this.handleFinishTask())
  }
}

@Component
struct WatchRemindModal {
  @Link visible: boolean
  @Prop time: number = 0
  @Prop min_minutes: number = 0
  @State title: string = '提示'

  @Builder
  BuildModalContent() {
    Column() {
      Text(`已学习${transTimeHms(this.time)}，连续观看时间未达要求，至少观看${this.min_minutes}分钟`)
        .padding(16)
      Text('*刷新或离开页面将会重置任务计时')
        .fontColor('#FF4040')
        .fontSize(12)
    }
  }

  @Builder
  BuildModalFooter() {
    Row() {
      Text('知道了')
        .padding(10)
        .fontColor('#40A9FF')
        .onClick(() => {
          this.visible = false
        })
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .borderWidth({ top: 1 })
    .borderColor('#33999999')
  }

  build() {
    CustomModalDialog({
      visible: $visible,
      title: this.title,
      dialogHeight: 300,
      contentBuilder: () => this.BuildModalContent(),
      footerBuilder: () => this.BuildModalFooter()
    })
  }
}

const transTimeHms = (time: number) => {
  // 创建一个基准时间对象（当前时间）
  const baseTime = dayjs()
  // 创建目标时间对象（当前时间 + 输入的秒数）
  const targetTime = baseTime.add(time, 'second')

  // 计算时间差（毫秒）
  const diffMs = targetTime.diff(baseTime)

  // 将毫秒转换为时分秒
  const totalSeconds = Math.floor(diffMs / 1000)
  const hours = Math.floor(totalSeconds / 3600)
  const minutes = Math.floor((totalSeconds % 3600) / 60)
  const seconds = totalSeconds % 60

  let txt = ''

  if (hours >= 1) {
    txt += `${hours}小时`
  }
  if (minutes > 0) {
    txt += `${minutes}分`
  }
  if (seconds > 0 || (txt === '' && seconds === 0)) { // 处理0秒的情况
    txt += `${seconds}秒`
  }

  return txt
}

const getAutocompleteTaskStatus = (status: number, type: number) => {
  switch (status) {
    case 0:
      return '完成任务'
    case 1:
      if (type === 9) {
        return '视频尚未看完，继续观看吧！'
      } else if (type === 8) {
        return '尚未参与本讨论主题的发帖、回帖或点赞，去参与吧！'
      }
      return '未完成任务'
    case 2:
      return '无此任务'
    case 3:
      if (type === 9) {
        return '视频尚未看完，继续观看吧！'
      }
      return '未完成任务'
    default:
      return '未完成任务'
  }
}