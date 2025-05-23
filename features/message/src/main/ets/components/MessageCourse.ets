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
  xyApiDelete
} from "@xy/basic"
import dayjs from "dayjs"

@Component
struct MessageCourse {
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @StorageLink('messageCount') messageCount: MessageCountModel = new MessageCountModel()
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @State isRefreshing: boolean = false
  @State isLoading: boolean = false
  @State screenWidth: number = 0
  @State screenHeight: number = 0
  @State onlyUnread: boolean = true
  @State msgTypeIndex: number = 0
  @State msgTypeName: string = '课程消息'
  @State last_msg_id: string | null = null
  @State selectGroup: string | null = null
  @State filterGroups: Record<string, string>[] = []
  @State filterMessages: Record<string, string | number>[] = []
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
      CustomToast.toast_info(`暂无${this.msgTypeName}`);
      return;
    }
    this.dialogController.close()

    CustomAlertDialog({
      title: '请确认',
      message: `是否确定删除所有${this.msgTypeName}（最多100条）？删除后将无法恢复`,
      onClickBtn: () => {
        const ids = _.map(this.msgData, msg => msg.id);
        xyApiPost(this.Api_Context.getApiPrefix("baseApi_inner") + MessageApi.delSelectedMsg, {
          "message_ids": ids.slice(0, 100),
        }).then(response => {
          if (response.success) {
            CustomToast.toast_success(`${this.msgTypeName}全部删除成功`);
            this.onRefresh();
          }
        })
      }
    } as AlertDialogParam)
  }
  handleReadAll = () => {
    if (_.isEmpty(this.msgData)) {
      CustomToast.toast_info(`暂无${this.msgTypeName}`);
      return;
    }
    this.dialogController.close()
    CustomAlertDialog({
      title: '请确认',
      message: `是否确定要将所有${this.msgTypeName}（最多100条）标记为已读？`,
      onClickBtn: () => {
        const ids = _.map(this.msgData, msg => msg.id);
        xyApiPost(this.Api_Context.getApiPrefix("baseApi_inner") + MessageApi.updateMsgStatus, {
          "message_ids": ids.slice(0, 100),
          "status": 1,
        }).then(response => {
          if (response.success) {
            CustomToast.toast_success(`${this.msgTypeName}全部已读设置成功`);
            this.onRefresh();
          }
        })
      }
    } as AlertDialogParam)
  }
  onInitFilter = async () => {
    const filterList: Record<string, string>[] = []
    const response = await xyApiGet(this.Api_Context.getApiPrefix("baseApi_inner") + HomeApi.queryJoinedGroups)
    if (response.success) {
      _.forEach(response.data, (item: Record<string, string>) => {
        if (dayjs().isAfter(dayjs(item.start_time)) && dayjs().isBefore(dayjs(item.end_time))) {
          filterList.push({ 'title': item.name, 'value': item.id })
        }
      })
      filterList.unshift({
        'title': '全部课程',
        "value": ''
      })
    }
    this.filterGroups = filterList

    const total_count =
      (this.messageCount.task_un_read_count ?? 0) +
        (this.messageCount.announcement_un_read_count ?? 0) +
        (this.messageCount.subgroup_un_read_count ?? 0) +
        (this.messageCount.discussion_un_read_count ?? 0) +
        (this.messageCount.qa_un_read_count ?? 0);
    this.filterMessages = [
      {
        "title": '课程消息',
        "count": total_count,
      },
      {
        "title": '任务消息',
        "count": this.messageCount.task_un_read_count,
      },
      {
        "title": '课程公告',
        "count": this.messageCount.announcement_un_read_count,
      },
      {
        "title": '小组消息',
        "count": this.messageCount.subgroup_un_read_count,
      },
      {
        "title": '讨论帖消息',
        "count": this.messageCount.discussion_un_read_count,
      },
      {
        "title": '答疑消息',
        "count": this.messageCount.qa_un_read_count,
      },
    ]
  }
  onGetCourseData = async () => {
    let body: Record<string, string | number> = { "page_size": 20 };
    if (this.onlyUnread) {
      body.msg_status = 0
    }
    if (this.last_msg_id) {
      body.last_msg_id = this.last_msg_id
    }
    if (this.selectGroup) {
      body.group_id = this.selectGroup
    }

    let _url = MessageApi.queryCourseNotices;
    switch (this.msgTypeIndex) {
      case 0:
        _url = MessageApi.queryCourseNotices;
        break;
      case 1:
        _url = MessageApi.queryCourseTaskNotices;
        break;
      case 2:
        _url = MessageApi.queryCourseAnnoNotices;
        break;
      case 3:
        _url = MessageApi.queryCourseSubgroupNotices;
        break;
      case 4:
        _url = MessageApi.queryCourseDiscussNotices;
        break;
      case 5:
        _url = MessageApi.queryCourseAreaNotices;
        break;
      default:
        break;
    }

    const response = await xyApiGet(this.Api_Context.getApiPrefix("baseApi_inner") + _url, body)

    if (response.success) {
      const data = response.data as Record<string, string | number | Record<string, string | number>[]>
      const new_data =
        _.map(data?.list as Record<string, string | number>[], (datum: Record<string, string | number>) => {

          const fixedMsg: Record<string, string | number | boolean> = {};

          if (this.msgTypeIndex === 2) {
            const group_id = _.get(datum, 'group_id');
            fixedMsg.group_id = group_id;
            fixedMsg.avatar = `${this.Api_Context.getApiPrefix(
              'baseApi_out',
            )}cloud/group/cover/${group_id}`;
            fixedMsg.id = _.get(datum, 'msg_id');
            fixedMsg.vernierId = _.get(datum, 'id');
            fixedMsg.msgCode = MessageContentType.Group_Announcement;
            fixedMsg.link_group = true;

            fixedMsg.title = _.get(datum, 'group_name');
            fixedMsg.content = _.get(datum, 'content.data');

            fixedMsg.createAt = _.get(datum, 'createdAt');
            fixedMsg.status = _.get(datum, 'status', -1);
          } else {
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
            if (fixedMsg.msgCode === MessageContentType.Answer_Be_Reject) {
              fixedMsg.link_group = true;
              fixedMsg.content = `答题记录被发回，请返回重新作答 ${_.get(
                datum,
                'body.msgBody.content.node_name',
              )}`;
            } else if (fixedMsg.msgCode === MessageContentType.Task_Publish) {
              fixedMsg.link_group = true;
              fixedMsg.content = `${fixedMsg.operator_name} 发布了任务 ${_.get(
                datum,
                'body.msgBody.content.name',
              )}`;
            } else if (fixedMsg.msgCode === MessageContentType.Task_Cancel) {
              fixedMsg.link_group = true;
              fixedMsg.content = `${fixedMsg.operator_name} 撤销了任务 ${_.get(
                datum,
                'body.msgBody.content.name',
              )}`;
            } else if (fixedMsg.msgCode === MessageContentType.Task_Update) {
              fixedMsg.link_group = true;
              fixedMsg.content = `${fixedMsg.operator_name} 修改了任务 ${_.get(
                datum,
                'body.msgBody.content.name',
              )}`;
            } else if (fixedMsg.msgCode === MessageContentType.Mark_Distribute_Paper) {
              const node_name = _.get(datum, 'body.msgBody.content.node_name');
              const task_type = _.get(datum, 'body.msgBody.content.task_type');
              const mark_mode = _.get(datum, 'body.msgBody.content.mark_mode');
              const distribute_success = _.get(
                datum,
                'body.msgBody.content.distribute_success',
              );

              fixedMsg.link_group = true;

              if (distribute_success) {
                const mark_mode_text = mark_mode === 3 ? '自评' : '互评';
                fixedMsg.content = `${this.getTypeByTasktype(
                  task_type as number,
                )}【${node_name}】已成功在答题截止后为学生分配待批阅的${mark_mode_text}答卷（仅为提交过答卷的学生分配）`;
              } else {
                fixedMsg.content =
                  `由于互评任务《${node_name}》的实际提交人数小于两人，无法正常分配互评答卷。\n修改方式：（1）修改批阅截止时间让任务处于未完成状态；（2）修改完成后，再修改批阅方式。`;
              }
            } else if (fixedMsg.msgCode === MessageContentType.Mark_Mode_Remind) {
              fixedMsg.link_group = true;
              const node_name = _.get(datum, 'body.msgBody.content.node_name');
              const task_type = _.get(datum, 'body.msgBody.content.task_type');
              const mark_mode = _.get(datum, 'body.msgBody.content.mark_mode');
              const mark_mode_text = mark_mode === 3 ? '自评' : '互评';
              fixedMsg.content = `${this.getTypeByTasktype(
                task_type as number,
              )}【${node_name}】已为你分配待批阅的${mark_mode_text}答卷，请尽快前往批阅`;
            } else if (fixedMsg.msgCode === MessageContentType.Task_End_Remind) {
              fixedMsg.link_group = true;
              const node_name = _.get(datum, 'body.msgBody.content.node_name');
              const task_end_time = _.get(datum, 'body.msgBody.content.task_end_time');
              fixedMsg.content = `任务 ${node_name} 即将在 ${dayjs(task_end_time).format(
                'YYYY-MM-DD HH:mm:ss',
              )} 截止，请尽快完成。`;
            } else if (fixedMsg.msgCode === MessageContentType.Group_Announcement) {
              fixedMsg.link_group = true;
              fixedMsg.content = _.get(datum, 'body.msgBody.content.data');
            } else if (
              fixedMsg.msgCode === MessageContentType.Publish_Evaluation_Activity
            ) {
              const activity_name = _.get(datum, 'body.msgBody.content.activity_name');
              fixedMsg.link_group = true;
              fixedMsg.activity_id = _.get(datum, 'body.msgBody.content.activity_id');
              fixedMsg.content = `${fixedMsg.operator_name} 发布了新的评价活动 ${activity_name}`;
            } else if (fixedMsg.msgCode === MessageContentType.Discuss_Be_Top) {
              fixedMsg.link_group = true;
              const point_title = _.get(datum, 'body.msgBody.content.point_title');
              fixedMsg.content = `恭喜！您的帖子 ${point_title} 被置顶，快去看看吧！`;
            } else if (fixedMsg.msgCode === MessageContentType.Discuss_Be_Best) {
              fixedMsg.link_group = true;
              const point_title = _.get(datum, 'body.msgBody.content.point_title');
              fixedMsg.content = `恭喜！您的帖子 ${point_title} 被设为精华帖，快去看看吧！`;
            } else if (fixedMsg.msgCode === MessageContentType.Discuss_Be_Common) {
              fixedMsg.link_group = true;
              const point_title = _.get(datum, 'body.msgBody.content.point_title');
              fixedMsg.content = `您的帖子 ${point_title} 被评论啦，快去看看吧！`;
            } else if (fixedMsg.msgCode === MessageContentType.Discuss_Be_Reply) {
              fixedMsg.link_group = true;
              const point_title = _.get(datum, 'body.msgBody.content.point_title');
              fixedMsg.content = `您在 ${point_title} 发表的评论收到了回复，快去看看吧！`;
            } else if (fixedMsg.msgCode === MessageContentType.Subgroup_Member_Join) {
              fixedMsg.link_group = true;
              const nickname = _.get(datum, 'body.msgBody.content.nickname');
              const subgroup_name = _.get(datum, 'body.msgBody.subgroup.name');
              fixedMsg.content = `您所在的 ${subgroup_name} 小组有新成员 ${nickname} 加入啦！`;
            } else if (fixedMsg.msgCode === MessageContentType.Subgroup_Member_Exit) {
              fixedMsg.link_group = true;
              const nickname = _.get(datum, 'body.msgBody.content.nickname');
              const subgroup_name = _.get(datum, 'body.msgBody.subgroup.name');
              fixedMsg.content = `${nickname} 退出了您所在的 ${subgroup_name} 小组`;
            } else if (fixedMsg.msgCode === MessageContentType.Subgroup_Publish_Discuss) {
              fixedMsg.link_group = true;
              const subgroup_name = _.get(datum, 'body.msgBody.subgroup.name');
              const name = _.get(datum, 'body.msgBody.content.name');
              fixedMsg.content = `${fixedMsg.operator_name} 在 ${subgroup_name} 小组内发布了讨论 ${name}，快去看看吧！`;
            } else if (fixedMsg.msgCode === MessageContentType.Area_add_Question) {
              fixedMsg.link_group = true;
              const title = _.get(datum, 'body.msgBody.content.title');
              const operator_id = _.get(datum, 'body.msgBody.operator.id');
              fixedMsg.avatar = this.getCourseAvatarUrl(operator_id as string);
              fixedMsg.content = `有新的学生提问 ${title} 需要答疑，快去看看吧！`;
            } else if (fixedMsg.msgCode === MessageContentType.Area_Be_Answer) {
              fixedMsg.link_group = true;
              const title = _.get(datum, 'body.msgBody.content.title');
              const operator_id = _.get(datum, 'body.msgBody.operator.id');
              fixedMsg.avatar = this.getCourseAvatarUrl(operator_id as string);
              fixedMsg.content = `您发起的提问【${title}】有新的动态，快去看看吧！`;
            }
            fixedMsg.node_id = _.get(datum, 'body.msgBody.content.node_id');
            fixedMsg.createAt = _.get(datum, 'createdAt');
            fixedMsg.status = _.get(datum, 'msgStatus[0].status', -1);
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
  getTypeByTasktype = (type: number) => {
    switch (type) {
      case 1:
        return '自主观看';
      case 2:
        return '作业';
      case 3:
        return '练习';
      case 4:
        return '测验';
      case 5:
        return '问卷';
      case 6:
        return '讨论';
      default:
        return '';
    }
  };
  getCourseAvatarUrl = (user_id: string) => {
    return `${this.Api_Context.getApiPrefix(
      'baseApi_out',
    )}cloud/file/avatar/${user_id}?random=${dayjs().format('YYYY/MM/DD/HH')}`;
  }
  onRefresh = () => {
    this.last_msg_id = null;
    this.onInitFilter()
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
  onEnterAppraise = (item: Record<string, string | number>) => {
    if (item.status === 0) {
      // 标记已读
      this.onUpdateMsgStatus(item.id as string, item.status)
    }
    // courseStudentAppraise
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
          Select(this.filterGroups.map((item) => {
            return { 'value': item.title } as SelectOption
          }))
            .width("100%")
            .backgroundColor(Color.White)
            .selected(0)
            .value(this.filterGroups.length > 0 ? this.filterGroups[0].title : "")
            .onSelect((index: number) => {
              this.selectGroup = this.filterGroups[index].value
              this.onGetCourseData()
            })

          Flex({ direction: FlexDirection.Column }) {
            List() {
              ForEach(this.filterMessages, (item: Record<string, string | number>, index: number) => {
                ListItem() {
                  Row() {
                    Badge({
                      count: item.count > 0 ? 1 : 0,
                      position: BadgePosition.RightTop,
                      style: { badgeSize: 8, fontSize: 0 }
                    }) {
                      Text(index === 0 ? "全部消息" : item.title as string)
                        .padding({ bottom: 12 })
                        .borderWidth({ bottom: this.msgTypeIndex === index ? 1 : 0 })
                        .borderColor('#40A9FF')
                        .fontColor('#999')
                        .fontSize(14)
                        .textAlign(TextAlign.Center)
                        .onClick(() => {
                          this.msgTypeName = item.title as string
                          this.msgTypeIndex = index
                          this.onGetCourseData()
                        })
                    }
                  }.padding({ left: 12, right: 12 })
                }
              })
            }
            .flexShrink(0)
            .width(this.screenWidth - 24)
            .height(44)
            .alignListItem(ListItemAlign.Center)
            .scrollBar(BarState.Off)
            .listDirection(Axis.Horizontal)
            .margin({ top: 12, bottom: 12 })

            if (_.isEmpty(this.msgData)) {
              Text(`暂无${this.onlyUnread ? "未读的" : ""}${this.msgTypeName}`)
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

                          if (item.msgCode === MessageContentType.Publish_Evaluation_Activity) {
                            Row() {
                              Text("前往评价活动")
                                .fontColor('#40A9FF')
                                .fontSize(13)
                                .fontWeight(400)
                              AppIcon({
                                iconCode: IconConstants.NEXT_ACTIVITY,
                                iconColor: '#40A9FF',
                                iconSize: 12,
                              })
                            }
                            .onClick(() => this.onEnterAppraise(item as Record<string, string | number>))
                          }
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
                  .onClick(() => {
                    this.pageInfos.pushPath({ name: 'messageCourseDetail', param: JSON.stringify(item) })
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
    .title(CustomNavTitle('课程消息', () => this.BuildNavRightBtn()))
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
export function MessageCourseBuilder() {
  MessageCourse()
}