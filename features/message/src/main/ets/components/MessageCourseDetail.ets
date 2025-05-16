import { display } from "@kit.ArkUI"
import _ from "@wolfx/lodash"
import {
  Api_Context,
  AppIcon,
  CustomAlertDialog,
  AlertDialogParam,
  CustomNavTitle,
  CustomToast,
  IconConstants,
  MessageApi,
  xyApiGet,
  HomeApi,
  xyApiPut,
  xyApiDelete,
  UserInfoModel,
  MessageContentType,
} from "@xy/basic"
import dayjs from "dayjs"

@Component
struct MessageCourseDetail {
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @StorageLink('UserInfo') userInfo: UserInfoModel = new UserInfoModel()
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @State screenWidth: number = 0
  @State screenHeight: number = 0
  @State onlyUnread: boolean = true
  private param: Record<string, string | number> = {}

  aboutToAppear(): void {
    this.screenWidth = px2vp(display.getDefaultDisplaySync().width)
    this.screenHeight = px2vp(display.getDefaultDisplaySync().height)

    this.param = JSON.parse(String(this.pageInfos.getParamByName('messageCourseDetail')[0]))
    if (this.param.status === 0) {
      this.onUpdateMsgStatus(this.param.id as string, 1)
    }
  }

  onEnterGroup = async (group_id: string) => {
    const response = await xyApiGet(this.Api_Context.getApiPrefix("baseApi_inner") + HomeApi.queryGroup +
      `/${group_id}`)

    if (response.success) {
      const group = response.data as Record<string, string | number>
      if (!_.isEmpty(group)) {
        if (group?.spType == 1 || group?.sp_type == 1) {
          // sp
          this.pageInfos.pushPath({
            name: 'courseSpecialReviewDetail', param: JSON.stringify({
              item: group,
              groupSpaceType: 'teach',
            })
          });
        } else {
          if (group.course_property === '2') {
            // mooc
            this.pageInfos.pushPath({
              name: 'courseMoocDetail', param: JSON.stringify({
                item: group,
              })
            });
          } else {
            this.pageInfos.pushPath({
              name: 'courseDetail', param: JSON.stringify({
                item: group,
              })
            });
          }
        }
      }
    }
  }
  onEnterAppraise = () => {
    this.pageInfos.pushPath({
      name: 'courseStudentAppraise', param: JSON.stringify({
        group_id: this.param.group_id,
        fromMessage: true,
        activity_id: this.param.activity_id,
      })
    });
  };
  onDeleteMsg = () => {
    CustomAlertDialog({
      title: '提示',
      message: '是否删除此消息？',
      onClickBtn: () => {
        xyApiDelete(this.Api_Context.getApiPrefix("baseApi_inner") + MessageApi.delMessage + this.param.id)
          .then(response => {
            if (response.success) {
              CustomToast.toast_success("删除成功");
              this.pageInfos.pop()
            }
          })
      }
    } as AlertDialogParam)
  }
  onUpdateMsgStatus = async (message_id: string, status: number) => {
    await xyApiPut(this.Api_Context.getApiPrefix("baseApi_inner") + MessageApi.updateMsgStatus, {
      "message_ids": [message_id],
      "status": status,
    })
  }

  @Builder
  BuildNavRightBtn() {
    Text('删除')
      .fontColor(Color.Red)
      .onClick(() => {
        this.onDeleteMsg()
      })
  }

  @Builder
  BuildPopupContent() {
    AppIcon({
      iconCode: IconConstants.INFO,
      iconSize: 16,
      iconColor: '#999999',
    }).enabled(false)
  }

  build() {
    NavDestination() {
      Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center }) {
        Text(dayjs(this.param?.createAt).format('YYYY-MM-DD HH:mm:ss'))
          .fontSize(13)
          .fontColor('#A9AFB8')
          .backgroundColor('#F1F1F1')

        Column() {
          if (this.param?.link_group) {
            Text(this.param?.title as string)
              .fontColor('#40A9FF')
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .onClick(() => this.onEnterGroup(this.param?.group_id as string))
          } else {
            Text(this.param?.title as string)
              .fontColor(Color.Black)
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
          }
          Text(this.param?.content as string)
            .fontColor('#999')
            .fontSize(13)
            .fontWeight(400)
            .margin({ top: 12 })
        }
        .width('100%')
        .margin(12)
        .padding(12)
        .backgroundColor('#F1F1F1')
        .borderRadius(4)
        .alignItems(HorizontalAlign.Start)

        if (!!this.param?.remind) {
          Text(this.param.remind as string)
            .fontColor('#FF4040')
            .fontSize(13)
            .fontWeight(400)
            .textAlign(TextAlign.Start)
        }
        if (this.param.msgCode === MessageContentType.Publish_Evaluation_Activity) {
          Button('前往评价活动', { type: ButtonType.Normal })
            .fontSize(14)
            .width('100%')
            .fontColor(Color.White)
            .backgroundColor('#40A9FF')
            .onClick(this.onEnterAppraise)
        }
      }
      .padding(12)
      .margin({ left: 12, right: 12 })
      .flexGrow(1)
      .backgroundColor(Color.White)
    }
    .title(CustomNavTitle('课程消息详情', () => this.BuildNavRightBtn()))
    .backgroundColor("#f1f1f1")
  }
}

@Builder
export function MessageCourseDetailBuilder() {
  MessageCourseDetail()
}