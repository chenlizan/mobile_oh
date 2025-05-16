import { display } from "@kit.ArkUI"
import dayjs from "dayjs"
import _ from "@wolfx/lodash"
import {
  Api_Context,
  AppIcon,
  CustomAlertDialog,
  CustomDatePickerDialog,
  CustomListItem,
  CustomNavTitle,
  CustomToast,
  HomeApi,
  IconConstants,
  verifyNameIsSpecial,
  xyApiPost
} from "@xy/basic"

@Component
struct CreateDiscuss {
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @State screenWidth: number = 0
  @State textAreaBorderColor1: ResourceColor = '#d9d9d9'
  @State textAreaBorderColor2: ResourceColor = '#d9d9d9'
  @State name: string = ''
  @State description: string = ''
  @State startTime: Date = dayjs().toDate()
  @State startTimeVisible: boolean = false
  @State startTimeTitle: string = '开始时间'
  @State endTime: Date = dayjs().add(6, 'day').toDate()
  @State endTimeVisible: boolean = false
  @State endTimeTitle: string = '截止时间'
  @State anonymous_mode: boolean = false
  private param: Record<string, string | boolean | Record<string, boolean>> = {}

  aboutToAppear(): void {
    this.screenWidth = px2vp(display.getDefaultDisplaySync().width)
    this.param = JSON.parse(String(this.pageInfos.getParamByName('createDiscuss')[0]))
  }

  @Builder
  BuildStartTimeItem() {
    Row() {
      Text(this.startTime ? dayjs(this.startTime).format('YYYY-MM-DD HH:mm') : '')
        .margin({ right: 8 })
        .fontColor('#999999')
        .fontSize(14)
      AppIcon({ iconCode: IconConstants.RIGHT })
    }
  }

  @Builder
  BuildEndTimeItem() {
    Row() {
      Text(this.endTime ? dayjs(this.endTime).format('YYYY-MM-DD HH:mm') : '')
        .margin({ right: 8 })
        .fontColor('#999999')
        .fontSize(14)
      AppIcon({ iconCode: IconConstants.RIGHT })
    }
  }

  build() {
    NavDestination() {
      Column() {
        Text() {
          Span('*').fontColor(Color.Red)
          Span('讨论主题(必填)')
        }
        .padding(12)

        TextArea({ placeholder: '请输入讨论主题' })
          .height(75)
          .margin({ left: 16, right: 16 })
          .backgroundColor(Color.White)
          .borderColor(this.textAreaBorderColor1)
          .borderRadius(4)
          .borderWidth(1)
          .placeholderColor('#999999')
          .maxLength(255)
          .onFocus(() => {
            this.textAreaBorderColor1 = '#40A9FF'
          })
          .onBlur(() => {
            this.textAreaBorderColor1 = '#d9d9d9'
          })
          .onChange((value: string) => {
            this.name = value
          })
        Divider()
          .margin({ top: 16, bottom: 16 })
          .color('#33999999')
          .strokeWidth(1)
        Text('讨论描述')
          .padding(12)
        TextArea({ placeholder: '请输入讨论描述' })
          .height(125)
          .margin({ left: 16, right: 16 })
          .backgroundColor(Color.White)
          .borderColor(this.textAreaBorderColor2)
          .borderRadius(4)
          .borderWidth(1)
          .placeholderColor('#999999')
          .maxLength(255)
          .onFocus(() => {
            this.textAreaBorderColor2 = '#40A9FF'
          })
          .onBlur(() => {
            this.textAreaBorderColor2 = '#d9d9d9'
          })
          .onChange((value: string) => {
            this.description = value
          })
        Divider()
          .margin({ top: 16, bottom: 16 })
          .color('#33999999')
          .strokeWidth(1)
        if (this.param.isSubGroup) {
          CustomListItem({
            itemBorder: {},
            text: this.startTimeTitle,
            operateBuilder: () => this.BuildStartTimeItem(),
            onClickBtn: () => this.startTimeVisible = true
          })
          CustomListItem({
            text: this.endTimeTitle,
            operateBuilder: () => this.BuildEndTimeItem(),
            onClickBtn: () => this.endTimeVisible = true
          })
          Divider()
            .margin({ top: 16, bottom: 16 })
            .color('#33999999')
            .strokeWidth(1)
        }
        Column() {
          Row() {
            Text('允许匿名发帖')
            Checkbox()
              .selectedColor('#40A9FF')
              .shape(CheckBoxShape.ROUNDED_SQUARE)
              .onChange((value) => {
                this.anonymous_mode = value
              })
          }
          .justifyContent(FlexAlign.SpaceBetween)
          .width('100%')
          .padding({ left: 16, right: 16 })

          Text('*勾选后允许匿名发帖，否则只能实名参与讨论 ；该设置在讨论创建后不可更改')
            .padding(12)
            .fontColor('#d9999999')
            .fontSize(13)
        }
        .flexGrow(1)
        .justifyContent(FlexAlign.End)
        .width('100%')
      }
      .flexGrow(1)
      .alignItems(HorizontalAlign.Start)
      .width(this.screenWidth - 24)
      .margin({ left: 12, right: 12 })
      .backgroundColor(Color.White)

      Button('确定', { type: ButtonType.Normal })
        .width(this.screenWidth - 24)
        .margin(12)
        .height(40)
        .backgroundColor('#40A9FF')
        .onClick(async () => {
          if (!_.trim(this.name)) {
            CustomToast.toast_info('请输入讨论主题!');
            return;
          }
          if (this.name.length > 255) {
            CustomToast.toast_info('讨论主题不能超过255个字符');
            return;
          }
          if (verifyNameIsSpecial(this.name)) {
            CustomToast.toast_info('讨论主题不能包含特殊字符（* \\ : ? " < > 等）');
            return;
          }
          if (_.trim(this.description).length > 255) {
            CustomToast.toast_info('讨论描述不能超过255个字符');
            return;
          }
          const body: Record<string, string | number | boolean | null | Record<string, string>> = {
            'group_id': this.param.group_id as string,
            'parent_id': this.param.parent_id as string,
            'type': 8,
            'name': this.name,
            'description': this.description,
            'open_anonymous_mode': this.anonymous_mode,
            'resource': {}
          }
          if (this.param.isSubGroup) {
            body['start_time'] = dayjs(this.startTime).toISOString()
            body['end_time'] = dayjs(this.endTime).toISOString()
          }
          const response = await xyApiPost(this.Api_Context.getApiPrefix('baseApi_inner') + (this.param.isSubGroup ?
          HomeApi.addSubgroupResource : HomeApi.addResource), body)
          if (response.success) {
            CustomAlertDialog({
              title: '提示',
              message: `讨论创建成功${(this.param.courseInfo as Record<string, boolean>).is_resource_auto_public ?
                '，已设置学生可见' : ''}。\n需要发布讨论任务，学生才能参与讨论，是否立即去发布任务？`,
              onClickBtn: () => {
                // TODO
                CustomToast.toast_info('发布逻辑没有开发')
                this.pageInfos.pop({ refresh: true })
              },
              onCloseBtn: () => {
                this.pageInfos.pop({ refresh: true })
              }
            })
          }
        })
      Text('注意：在课程中创建的讨论需要发布后学生才可以参与，小组中创建的讨论可直接参与')
        .margin({ left: 12, right: 12 })
        .fontColor('#d9999999')
        .fontSize(13)

      CustomDatePickerDialog({
        visible: $startTimeVisible,
        title: $startTimeTitle,
        onOkBtn: (value: Date) => {
          this.startTime = value
        }
      })

      CustomDatePickerDialog({
        visible: $endTimeVisible,
        title: $endTimeTitle,
        onOkBtn: (value: Date) => {
          this.endTime = value
        }
      })
    }
    .title(CustomNavTitle('创建讨论'))
    .backgroundColor('#f1f1f1')
  }
}

@Builder
export function CreateDiscussBuilder() {
  CreateDiscuss()
}