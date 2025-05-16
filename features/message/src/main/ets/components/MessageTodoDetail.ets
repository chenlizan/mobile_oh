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
  xyApiPost,
} from "@xy/basic"
import dayjs from "dayjs"

@Component
struct MessageTodoDetail {
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
  // 待办 同意操作
  onAcceptPress = async (verify: number) => {
    if (this.param.msgCode === MessageContentType.Apply_Clone_Group) {
      // 克隆申请
      const response = await xyApiPost(this.Api_Context.getApiPrefix("baseApi_inner") + MessageApi.verifyCloneSite, {
        "applay_id": this.param?.applay_id,
        "verify": verify,
        "apply_user_id": this.param.apply_user_id,
        "apply_user_nickname": this.param.apply_user_nickname,
      })
      if (response?.success) {
        if (verify === 1) {
          this.onUpdateMsgStatus(this.param.id as string, 2)
          CustomToast.toast_success('已同意该邀请');
        } else if (verify === 2) {
          this.onUpdateMsgStatus(this.param.id as string, 3)
          CustomToast.toast_success('已拒绝该申请');
        }
      }
    } else if (this.param.msgCode === MessageContentType.Invite_To_Group) {
      if (verify === 2) {
        this.onSelectClass(this.param, verify, '');
      } else {
        // 判断身份，学生需要选择班级，教师无需
        if (this.param.be_join_role === 1) {
        } else {
          this.onSelectClass(this.param, verify, '');
        }
      }
    } else if (this.param.msgCode === MessageContentType.Apply_Be_Friend) {
      // 好友邀请
      const response = await xyApiPost(this.Api_Context.getApiPrefix("baseApi_inner") + MessageApi.verifyFriend, {
        "friend_id": this.param?.operator_id,
        "status": verify === 1 ? 2 : 3,
      })
      if (response?.success) {
        if (verify === 1) {
          this.onUpdateMsgStatus(this.param.id as string, 2)
          CustomToast.toast_success('已同意该邀请');
        } else if (verify === 2) {
          this.onUpdateMsgStatus(this.param.id as string, 3)
          CustomToast.toast_success('已拒绝该申请');
        }
      }
    } else if (this.param.msgCode === MessageContentType.Apply_Merge_Group) {
      // 课程合并
      const response = await xyApiPost(this.Api_Context.getApiPrefix("ccApi") + MessageApi.mergeSiteVerify, {
        "siteId": this.param?.mainSiteId,
        "applyStatus": verify,
        "mergeSiteId": this.param?.beMergedSiteId,
      })
      if (response.code === 200) {
        if (verify === 1) {
          this.onUpdateMsgStatus(this.param.id as string, 2)
          CustomToast.toast_success('已同意该邀请');
        } else if (verify === 2) {
          this.onUpdateMsgStatus(this.param.id as string, 3)
          CustomToast.toast_success('已拒绝该申请');
        }
      }
    } else {
      CustomToast.toast_info("移动端暂不支持处理该消息类型");
    }
  };

  // 设置班级、昵称
  onSelectClass = async (data: Record<string, string | number | boolean>, verify: number, class_id: string) => {
    const response = await xyApiPost(this.Api_Context.getApiPrefix("baseApi_inner") + HomeApi.verifyInvite, {
      "group_id": data.group_id,
      "verify": verify,
      "nickname": this.userInfo.realname,
      "class_id": class_id,
      "role": data.be_join_role,
    })

    if (response.success) {
      if (verify === 1) {
        this.onUpdateMsgStatus(data.id as string, 2)
        CustomToast.toast_success('已同意该邀请');
      } else if (verify === 2) {
        this.onUpdateMsgStatus(data.id as string, 3)
        CustomToast.toast_success('已拒绝该申请');
      }
    }
  };
  onEnterMemberAdd = async () => {
    // 进入课程成员处理页
    const response = await xyApiGet(this.Api_Context.getApiPrefix("baseApi_inner") + HomeApi.queryGroup +
      `/${this.param.group_id}`)

    if (response.success) {
      const group = response.data as Record<string, string | number>
      this.pageInfos.pushPath({
        name: 'courseMemberAdd', param: JSON.stringify({
          group: group,
          fromMessage: true,
          is_all: true,
        })
      });
    }
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

        if (this.param.status === 0) {
          if (this.param.msgCode === MessageContentType.Invite_To_Group ||
            this.param.msgCode === MessageContentType.Apply_Clone_Group ||
            this.param.msgCode === MessageContentType.Apply_Be_Friend ||
            this.param.msgCode === MessageContentType.Apply_Merge_Group) {
            Text('同意')
              .padding(8)
              .fontSize(13)
              .fontColor(Color.White)
              .backgroundColor('#40A9FF')
              .borderRadius(4)
              .margin({ right: 4 })
              .onClick(() => this.onAcceptPress(1))
            Text('拒绝')
              .padding(8)
              .fontSize(13)
              .backgroundColor(Color.White)
              .fontColor('#999999')
              .borderColor('#F5F5F5')
              .borderWidth(1)
              .borderRadius(4)
              .onClick(() => this.onAcceptPress(2))
          }
          if (this.param.msgCode === MessageContentType.Apply_Join_Group) {
            Button('去课程中处理', { type: ButtonType.Normal })
              .fontSize(14)
              .width('100%')
              .fontColor(Color.White)
              .backgroundColor('#40A9FF')
              .onClick(this.onEnterMemberAdd)
          }
        }
      }
      .padding(12)
      .margin({ left: 12, right: 12 })
      .flexGrow(1)
      .backgroundColor(Color.White)
    }
    .title(CustomNavTitle('代办事项详情', () => this.BuildNavRightBtn()))
    .backgroundColor("#f1f1f1")
  }
}

@Builder
export function MessageTodoDetailBuilder() {
  MessageTodoDetail()
}