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
  CustomPopup,
  MessageContentType,
  xyApiPut,
  xyApiDelete,
  UserInfoModel,
  getMemberRole
} from "@xy/basic"
import dayjs from "dayjs"

@Component
struct MessageSystem {
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @StorageLink('UserInfo') userInfo: UserInfoModel = new UserInfoModel()
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
      CustomToast.toast_info(`暂无系统消息`);
      return;
    }
    this.dialogController.close()

    CustomAlertDialog({
      title: '请确认',
      message: `是否确定删除所有系统消息（最多100条）？删除后将无法恢复`,
      onClickBtn: () => {
        const ids = _.map(this.msgData, msg => msg.id);
        xyApiPost(this.Api_Context.getApiPrefix("baseApi_inner") + MessageApi.delSelectedMsg, {
          "message_ids": ids.slice(0, 100),
        }).then(response => {
          if (response.success) {
            CustomToast.toast_success(`系统消息全部删除成功`);
            this.onRefresh();
          }
        })
      }
    } as AlertDialogParam)
  }
  handleReadAll = () => {
    if (_.isEmpty(this.msgData)) {
      CustomToast.toast_info(`暂无系统消息`);
      return;
    }
    this.dialogController.close()
    CustomAlertDialog({
      title: '请确认',
      message: `是否确定要将所有系统消息（最多100条）标记为已读？`,
      onClickBtn: () => {
        const ids = _.map(this.msgData, msg => msg.id);
        xyApiPost(this.Api_Context.getApiPrefix("baseApi_inner") + MessageApi.updateMsgStatus, {
          "message_ids": ids.slice(0, 100),
          "status": 1,
        }).then(response => {
          if (response.success) {
            CustomToast.toast_success(`系统消息全部已读设置成功`);
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

    const response = await xyApiGet(this.Api_Context.getApiPrefix("baseApi_inner") + MessageApi.querySystemNotices, body)

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
          fixedMsg.operator_name = _.get(datum, 'body.msgBody.operator.nickname');
          fixedMsg.createAt = _.get(datum, 'createdAt');
          fixedMsg.status = _.get(datum, 'msgStatus[0].status', -1);
          fixedMsg.avatar = `${this.Api_Context.getApiPrefix(
            'baseApi_out',
          )}cloud/group/cover/${fixedMsg.group_id}`;
          if (fixedMsg.msgCode === MessageContentType.Join_School_Verdict) {
            const applyTime = _.get(datum, 'body.msgBody.content.apply_time');
            const checkStatus = _.get(datum, 'body.msgBody.content.check_status');
            const schoolName = _.get(datum, 'body.msgBody.content.school_name');
            fixedMsg.avatar = this.getCourseAvatarUrl(this.userInfo.id as string);
            if (checkStatus === 1) {
              fixedMsg.title = '申请加入学校成功';
              fixedMsg.content = `你在 ${dayjs(applyTime).format(
                'YYYY-MM-DD HH:mm:ss',
              )} 发起的加入 ${schoolName} 的申请被通过，已经加入该学校。`;
            } else {
              fixedMsg.title = '申请加入学校失败';
              fixedMsg.content = `你在 ${dayjs(applyTime).format(
                'YYYY-MM-DD HH:mm:ss',
              )} 发起的加入 ${schoolName} 的申请被拒绝，无法加入该学校。`;
            }
          } else if (fixedMsg.msgCode === MessageContentType.Split_Group_Verdict) {
            const old_group = _.get(datum, 'body.msgBody.group.name');
            const new_group = _.get(datum, 'body.msgBody.content.new_group_name');
            fixedMsg.title = old_group;
            fixedMsg.link_group = true;
            fixedMsg.group_id = _.get(datum, 'body.msgBody.content.new_group_id');
            fixedMsg.avatar = _.get(datum, 'body.msgBody.group.cover_img');
            fixedMsg.content = `您被拆分至新的课程《${new_group}》`;
          } else if (fixedMsg.msgCode === MessageContentType.Merge_Group_Verdict) {
            const old_group = _.get(datum, 'body.msgBody.group.name');
            const new_group = _.get(datum, 'body.msgBody.content.new_group_name');
            fixedMsg.title = old_group;
            fixedMsg.link_group = true;
            fixedMsg.group_id = _.get(datum, 'body.msgBody.content.new_group_id');
            fixedMsg.avatar = _.get(datum, 'body.msgBody.group.cover_img');
            fixedMsg.content = `您所在的课程《${old_group}》已被合并至课程《${new_group}》`;
          } else if (fixedMsg.msgCode === MessageContentType.Clone_Group_Verdict) {
            const is_success = _.get(datum, 'body.msgBody.content.is_success');
            const ori_group_name = _.get(datum, 'body.msgBody.content.ori_group.name');
            const des_group_id = _.get(datum, 'body.msgBody.content.des_group.id');
            const apply_user_id = _.get(datum, 'body.msgBody.content.apply_user_id');
            const apply_user_nickname = _.get(
              datum,
              'body.msgBody.content.apply_user_nickname',
            );
            fixedMsg.avatar = `${this.Api_Context.getApiPrefix(
              'baseApi_out',
            )}cloud/group/cover/${des_group_id}`;
            if (is_success) {
              fixedMsg.title = '课程克隆成功';
              if (apply_user_id === this.userInfo.id) {
                fixedMsg.content = `您申请克隆的《${ori_group_name}》课程已克隆成功，请进入“克隆记录”页面查看详情`;
              } else {
                fixedMsg.content = `${apply_user_nickname} 申请克隆的《${ori_group_name}》课程已克隆成功`;
              }
            } else {
              fixedMsg.title = '课程克隆失败';
              if (apply_user_id === this.userInfo.id) {
                fixedMsg.content = `您申请克隆的《${ori_group_name}》课程克隆失败，请进入“克隆记录”页面查看详情`;
              } else {
                fixedMsg.content = `${apply_user_nickname} 申请克隆的《${ori_group_name}》课程克隆失败`;
              }
            }
          } else if (fixedMsg.msgCode === MessageContentType.Exit_To_Group) {
            const group_name = _.get(datum, 'body.msgBody.group.name');
            fixedMsg.title = group_name;
            fixedMsg.content = `课程成员 ${fixedMsg.operator_name}，已主动退出《${group_name}》课程`;
          } else if (fixedMsg.msgCode === MessageContentType.Remove_From_Group) {
            const group_name = _.get(datum, 'body.msgBody.group.name');
            fixedMsg.title = group_name;
            fixedMsg.content = `您已被 ${fixedMsg.operator_name} 移出《${group_name}》课程`;
          } else if (fixedMsg.msgCode === MessageContentType.Group_Role_Change) {
            fixedMsg.link_group = true;
            const group_name = _.get(datum, 'body.msgBody.group.name');
            const role = _.get(datum, 'body.msgBody.content.role') as string;
            const new_role = _.get(datum, 'body.msgBody.content.new_role') as string;
            fixedMsg.title = group_name;

            if (parseInt(new_role) === 1) {
              fixedMsg.content = `${
              fixedMsg.operator_name
              } 已取消您在《${group_name}》课程中的 ${getMemberRole(
                parseInt(role),
              )} 身份`;
            } else {
              fixedMsg.content = `${
              fixedMsg.operator_name
              } 已将您设置为《${group_name}》课程的 ${getMemberRole(
                parseInt(new_role),
              )}`;
            }
          } else if (fixedMsg.msgCode === MessageContentType.Course_Stop_Open) {
            const group_name = _.get(datum, 'body.msgBody.group.name');
            const group_key = _.get(datum, 'body.msgBody.content.group_key');

            fixedMsg.title = '教务课程停开';
            fixedMsg.avatar = _.get(datum, 'body.msgBody.group.cover_img');
            fixedMsg.content = `由于教务课程停开，您的 ${group_name}（${group_key}）课程已被禁用，如有资源克隆等需要可联系学校运维人员手动处理`;
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
        } else {
          if (group.course_property === '2') {
            // mooc
          } else {
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
              Text(`暂无${this.onlyUnread ? "未读的" : ""}系统消息`)
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
                  }
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
    .title(CustomNavTitle('系统消息', () => this.BuildNavRightBtn()))
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
          itemBorder: '',
          operateBuilder: () => this.BuildOperate(),
        })
        CustomDivider()
        CustomListItem({
          text: '全部已读',
          itemRadius: 8,
          itemBorder: '',
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
          itemBorder: '',
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
export function MessageSystemBuilder() {
  MessageSystem()
}