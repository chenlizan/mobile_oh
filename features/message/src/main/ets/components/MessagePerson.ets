import { display } from "@kit.ArkUI"
import _ from "@wolfx/lodash"
import {
  Api_Context,
  AppIcon,
  CustomAlertDialog,
  AlertDialogParam,
  CustomDivider,
  CustomList,
  CustomListItem,
  CustomNavTitle,
  CustomToast,
  IconConstants,
  MessageApi,
  xyApiGet,
  xyApiPost,
  HomeApi,
  MessageCountModel,
  CustomPopup,
  MessageContentType,
  xyApiPut,
  xyApiDelete,
  getAvatarSource
} from "@xy/basic"
import dayjs from "dayjs"

@Component
struct MessagePerson {
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @StorageLink('messageCount') messageCount: MessageCountModel = new MessageCountModel()
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @State isRefreshing: boolean = false
  @State isLoading: boolean = false
  @State screenWidth: number = 0
  @State screenHeight: number = 0
  @State onlyUnread: boolean = true
  @State last_msg_id: string | null = null
  @State msgData: Record<string, string | number | boolean>[] = []
  onChangeUnread: (check: boolean) => void = (check) => {
    this.onlyUnread = check
    this.onRefresh();
  }
  onDeleteAll: () => void = () => {
    this.handleDeleteAll()
  }
  onReadAll: () => void = () => {
    this.handleReadAll()
  }
  dialogController: CustomDialogController = new CustomDialogController({
    builder: MessageSettingDialog({
      onlyUnread: this.onlyUnread,
      onChangeUnread: this.onChangeUnread,
      onDeleteAll: this.onDeleteAll,
      onReadAll: this.onReadAll
    }),
    alignment: DialogAlignment.Center,
    customStyle: true,
    cancel: () => this.dialogController.close(),
    closeAnimation: { duration: 0 }
  })

  aboutToAppear(): void {
    this.screenWidth = px2vp(display.getDefaultDisplaySync().width)
    this.screenHeight = px2vp(display.getDefaultDisplaySync().height)
    this.onRefresh()

  }

  handleDeleteAll = () => {
    if (_.isEmpty(this.msgData)) {
      CustomToast.toast_info(`暂无个人消息`);
      return;
    }
    this.dialogController.close()

    CustomAlertDialog({
      title: '请确认',
      message: `是否确定删除所有个人消息（最多100条）？删除后将无法恢复`,
      onClickBtn: () => {
        const ids = _.map(this.msgData, msg => msg.id);
        xyApiPost(this.Api_Context.getApiPrefix("baseApi_inner") + MessageApi.delSelectedMsg, {
          "message_ids": ids.slice(0, 100),
        }).then(response => {
          if (response.success) {
            CustomToast.toast_success(`个人消息全部删除成功`);
            this.onRefresh();
          }
        })
      }
    } as AlertDialogParam)
  }
  handleReadAll = () => {
    if (_.isEmpty(this.msgData)) {
      CustomToast.toast_info(`暂无个人消息`);
      return;
    }
    this.dialogController.close()
    CustomAlertDialog({
      title: '请确认',
      message: `是否确定要将所有个人消息（最多100条）标记为已读？`,
      onClickBtn: () => {
        const ids = _.map(this.msgData, msg => msg.id);
        xyApiPost(this.Api_Context.getApiPrefix("baseApi_inner") + MessageApi.updateMsgStatus, {
          "message_ids": ids.slice(0, 100),
          "status": 1,
        }).then(response => {
          if (response.success) {
            CustomToast.toast_success(`个人消息全部已读设置成功`);
            this.onRefresh();
          }
        })
      }
    } as AlertDialogParam)
  }
  onGetCourseData = async () => {
    let body: Record<string, string | number> = { "page_size": 20 };
    if (this.onlyUnread) {
      body.msg_status = 0
    }
    if (this.last_msg_id) {
      body.last_msg_id = this.last_msg_id
    }

    const response = await xyApiGet(this.Api_Context.getApiPrefix("baseApi_inner") + MessageApi.queryPersonalNotices, body)

    if (response.success) {
      const data = response.data as Record<string, string | number | Record<string, string | number>[]>
      const new_data =
        _.map(data?.list as Record<string, string | number>[], (datum: Record<string, string | number>) => {

          const fixedMsg: Record<string, string | number | boolean> = {};

          fixedMsg.group_id = _.get(datum, 'body.msgBody.group.id');
          fixedMsg.msgCode = _.get(datum, 'body.msgCode');
          fixedMsg.id = _.get(datum, 'body.msgId');
          fixedMsg.vernierId = _.get(datum, 'id');

          fixedMsg.operator_id = _.get(datum, 'body.msgBody.operator.id');
          fixedMsg.avatar = this.getCourseAvatarUrl(fixedMsg.operator_id as string);
          fixedMsg.operator_name = _.get(datum, 'body.msgBody.operator.nickname');
          fixedMsg.createAt = _.get(datum, 'createdAt');
          fixedMsg.status = _.get(datum, 'msgStatus[0].status', -1);

          if (fixedMsg.msgCode === MessageContentType.User_Reflect_Reply) {
            const reply_content = _.get(datum, 'body.msgBody.content.reply_content');
            fixedMsg.title = `反馈回复："${_.get(
              datum,
              'body.msgBody.content.feedback_title',
            )}"`;
            fixedMsg.content = `管理员 ${fixedMsg.operator_name} 回复了您的反馈："${reply_content}"`;
          } else if (fixedMsg.msgCode === MessageContentType.Clone_Group_Result) {
            //verify:1 同意  2 拒绝
            const verify = _.get(datum, 'body.msgBody.content.verify');
            const applyCourse = _.get(datum, 'body.msgBody.content.fromGroup.name');
            const avatar = _.get(datum, 'body.msgBody.content.verifier.avatar') as string;
            fixedMsg.avatar = _.trim(avatar)
              ? getAvatarSource(avatar).uri
              : '';
            if (verify === 1) {
              fixedMsg.title = '申请课程克隆成功';
              fixedMsg.content = `您提交的《${applyCourse}》课程克隆申请已通过，系统已经开始进行课程克隆，克隆结果请在"克隆记录"中查看。`;
            } else {
              fixedMsg.title = '申请课程克隆失败';
              fixedMsg.content = `您提交的《${applyCourse}》课程克隆申请被拒绝了，建议线下沟通后重新发起。`;
            }
          } else if (fixedMsg.msgCode === MessageContentType.Review_Group_Result) {
            //apply_status:1 拒绝  2 通过
            const apply_status = _.get(datum, 'body.msgBody.content.apply_status');
            const siteName = _.get(
              datum,
              'body.msgBody.content.be_review_site_name',
              '（未知课程）',
            );
            const level = _.get(datum, 'body.msgBody.content.level');
            fixedMsg.title = `优质课程评审申请${
            apply_status === '2' ? '通过' : '拒绝'
            }`;
            if (apply_status === '2') {
              fixedMsg.content = `您提交的《${siteName}》课程优质课程评审 等级（${level}）等级申请已通过，评审流程与结果可在课程空间"课程管理-优质课程评审"中查看。`;
            } else {
              fixedMsg.content = `您提交的《${siteName}》课程优质课程评审 等级（${level}）等级申请已被拒绝，建议线下沟通后重新发起申请。`;
            }
          } else if (fixedMsg.msgCode === MessageContentType.Be_Friend_Result) {
            fixedMsg.title = '好友申请';
            const status = _.get(datum, 'body.msgBody.content.status');
            if (status === 2) {
              fixedMsg.content = `恭喜！您的好友申请已通过，${fixedMsg.operator_name} 已成为您的好友`;
            } else {
              fixedMsg.content = `很遗憾，${fixedMsg.operator_name} 拒绝了您加好友的申请`;
            }
          } else if (fixedMsg.msgCode === MessageContentType.Merge_Group_Result) {
            //apply_status:1 同意  2 拒绝
            const apply_status = _.get(datum, 'body.msgBody.content.apply_status');
            const beMergeSiteName = _.get(
              datum,
              'body.msgBody.content.be_merge_site_name',
              '（未知课程）',
            );

            if (apply_status === 1) {
              fixedMsg.title = '申请课程合并成功';
              fixedMsg.content = `您提交的《${beMergeSiteName}》课程合并申请已通过，系统已经开始进行课程合并，合并结果请在“合并记录”中查看。`;
            } else {
              fixedMsg.title = '申请课程合并失败';
              fixedMsg.content = `您提交的《${beMergeSiteName}》课程合并申请被拒绝了，建议线下沟通后重新发起。`;
            }
          } else if (fixedMsg.msgCode === MessageContentType.Join_Group_Result) {
            const group_name = _.get(datum, 'body.msgBody.group.name');
            const group_id = _.get(datum, 'body.msgBody.group.id');
            const is_refuse = _.get(datum, 'body.msgBody.content.is_refuse');
            fixedMsg.avatar = `${this.Api_Context.getApiPrefix(
              'baseApi_out',
            )}cloud/group/cover/${group_id}`;
            if (!is_refuse) {
              fixedMsg.title = '申请加入课程成功';
              fixedMsg.content = `你发起的加入《${group_name}》的申请被通过，已经加入该课程。`;
            } else {
              fixedMsg.title = '申请加入课程失败';
              fixedMsg.content = `你发起的加入《${group_name}》的申请被拒绝，建议线下沟通后重新发起申请。`;
            }
          }

          return fixedMsg
        })

      if (this.last_msg_id) {
        this.msgData = [...this.msgData, ...new_data]
      } else {
        this.msgData = new_data
      }

      this.isRefreshing = false
      this.isLoading = false
    }
  }
  getCourseAvatarUrl = (user_id: string) => {
    return `${this.Api_Context.getApiPrefix(
      'baseApi_out',
    )}cloud/file/avatar/${user_id}?random=${dayjs().format('YYYY/MM/DD/HH')}`;
  }
  onRefresh = () => {
    this.last_msg_id = null;
    this.onGetCourseData()
  };
  onEndReached = () => {
    if (_.isEmpty(this.msgData) || this.isLoading) {
      return;
    }
    const notices = this.msgData.sort((a, b) =>
    (b.vernierId as string).localeCompare(a.vernierId as string),
    );
    if (this.last_msg_id !== notices[this.msgData.length - 1].vernierId) {
      this.last_msg_id = notices[this.msgData.length - 1].vernierId as string;
      this.onGetCourseData()
    }
  };
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
  onDeletePress = (item: Record<string, string | number>) => {
    CustomAlertDialog({
      title: '提示',
      message: '是否删除此消息？',
      onClickBtn: () => {
        xyApiDelete(this.Api_Context.getApiPrefix("baseApi_inner") + MessageApi.delMessage + item.id).then(response => {
          if (response.success) {
            CustomToast.toast_success("删除成功");
            this.onRefresh()
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
    this.onRefresh()
  }

  @Builder
  BuildNavRightBtn() {
    AppIcon({
      iconCode: IconConstants.MORE,
      iconSize: 24,
      onClickBtn: () => {
        this.dialogController.open()
      }
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
      Refresh({ refreshing: $$this.isRefreshing }) {
        Column() {
          Flex({ direction: FlexDirection.Column }) {
            if (_.isEmpty(this.msgData)) {
              Text(`暂无${this.onlyUnread ? "未读的" : ""}个人消息`)
                .fontColor('#999')
                .fontSize(15)
                .fontWeight(400)
                .width('100%')
                .textAlign(TextAlign.Center)
                .height(300)
            } else {
              List() {
                ForEach(this.msgData, (item: Record<string, string | number | boolean>, index: number) => {
                  ListItem() {
                    Row() {
                      Badge({
                        count: item.status === 0 ? 1 : 0,
                        position: BadgePosition.RightTop,
                        style: { badgeSize: 8, fontSize: 0 }
                      }) {
                        Image(item.avatar as string)
                          .width(36)
                          .height(36)
                          .borderRadius(36)
                      }.margin({ right: 10 })

                      Column() {
                        Row() {
                          if (item.link_group) {
                            Text(item.title as string)
                              .fontColor('#40A9FF')
                              .fontSize(15)
                              .fontWeight(400)
                              .layoutWeight(1)
                              .textOverflow({ overflow: TextOverflow.Ellipsis })
                              .maxLines(1)
                              .onClick(() => this.onEnterGroup(item.group_id as string))
                          } else {
                            Text(item.title as string)
                              .fontColor(Color.Black)
                              .fontSize(15)
                              .fontWeight(400)
                              .textOverflow({ overflow: TextOverflow.Ellipsis })
                              .maxLines(1)
                              .layoutWeight(1)
                          }
                          Text(dayjs(item.createAt as string).format('MM月DD日 HH:mm'))
                            .fontColor('#999')
                            .fontSize(13)
                            .margin({ left: 4 })
                            .fontWeight(400)

                          if (!!item.remind && item.status === 0) {
                            CustomPopup({
                              contentBuilder: () => this.BuildPopupContent(),
                              tips: item.remind as string
                            })
                          }
                        }.margin({ bottom: 12 })

                        Row() {
                          Text(item.content as string)
                            .fontColor('#999')
                            .fontSize(13)
                            .fontWeight(400)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                            .maxLines(1)
                            .margin({ right: 4 })
                            .layoutWeight(1)

                          Text('删除')
                            .padding(8)
                            .fontSize(13)
                            .backgroundColor(Color.White)
                            .fontColor('#999999')
                            .borderColor('#F5F5F5')
                            .borderWidth(1)
                            .borderRadius(4)
                            .onClick(() => this.onDeletePress(item as Record<string, string | number>))
                        }
                      }.layoutWeight(1)
                    }.padding(12)
                    .borderWidth({ bottom: 1 })
                    .borderColor({ bottom: '#ebebeb' })
                  }.onClick(() => {
                    this.pageInfos.pushPath({ name: 'messagePersonDetail', param: JSON.stringify(item) })
                  })
                })
              }
              .flexGrow(1)
              .backgroundColor(Color.White)
              .onScrollIndex((start: number, end: number) => {
                // 当达到列表末尾时，触发新数据加载。
                if (end >= this.msgData.length - 1) {
                  this.isLoading = true;
                  this.onEndReached()
                }
              })
              .scrollBar(BarState.Off)
              // 开启边缘滑动效果。
              .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
            }
          }
          .margin({ top: 12 })
          .flexGrow(1)
          .backgroundColor(Color.White)
        }
        .width(this.screenWidth - 24)
        .height('100%')
      }
      .onRefreshing(() => {
        this.onRefresh()
      })
    }
    .title(CustomNavTitle('个人消息', () => this.BuildNavRightBtn()))
    .backgroundColor("#f1f1f1")
  }
}

@CustomDialog
export struct MessageSettingDialog {
  @Prop onlyUnread: boolean = true
  @State screenWidth: number = 0
  @State screenHeight: number = 0
  private controller: CustomDialogController
  onChangeUnread: (check: boolean) => void = () => {
  }
  onDeleteAll: () => void = () => {
  }
  onReadAll: () => void = () => {
  }

  async aboutToAppear() {
    this.screenWidth = px2vp(display.getDefaultDisplaySync().width)
    this.screenHeight = px2vp(display.getDefaultDisplaySync().height)
  }

  @Builder
  BuildOperate() {
    Checkbox()
      .select(this.onlyUnread)
      .selectedColor('#40A9FF')
      .shape(CheckBoxShape.ROUNDED_SQUARE)
      .onChange((value: boolean) => {
        this.onChangeUnread(value)
      })
  }

  build() {
    Column() {
      Text("列表选项")
        .fontColor('#000')
        .fontSize(16)
        .fontWeight('bold')
        .padding({ top: 16, bottom: 12 })
        .width('100%')
        .textAlign(TextAlign.Center)
      Text("仅保留7天内的消息")
        .fontColor('#000')
        .fontSize(15)
        .fontWeight(400)
        .backgroundColor('#F1F1F1')
        .padding({ left: 16 })
        .height(44)
        .width('100%')

      CustomList() {
        CustomListItem({
          text: '仅看未读',
          itemRadius: 8,
          itemBorder: {},
          operateBuilder: () => this.BuildOperate(),
        })
        CustomDivider()
        CustomListItem({
          text: '全部已读',
          itemRadius: 8,
          itemBorder: {},
          onClickBtn: () => {
            this.onReadAll()
          }
        })
        Text("*可将当前栏目内的所有未读消息标记为已读状态（最多100条）")
          .fontColor('#999')
          .fontSize(13)
          .fontWeight(400)
          .margin({ left: 16, right: 16, bottom: 12 })
        CustomDivider()
        CustomListItem({
          text: '全部清空',
          itemRadius: 8,
          itemBorder: {},
          onClickBtn: () => {
            this.onDeleteAll()
          }
        })
      }
    }
    .width(this.screenWidth - 40)
    .borderRadius(8)
    .backgroundColor(Color.White)
  }
}


@Builder
export function MessagePersonBuilder() {
  MessagePerson()
}