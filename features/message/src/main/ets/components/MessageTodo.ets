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
  getMemberRole,
  IconConstants,
  MessageApi,
  MessageContentType,
  xyApiGet,
  xyApiPost,
  HomeApi,
  CustomPopup,
  UserInfoModel,
  xyApiPut
} from "@xy/basic"
import dayjs from "dayjs"
import { AssignClassModal } from "./AssignClassModal"

@Component
struct MessageTodo {
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @StorageLink('UserInfo') userInfo: UserInfoModel = new UserInfoModel()
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @State isRefreshing: boolean = false
  @State isLoading: boolean = false
  @State screenWidth: number = 0
  @State screenHeight: number = 0
  @State onlyUnread: boolean = true
  @State visible: boolean = false
  @State classList: Record<string, string | number>[] = []
  @State last_msg_id: string | null = null
  @State msgData: Record<string, string | number | boolean>[] = []
  private item: Record<string, string | number | boolean> = {}
  private verify: number = 0
  onChangeUnread: (check: boolean) => void = (check) => {
    this.onlyUnread = check
    this.onRefresh();
  }
  onDeleteAll: () => void = () => {
    this.handleDeleteAll()
  }
  dialogController: CustomDialogController = new CustomDialogController({
    builder: MessageSettingDialog({
      onlyUnread: this.onlyUnread,
      onChangeUnread: this.onChangeUnread,
      onDeleteAll: this.onDeleteAll,
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
      CustomToast.toast_info('暂无待办事项消息');
      return;
    }
    this.dialogController.close()

    CustomAlertDialog({
      title: '请确认',
      message: '是否确定删除所有待办事项（最多100条）？删除后将无法恢复',
      onClickBtn: () => {
        const ids = _.map(this.msgData, msg => msg.id);
        xyApiPost(this.Api_Context.getApiPrefix("baseApi_inner") + MessageApi.delSelectedMsg, {
          "message_ids": ids.slice(0, 100),
        }).then(response => {
          if (response.success) {
            CustomToast.toast_success("待办事项全部删除成功");
            this.onRefresh();
          }
        })
      }
    } as AlertDialogParam)
  }
  handleGetMsgTodoNotices = async () => {
    let body: Record<string, string | number> = { "page_size": 20 };
    if (this.onlyUnread) {
      body.msg_status = 0
    }
    if (this.last_msg_id) {
      body.last_msg_id = this.last_msg_id
    }
    const response = await xyApiGet(this.Api_Context.getApiPrefix("baseApi_inner") + MessageApi.queryTodoNotices, body)

    if (response.success) {
      const data = response.data as Record<string, string | number | Record<string, string | number>[]>

      const new_data =
        _.map(data?.list as Record<string, string | number>[], (datum: Record<string, string | number>) => {

          const fixedMsg: Record<string, string | number | boolean> = {};
          const group_id = _.get(datum, 'body.msgBody.group.id');
          fixedMsg.group_id = group_id;
          fixedMsg.avatar = `${this.Api_Context.getApiPrefix(
            'baseApi_out',
          )}cloud/group/cover/${group_id}`;
          fixedMsg.title = _.get(datum, 'body.msgBody.group.name');
          fixedMsg.id = _.get(datum, 'body.msgId');
          fixedMsg.vernierId = _.get(datum, 'id');
          fixedMsg.msgCode = _.get(datum, 'body.msgCode');
          fixedMsg.operator_id = _.get(datum, 'body.msgBody.operator.id');
          fixedMsg.operator_name = _.get(datum, 'body.msgBody.operator.nickname');
          if (fixedMsg.msgCode === MessageContentType.Invite_To_Group) {
            fixedMsg.be_join_role = _.get(datum, 'body.msgBody.content.be_join_role');
            fixedMsg.link_group = true;
            fixedMsg.content = `${fixedMsg.operator_name} 邀请您参加课程`;
          } else if (fixedMsg.msgCode === MessageContentType.Apply_Join_Group) {
            fixedMsg.class_id = _.get(datum, 'body.msgBody.content.class_id');
            const class_name = _.get(datum, 'body.msgBody.content.class_name');
            const student_number = _.get(datum, 'body.msgBody.content.student_number');
            const operator_role = _.get(datum, 'body.msgBody.operator.role', 1);
            fixedMsg.link_group = true;
            if (operator_role === 1) {
              fixedMsg.content = `${fixedMsg.operator_name}（一卡通号：${
              student_number ? student_number : '暂无数据'
              }）申请加入班级（${class_name}）`;
            } else {
              fixedMsg.content = `${fixedMsg.operator_name}（一卡通号：${
              student_number ? student_number : '暂无数据'
              }）申请成为本课程${getMemberRole(operator_role as number)}`;
            }
          } else if (fixedMsg.msgCode === MessageContentType.Apply_Merge_Group) {
            // 主合并课程siteId
            fixedMsg.mainSiteId = _.get(datum, 'body.msgBody.content.merge_site_id');
            // 被合并课程siteId
            fixedMsg.beMergedSiteId = _.get(
              datum,
              'body.msgBody.content.be_merge_site_id',
            );
            const school_name = _.get(datum, 'body.msgBody.operator.school_name');
            const site_name = _.get(datum, 'body.msgBody.content.be_merge_site_name');

            fixedMsg.title = '课程合并申请';
            fixedMsg.avatar = this.getCourseAvatarUrl(fixedMsg.operator_id as string);
            fixedMsg.content =
              `${school_name} - ${fixedMsg.operator_name} 申请合并您的课程《${site_name}》的课程成员，合并完成后您的课程将会被删除`;
            fixedMsg.remind =
              '提示：请谨慎审核申请信息，建议不要随意允许陌生人合并自己的课程。';
          } else if (fixedMsg.msgCode === MessageContentType.Apply_Clone_Group) {
            let cloneContents: Array<string> = [];
            const schoolShortName = _.get(
              datum,
              'body.msgBody.content.applayer.schoolShortName',
            );
            const nickname = _.get(datum, 'body.msgBody.content.applayer.nickname');
            const applyCourse = _.get(datum, 'body.msgBody.content.fromGroup.name');
            // const applayParams = _.get(datum, 'body.msgBody.content.applayParams') as Record<string, string | number>[];
            // const pickClone = _.pickBy(
            //   applayParams,
            //   (val: number, key: string) => val === 1 && key !== 'isAppend',
            // );
            // const cloneContentObj: Record<string, string> = {
            //   "is_clone_res": '备授课内容',
            //   "is_clone_setting": '课程设置',
            //   "is_clone_grade": '总评成绩设置',
            //   "is_clone_group_desc": '课程简介',
            //   "is_clone_application": '课程应用',
            // };
            // _.forEach(pickClone, (val, key) => {
            //   if (cloneContentObj[key]) {
            //     cloneContents.push(cloneContentObj[key]);
            //   }
            // });
            const cloneText = _.isEmpty(cloneContents)
              ? ''
              : _.join(cloneContents, '、');
            fixedMsg.apply_user_id = _.get(datum, 'body.msgBody.content.applayer.id');
            fixedMsg.apply_user_nickname = _.get(
              datum,
              'body.msgBody.content.applayer.nickname',
            );
            fixedMsg.applay_id = _.get(datum, 'body.msgBody.content.applayId');
            fixedMsg.title = '课程克隆申请';
            const avatar = _.get(datum, 'body.msgBody.content.applayer.avatar');
            fixedMsg.avatar = `${this.Api_Context.getApiPrefix('baseApi_out')}${avatar}`;
            const key_number = _.get(
              datum,
              'body.msgBody.content.fromGroup.key_number',
            );
            fixedMsg.content =
              `${schoolShortName} - ${nickname} 申请克隆您的课程《${applyCourse}》（课程空间编号：${key_number}）,克隆内容包含 ${cloneText}`;
            fixedMsg.remind =
              '提示：请谨慎审核申请信息，建议不要随意允许陌生人克隆自己的课程';
          } else if (fixedMsg.msgCode === MessageContentType.Apply_Be_Friend) {
            const nickname = _.get(datum, 'body.msgBody.operator.nickname');
            fixedMsg.title = `${nickname} 的好友申请`;
            fixedMsg.content = `${nickname} 想要加您为好友`;
            fixedMsg.avatar = this.getCourseAvatarUrl(fixedMsg.operator_id as string);
          }
          fixedMsg.node_id = _.get(datum, 'body.msgBody.content.node_id');
          fixedMsg.createAt = _.get(datum, 'createdAt');
          fixedMsg.status = _.get(datum, 'msgStatus[0].status', -1);

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
  onRefresh = () => {
    this.last_msg_id = null;
    this.handleGetMsgTodoNotices()
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
      this.handleGetMsgTodoNotices()
    }
  };
  getCourseAvatarUrl = (user_id: string) => {
    return `${this.Api_Context.getApiPrefix(
      'baseApi_out',
    )}cloud/file/avatar/${user_id}?random=${dayjs().format('YYYY/MM/DD/HH')}`;
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
  onEnterMemberAdd = async (group_id: string) => {
    const response = await xyApiGet(this.Api_Context.getApiPrefix("baseApi_inner") + HomeApi.queryGroup +
      `/${group_id}`)

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
  }
  onAcceptPress = async (item: Record<string, string | number | boolean>, verify: number) => {
    if (item.msgCode === MessageContentType.Apply_Clone_Group) {
      // 克隆申请
      const response = await xyApiPost(this.Api_Context.getApiPrefix("baseApi_inner") + MessageApi.verifyCloneSite, {
        "applay_id": item?.applay_id,
        "verify": verify,
        "apply_user_id": item.apply_user_id,
        "apply_user_nickname": item.apply_user_nickname,
      })
      if (response?.success) {
        if (verify === 1) {
          this.onUpdateMsgStatus(item.id as string, 2)
          CustomToast.toast_success('已同意该邀请');
        } else if (verify === 2) {
          this.onUpdateMsgStatus(item.id as string, 3)
          CustomToast.toast_success('已拒绝该申请');
        }
      }
    } else if (item.msgCode === MessageContentType.Invite_To_Group) {
      if (verify === 2) {
        this.onSelectClass(item, verify, '');
      } else {
        // 判断身份，学生需要选择班级，教师无需
        if (item.be_join_role === 1) {
          xyApiGet(this.Api_Context.getApiPrefix('baseApi_inner') + HomeApi.groupClassList + '/' + item.group_id)
            .then((response) => {
              this.classList = response.data as Record<string, string | number>[]
              this.visible = true
              this.item = item
              this.verify = verify
            })
        } else {
          this.onSelectClass(item, verify, '');
        }
      }
    } else if (item.msgCode === MessageContentType.Apply_Be_Friend) {
      // 好友邀请
      const response = await xyApiPost(this.Api_Context.getApiPrefix("baseApi_inner") + MessageApi.verifyFriend, {
        "friend_id": item?.operator_id,
        "status": verify === 1 ? 2 : 3,
      })
      if (response?.success) {
        if (verify === 1) {
          this.onUpdateMsgStatus(item.id as string, 2)
          CustomToast.toast_success('已同意该邀请');
        } else if (verify === 2) {
          this.onUpdateMsgStatus(item.id as string, 3)
          CustomToast.toast_success('已拒绝该申请');
        }
      }
    } else if (item.msgCode === MessageContentType.Apply_Merge_Group) {
      // 课程合并
      const response = await xyApiPost(this.Api_Context.getApiPrefix("ccApi") + MessageApi.mergeSiteVerify, {
        "siteId": item?.mainSiteId,
        "applyStatus": verify,
        "mergeSiteId": item?.beMergedSiteId,
      })
      if (response.code === 200) {
        if (verify === 1) {
          this.onUpdateMsgStatus(item.id as string, 2)
          CustomToast.toast_success('已同意该邀请');
        } else if (verify === 2) {
          this.onUpdateMsgStatus(item.id as string, 3)
          CustomToast.toast_success('已拒绝该申请');
        }
      }
    } else {
      CustomToast.toast_info("移动端暂不支持处理该消息类型");
    }
  }
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
    this.visible = false;
  };
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
          if (_.isEmpty(this.msgData)) {
            Text(`暂无${this.onlyUnread ? "未处理的" : ""}代办事项`)
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

                        if (item.status === 0) {
                          if (item.msgCode === MessageContentType.Invite_To_Group ||
                            item.msgCode === MessageContentType.Apply_Clone_Group ||
                            item.msgCode === MessageContentType.Apply_Be_Friend ||
                            item.msgCode === MessageContentType.Apply_Merge_Group) {
                            Text('同意')
                              .padding(8)
                              .fontSize(13)
                              .fontColor(Color.White)
                              .backgroundColor('#40A9FF')
                              .borderRadius(4)
                              .margin({ right: 4 })
                              .onClick(() => this.onAcceptPress(item, 1))
                            Text('拒绝')
                              .padding(8)
                              .fontSize(13)
                              .backgroundColor(Color.White)
                              .fontColor('#999999')
                              .borderColor('#F5F5F5')
                              .borderWidth(1)
                              .borderRadius(4)
                              .onClick(() => this.onAcceptPress(item, 2))
                          }
                          if (item.msgCode === MessageContentType.Apply_Join_Group) {
                            Row() {
                              Text("去课程中处理")
                                .fontColor('#40A9FF')
                                .fontSize(13)
                                .fontWeight(400)
                              AppIcon({
                                iconCode: IconConstants.NEXT_ACTIVITY,
                                iconColor: '#40A9FF',
                                iconSize: 12,
                              })
                            }
                            .onClick(() => this.onEnterMemberAdd(item.group_id as string))
                          }
                        } else {
                          Text(item.status === 2 ? "已同意" : "已拒绝")
                            .fontColor('#999')
                            .fontSize(13)
                            .fontWeight(400)
                        }
                      }
                    }.layoutWeight(1)
                  }.padding(12)
                  .borderWidth({ bottom: 1 })
                  .borderColor({ bottom: '#ebebeb' })
                }
                .onClick(() => {
                  this.pageInfos.pushPath({
                    name: 'messageTodoDetail', param: JSON.stringify(item)
                  })
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
        .width(this.screenWidth - 24)
        .height('100%')
      }
      .onRefreshing(() => {
        this.onRefresh()
      })

      AssignClassModal({
        visible: $visible,
        classList: $classList,
        name: this.userInfo.realname,
        onSelect: (selectClass: Record<string, string | number>) => {
          this.onSelectClass(this.item, this.verify, selectClass.id as string)
        }
      })
    }
    .title(CustomNavTitle('代办事项', () => this.BuildNavRightBtn()))
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
          text: '仅看未处理',
          itemRadius: 8,
          itemBorder: {},
          operateBuilder: () => this.BuildOperate(),
        })
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
export function MessageTodoBuilder() {
  MessageTodo()
}