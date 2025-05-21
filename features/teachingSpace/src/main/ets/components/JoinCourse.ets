import { url } from "@kit.ArkTS"
import { display } from "@kit.ArkUI"
import { scanBarcode } from "@kit.ScanKit"
import _ from "@wolfx/lodash"
import dayjs from "dayjs"
import {
  Api_Context,
  AppIcon,
  CustomAlertDialog,
  CustomNavTitle,
  CustomToast,
  HomeApi,
  IconConstants,
  UserInfoModel,
  xyApiGet,
  CustomModalDialog,
  xyApiPost
} from "@xy/basic"

interface Option {
  value: string
  class_id: string
}

@Component
struct JoinCourse {
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @StorageLink('UserInfo') userInfo: UserInfoModel = new UserInfoModel()
  @State screenWidth: number = 0
  @State isRefreshing: boolean = false
  @State visible: boolean = false
  @State title: string = '申请设置'
  @State classList: Option[] = []
  @State resultGroup: Record<string, string>[] = []
  private group_id: string = ''
  private join_type: number = 0
  private class_id: string = ''
  private role: number = 1

  aboutToAppear(): void {
    this.screenWidth = px2vp(display.getDefaultDisplaySync().width)
  }

  handleJoinStep(data: Record<string, number | string>, group_id: string) {
    if (data?.filed === 1) {
      CustomToast.toast_fail('课程已归档')
      return
    }
    if (data?.member_staus === 2) {
      CustomToast.toast_fail('你已经是课程成员了~')
      return
    }
    if (data.join_type === 3) {
      CustomToast.toast_fail('禁止加入')
      return
    }
    if (data.lock === 2) {
      CustomToast.toast_fail('课程已锁定')
      return
    }
    if (data.identity_flag === 1 && this.userInfo.isRealStudent) {
      CustomToast.toast_fail('该课程仅允许教师加入')
      return
    }
    if (this.userInfo.isSchoolFellow) {
      CustomToast.toast_fail('校友可以直接访问课程进行学习，不必加入课程')
      return
    }
    if (data?.public_type === '1' && this.userInfo.id !== data?.creator) {
      CustomToast.toast_fail('该课程未公开，无法加入')
      return
    }
    if (data?.end_time) {
      if (dayjs().isAfter(dayjs(data.end_time))) {
        CustomToast.toast_fail('课程已经结课，不允许操作')
        return
      }
    }

    CustomAlertDialog({
      'title': '提示',
      'message': `是否加入课程`,
      onClickBtn: () => {
        xyApiGet(this.Api_Context.getApiPrefix('baseApi_inner') + HomeApi.groupClassList + '/' + group_id)
          .then((response) => {
            this.classList =
              _.map(response.data, (item: Record<string, string>) => {
                return { 'value': item.class_name, class_id: item.class_id } as Option
              })
            this.visible = true
            this.group_id = group_id
            this.class_id = this.classList[0].class_id
            this.join_type = data.join_type as number
          })
      }
    })
  }

  @Builder
  BuildNavRightBtn() {
    AppIcon({
      iconCode: IconConstants.SCAN,
      iconSize: 16,
      onClickBtn: async () => {
        const scanResult = await scanBarcode.startScanForResult(getContext())
        const data = scanResult.originalValue
        if (data.indexOf('joinGroupQrCode') > -1) {
          const urlObject = url.URL.parseURL(scanResult.originalValue)
          const params = new url.URLParams(urlObject.search)
          if (params.get("qrtype") === 'JOIN_GROUP') {
            const response = await xyApiGet(this.Api_Context.getApiPrefix('baseApi_inner') + HomeApi.groupQr +
              `/${params.get("group_id")}`)
            if (response.success) {
              const data = response.data as Record<string, number>
              this.handleJoinStep(data, params.get('group_id') as string)
            }
          }
        }
      }
    })
  }

  @Builder
  BuildModalContent() {
    Column() {
      Row() {
        Text('教学班级')
        Select(this.classList)
          .selected(0)
          .value(this.classList.length > 0 ? this.classList[0].value : '')
          .onSelect((index: number, text?: string | undefined) => {
            const data = _.find(this.classList, { value: text })
            this.class_id = data?.class_id as string
          })
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .width('100%')
      .padding(12)

      Divider()
      Row() {
        Text('课内身份')
        Select([{ value: '学生' }, { value: '助教' }, { value: '教师' }])
          .selected(0)
          .value('学生')
          .onSelect((index: number, text?: string | undefined) => {
            if (text === '学生') {
              this.role = 1
            } else if (text === '助教') {
              this.role = 2
            } else if (text === '教师') {
              this.role = 4
            }
          })
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .width('100%')
      .padding(12)
    }
    .padding({ left: 16, right: 16 })
  }

  @Builder
  BuildModalFooter() {
    Row() {
      Button('取消', { type: ButtonType.Normal })
        .height(40)
        .fontColor('#999999')
        .backgroundColor(Color.White)
        .borderWidth({ top: 1 })
        .borderColor('#33999999')
        .borderRadius({
          topLeft: 0,
          topRight: 0,
          bottomLeft: 8,
          bottomRight: 0
        })
        .flexGrow(1)
        .onClick(() => this.visible = false)
      Button('确定', { type: ButtonType.Normal })
        .height(40)
        .backgroundColor('#40A9FF')
        .borderWidth({ top: 1 })
        .borderColor('#40A9FF')
        .borderRadius({
          topLeft: 0,
          topRight: 0,
          bottomLeft: 0,
          bottomRight: 8
        })
        .flexGrow(1)
        .onClick(async () => {
          if (this.join_type === 2) {
            const response = await xyApiPost(this.Api_Context.getApiPrefix('baseApi_inner') + HomeApi.joinGroupNoVerify,
              {
                'group_id': this.group_id,
                'class_id': this.class_id,
                'role': this.role,
              })
            if (response.success) {
              CustomToast.toast_success('已加入开放群组')
            }
          } else if (this.join_type === 1) {
            const response = await xyApiPost(this.Api_Context.getApiPrefix('baseApi_inner') + HomeApi.joinGroup,
              {
                'group_id': this.group_id,
                'class_id': this.class_id,
                'role': this.role,
              })
            if (response.success) {
              CustomToast.toast_success('加入申请已发送，7天内有效')
            }
            this.visible = false
          }
        })
    }
    .width('100%')
  }

  build() {
    NavDestination() {
      Refresh({ refreshing: $$this.isRefreshing }) {
        Flex({ direction: FlexDirection.Column }) {
          Search({ placeholder: '请输入课程空间编号' })
            .margin({ left: 12, right: 12, bottom: 4 })
            .backgroundColor(Color.White)
            .borderRadius(4)
            .flexShrink(0)
            .onChange(async (value: string) => {
              if (_.isEmpty(value)) {
                this.resultGroup = []
              }
              const response =
                await xyApiGet(this.Api_Context.getApiPrefix('baseApi_inner') + HomeApi.queryGroup, { 'key': value })
              if (response.success) {
                this.resultGroup = (_.isEmpty(response.data) ? [] : [response.data]) as Record<string, string>[]
              }
            })
          Row() {
            Text('*仅搜索校内公开与全网公开的课程')
              .fontColor('#B9B9B9')
              .fontSize(13)
          }
          .justifyContent(FlexAlign.End)
          .width(this.screenWidth - 24)
          .margin({ left: 12, right: 12, top: 12 })

          if (_.isEmpty(this.resultGroup)) {
            Column() {
              Text('暂无数据')
                .fontColor('#999999')
            }
            .flexGrow(1)
            .justifyContent(FlexAlign.Center)
            .width(this.screenWidth)
          } else {
            Column() {
              Flex({ direction: FlexDirection.Row }) {
                if (this.resultGroup[0].course_property === '2') {
                  Text('MOOC')
                    .padding({
                      left: 8,
                      right: 8,
                      top: 4,
                      bottom: 4
                    })
                    .backgroundColor('#EBEDF0')
                    .borderRadius(2)
                    .fontColor('#FCBB34')
                    .fontSize(14)
                }
                Text(this.resultGroup[0].name)
              }

              Flex({ direction: FlexDirection.Row }) {
                Text((() => {
                  const content: string[] = []
                  content.push(!_.trim(this.resultGroup[0].school_name) ? '自由课程（无学校）' :
                  this.resultGroup[0].school_name)
                  if (!!_.trim(this.resultGroup[0].teacher_names)) {
                    content.push(this.resultGroup[0].teacher_names)
                  }
                  return content.join(' | ')
                })())
                  .fontColor('#B9B9B9')
                  .fontSize(13)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .ellipsisMode(EllipsisMode.END)
                  .wordBreak(WordBreak.BREAK_ALL)
              }
              .padding({ top: 10 })

              Flex({ direction: FlexDirection.Row }) {
                Text((() => {
                  switch (this.resultGroup[0].public_type) {
                    case '1':
                      return `私有课程`
                    case '2':
                      return `课内公开`
                    case '3':
                      return `校内公开`
                    case '4':
                      return `全网公开`
                    default:
                      return null
                  }
                })
                ())
                  .textAlign(TextAlign.Center)
                  .padding({
                    left: 8,
                    right: 8,
                    top: 4,
                    bottom: 4
                  })
                  .fontColor('#999999')
                  .fontSize(13)
                  .backgroundColor('#EBEDF0')
                  .borderRadius(2)
                  .borderRadius(4)

                Text((() => {
                  switch (this.resultGroup[0].public_type) {
                    case '1':
                      return '*私有课程仅教师可以查看'
                    case '2':
                      return '*课程内的成员可以查看课程'
                    case '3':
                      return '*校内用户可以查看课程'
                    case '4':
                      return '*课程全网可见'
                    default:
                      return ''
                  }
                })
                ())
                  .textAlign(TextAlign.Center)
                  .padding({
                    left: 8,
                    right: 8,
                    top: 4,
                    bottom: 4
                  })
                  .fontColor('#B9B9B9')
                  .fontSize(13)
              }
              .padding({ top: 10 })

              Row() {
                Row() {
                }
                .height(1)
                .borderWidth({ top: 1 })
                .layoutWeight(1)
                .borderColor('#40A9FF')
                .borderStyle(BorderStyle.Dashed)
              }
              .padding({ top: 10 })

              Flex({ direction: FlexDirection.Row }) {
                Text('课程介绍')
              }
              .padding({ top: 10 })

              Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.Center }) {
                Text(_.trim(this.resultGroup[0].desc) ? _.trim(this.resultGroup[0].desc) : '暂无简介内容')
                  .fontColor('#B9B9B9')
                  .fontSize(13)
              }
              .padding(_.trim(this.resultGroup[0].desc) ? 8 : 25)
            }
            .width(this.screenWidth - 24)
            .margin(12)
            .padding(10)
            .backgroundColor(Color.White)
            .borderRadius(4)
            .onClick(() => {
              this.handleJoinStep(this.resultGroup[0], this.resultGroup[0].id)
            })
          }
        }
      }
      .onRefreshing(() => {
        setTimeout(() => {
          this.isRefreshing = false
        }, 500)
      })

      CustomModalDialog({
        visible: $visible,
        title: this.title,
        hideCloseBtn: Visibility.Hidden,
        contentBuilder: () => this.BuildModalContent(),
        footerBuilder: () => this.BuildModalFooter(),
      })
    }

    .title(CustomNavTitle('加入课程', () => this.BuildNavRightBtn()))
    .backgroundColor("#f1f1f1")
  }
}

@Builder
export function
JoinCourseBuilder() {
  JoinCourse()
}