import { display } from "@kit.ArkUI";
import _ from "@wolfx/lodash";
import {
  Api_Context,
  AppIcon,
  CustomDivider,
  CustomList,
  CustomListItem,
  CustomToast,
  IconConstants,
  MessageApi,
  MessageCountModel,
  MessageSettingModel,
  xyApiGet,
  xyApiPost
} from "@xy/basic";

@Component
export struct MessagePage {
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @StorageLink('messageCount') messageCount: MessageCountModel = new MessageCountModel()
  @Link globalPageIndex: string
  @State isRefreshing: boolean = false
  @State screenWidth: number = 0
  @State settings: Record<string, string | Array<number>>[] = []
  dialogController: CustomDialogController = new CustomDialogController({
    builder: MessageSettingDialog(),
    alignment: DialogAlignment.Bottom,
    customStyle: true,
    cancel: () => this.dialogController.close(),
    closeAnimation: { duration: 0 }
  })

  aboutToAppear(): void {
    this.screenWidth = px2vp(display.getDefaultDisplaySync().width)

    this.onRefresh()
  }

  async onRefresh() {
    const response = await xyApiGet(this.Api_Context.getApiPrefix("baseApi_inner") + MessageApi.msgUnReadTipCount)
    if (response.success) {
      const data: Record<string, number> = response.data as Record<string, number>

      const course_un_read_count =
        data.task_un_read_count +
        data.announcement_un_read_count +
        data.subgroup_un_read_count +
        data.discussion_un_read_count +
        data.qa_un_read_count;

      this.messageCount.todo_un_read_count = data.todo_un_read_count
      this.messageCount.course_un_read_count = course_un_read_count
      this.messageCount.person_un_read_count = data.person_un_read_count
      this.messageCount.system_un_read_count = data.system_un_read_count
      this.messageCount.task_un_read_count = data.task_un_read_count
      this.messageCount.announcement_un_read_count = data.announcement_un_read_count
      this.messageCount.subgroup_un_read_count = data.subgroup_un_read_count
      this.messageCount.discussion_un_read_count = data.discussion_un_read_count
      this.messageCount.qa_un_read_count = data.qa_un_read_count
    }
  }

  @Builder
  BuildHeader() {
    RelativeContainer() {
      Row() {
        Text('消息中心')
          .fontSize(16)
          .fontColor('#404040')
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)

      Row() {
        AppIcon({
          iconCode: IconConstants.MORE,
          iconSize: 24,
          onClickBtn: () => {
            this.dialogController.open()
          }
        })
      }
      .alignRules({
        top: { anchor: "__container__", align: VerticalAlign.Top },
        right: { anchor: "__container__", align: HorizontalAlign.End },
      })
      .padding({ top: 12, right: 16 })
    }
    .flexBasis(42)
    .height(42)
  }

  @Builder
  BuildLeftIcon(iconCode: IconConstants, iconColor: ResourceColor) {
    Column() {
      AppIcon({
        iconCode: iconCode,
        iconColor: Color.White,
        iconSize: 16
      })
    }
    .width(48)
    .height(48)
    .margin({ right: 10 })
    .justifyContent(FlexAlign.Center)
    .backgroundColor(iconColor)
    .borderRadius(4)
  }

  @Builder
  BuildTodoOperate() {
    Row() {
      Badge({
        count: this.messageCount.todo_un_read_count > 0 ? 1 : 0,
        position: BadgePosition.Left,
        style: { badgeSize: 8, fontSize: 0 }
      }) {
        Text()
          .margin({ right: 20 })
      }

      AppIcon({ iconCode: IconConstants.RIGHT })
    }
  }

  @Builder
  BuildCourseOperate() {
    Row() {
      Badge({
        count: this.messageCount.course_un_read_count > 0 ? 1 : 0,
        position: BadgePosition.Left,
        style: { badgeSize: 8, fontSize: 0 }
      }) {
        Text()
          .margin({ right: 20 })
      }

      AppIcon({ iconCode: IconConstants.RIGHT })
    }
  }

  @Builder
  BuildPersonOperate() {
    Row() {
      Badge({
        count: this.messageCount.person_un_read_count > 0 ? 1 : 0,
        position: BadgePosition.Left,
        style: { badgeSize: 8, fontSize: 0 }
      }) {
        Text()
          .margin({ right: 20 })
      }

      AppIcon({ iconCode: IconConstants.RIGHT })
    }
  }

  @Builder
  BuildSystemOperate() {
    Row() {
      Badge({
        count: this.messageCount.system_un_read_count > 0 ? 1 : 0,
        position: BadgePosition.Left,
        style: { badgeSize: 8, fontSize: 0 }
      }) {
        Text()
          .margin({ right: 20 })
      }

      AppIcon({ iconCode: IconConstants.RIGHT })
    }
  }

  build() {
    Refresh({ refreshing: $$this.isRefreshing }) {
      Column() {
        this.BuildHeader()
        CustomList({ listPadding: { left: 16, right: 16 } }) {
          CustomListItem({
            iconBuilder: () => this.BuildLeftIcon(IconConstants.TO_DO_LIST, '#709DDD'),
            operateBuilder: () => this.BuildTodoOperate(),
            text: '待办事项',
            fontSize: 14,
            itemRadius: 4,
            itemPadding: 8,
            itemMargin: { top: 8 },
            itemBorder: {},
            onClickBtn: () => {
              this.pageInfos.pushPath({ name: 'messageTodo' })
            }
          })
          CustomListItem({
            iconBuilder: () => this.BuildLeftIcon(IconConstants.COURSE_LIST, '#45BA94'),
            operateBuilder: () => this.BuildCourseOperate(),
            text: '课程消息',
            fontSize: 14,
            itemRadius: 4,
            itemPadding: 8,
            itemMargin: { top: 8 },
            itemBorder: {},
            onClickBtn: () => {
              this.pageInfos.pushPath({ name: 'messageCourse' })
            }
          })
          CustomListItem({
            iconBuilder: () => this.BuildLeftIcon(IconConstants.PERSON_LIST, '#F27D5D'),
            operateBuilder: () => this.BuildPersonOperate(),
            text: '个人消息',
            fontSize: 14,
            itemRadius: 4,
            itemPadding: 8,
            itemMargin: { top: 8 },
            itemBorder: {},
            onClickBtn: () => {
              this.pageInfos.pushPath({ name: 'messagePerson' })
            }
          })
          CustomListItem({
            iconBuilder: () => this.BuildLeftIcon(IconConstants.SYSTEM_LIST, '#7BA5E1'),
            operateBuilder: () => this.BuildSystemOperate(),
            text: '系统消息',
            fontSize: 14,
            itemRadius: 4,
            itemPadding: 8,
            itemMargin: { top: 8 },
            itemBorder: {},
            onClickBtn: () => {
              this.pageInfos.pushPath({ name: 'messageSystem' })
            }
          })
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#f1f1f1')
    }
    .onRefreshing(() => {
      this.onRefresh()
      setTimeout(() => {
        this.isRefreshing = false
      }, 500)
    })
  }
}

@CustomDialog
export struct MessageSettingDialog {
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @State settings: Record<string, string | Array<number>>[] = []
  @State msgSetting: MessageSettingModel[] = []
  @State screenWidth: number = 0
  @State screenHeight: number = 0
  private controller: CustomDialogController

  async aboutToAppear() {
    this.screenWidth = px2vp(display.getDefaultDisplaySync().width)
    this.screenHeight = px2vp(display.getDefaultDisplaySync().height)

    this.msgSetting = [
      {
        "title": "任务消息",
        "showSubs": true,
        "subMsgType": "1",
        "subs": [{ "code": 210001, "title": '任务发布', "disabled": true },
          { "code": 210002, "title": '自评/互评提醒', "disabled": true },
          { "code": 210008, "title": '自评/互评分配答卷', "disabled": true },
          { "code": 210003, "title": '作业/测练被发回', "disabled": true },
          { "code": 210004, "title": '评价活动发布', "disabled": true },
          { "code": 210005, "title": '任务截止提醒', "disabled": true },
          { "code": 210006, "title": '任务撤销', "disabled": false },
          { "code": 210007, "title": '任务修改', "disabled": false }]
      },
      {
        "title": "课程公告",
        "showSubs": true,
        "subMsgType": "2",
        "subs": [{ "code": 220001, "title": '课程公告', "disabled": true }]
      },
      {
        "title": "小组消息",
        "showSubs": true,
        "subMsgType": "3",
        "subs": [{ "code": 230001, "title": '组内讨论帖', "disabled": false },
          { "code": 230002, "title": '新成员加入小组', "disabled": false },
          { "code": 230003, "title": '成员退出小组', "disabled": false }]
      },
      {
        "title": "讨论帖消息",
        "showSubs": true,
        "subMsgType": "4",
        "subs": [{ "code": 240001, "title": '帖子被置顶', "disabled": false },
          { "code": 240002, "title": '帖子被设为精华帖', "disabled": false },
          { "code": 240003, "title": '帖子被评论', "disabled": false },
          { "code": 240004, "title": '评论被回复', "disabled": false }]
      },
      {
        "title": "答疑消息",
        "showSubs": true,
        "subMsgType": "5",
        "subs": [{ "code": 250001, "title": '新增提问', "disabled": false },
          { "code": 250002, "title": '发起提问被回答', "disabled": false }]
      }
    ]

    const response = await xyApiGet(this.Api_Context.getApiPrefix("baseApi_inner") + MessageApi.msgSetting)
    if (response.success) {
      const data = response.data as Record<string, string | number | Record<string, string | Array<number>>[]>
      this.settings = data?.settings as Record<string, string | Array<number>>[]
    }
  }

  onSelectAll = (value: boolean) => {
    if (value !== this.judgeMsgSettingCheckAll()) {
      const new_settings = _.map(this.settings, setting => {
        const selected_msg_codes: Array<number> = [];
        const item = _.find(this.msgSetting, { subMsgType: setting.subMsgType }) as MessageSettingModel
        _.map(item.subs, (i: Record<string, string | number | boolean>) => {
          if (i.disabled || value) {
            selected_msg_codes.push(i.code as number);
          }
        });
        setting.selected_msg_codes = selected_msg_codes;
        return setting;
      });

      this.onUpdateSetting(new_settings);
    }
  };
  onSelectOptions = (value: boolean, subMsgType: string, code: number) => {
    if (value !== this.judgeMsgSettingCheck(subMsgType, code)) {
      const new_settings = _.map(this.settings, setting => {
        if (setting.subMsgType === subMsgType) {
          let selected_msg_codes = setting.selected_msg_codes as Array<number>;
          const include = _.includes(selected_msg_codes, code);
          if (value) {
            if (!include) {
              selected_msg_codes.push(code);
            }
          } else {
            if (include) {
              selected_msg_codes = _.filter(
                selected_msg_codes,
                item => item !== code,
              );
            }
          }

          setting.selected_msg_codes = selected_msg_codes
        }
        return setting;
      });
      this.onUpdateSetting(new_settings);
    }
  };
  onUpdateSetting = async (settings: Record<string, string | Array<number>>[]) => {
    const response =
      await xyApiPost(this.Api_Context.getApiPrefix("baseApi_inner") + MessageApi.msgSetting, { "settings": settings })
    if (response.success) {
      this.settings = settings
      CustomToast.toast_success("设置成功")
    } else {
      CustomToast.toast_fail(response.message)
    }
  }
  judgeMsgSettingCheckAll = () => {
    const unChecks = _.filter(this.settings, setting => {
      const msgSetting = _.find(this.msgSetting, { subMsgType: setting.subMsgType }) as MessageSettingModel
      return !!_.filter(
        msgSetting.subs,
        item => !_.includes(setting.selected_msg_codes, item.code),
      ).length;
    });

    return _.isEmpty(unChecks);
  };
  judgeMsgSettingCheck = (subMsgType: string, code: number) => {
    const msg_codes =
      (_.find(this.settings, { subMsgType: subMsgType })?.selected_msg_codes ?? []) as Array<number>;
    return _.includes(msg_codes, code)
  };
  onChangeShowStatue = (subMsgType: string) => {
    this.msgSetting = _.map(this.msgSetting, (item: MessageSettingModel) => {
      if (item.subMsgType === subMsgType) {
        item.showSubs = !item.showSubs
      }
      return item
    })
  };

  @Builder
  itemHead(item: MessageSettingModel) {
    Column() {
      Row() {
        AppIcon({
          iconCode: item.showSubs ? IconConstants.UP : IconConstants.DOWN,
          iconColor: '#fff',
          iconBackgroundColor: '#40A9FF',
          iconSize: 12,
          iconRadius: 20,
          iconPadding: 4,
          iconMargin: { right: 8 },
        })
        Text(item.title)
          .fontColor('#000')
          .fontSize(16)
          .fontWeight('bold')
      }
      .width('100%')
      .padding(16)
      .justifyContent(FlexAlign.Start)
      .onClick(() => this.onChangeShowStatue(item.subMsgType))

      CustomDivider()
    }
    .backgroundColor(Color.White)
    .alignItems(HorizontalAlign.Start)
  }

  build() {
    Column() {
      Row() {
        Column() {
          Text("消息提醒设置")
            .fontColor('#000')
            .fontSize(16)
            .fontWeight('bold')
          Text("*取消勾选后，该类任务不再发送消息提醒")
            .fontColor('#999999')
            .fontSize(13)
            .fontWeight(400)
            .margin({ top: 10 })
        }
        .alignItems(HorizontalAlign.Start)
        .flexGrow(1)

        Row() {
          Text("全选")
            .fontColor('#999999')
            .fontSize(13)
            .fontWeight(400)
          Checkbox()
            .select(this.judgeMsgSettingCheckAll())
            .selectedColor('#40A9FF')
            .shape(CheckBoxShape.CIRCLE)
            .onChange((value: boolean) => {
              this.onSelectAll(value);
            })
        }
      }
      .width('100%')
      .height(64)
      .padding({
        top: 10,
        bottom: 10,
        right: 16,
        left: 16
      })

      CustomDivider()

      List() {
        ForEach(this.msgSetting, (item: MessageSettingModel) => {
          ListItemGroup({ header: this.itemHead(item) }) {
            if (item.showSubs) {
              ForEach(item.subs, (sub: Record<string, string | number | boolean>) => {
                ListItem() {
                  Column() {
                    Row() {
                      Text(sub.title as string)
                        .fontColor('#000')
                        .fontSize(15)
                        .fontWeight(400)
                      Checkbox()
                        .select(this.judgeMsgSettingCheck(item.subMsgType, sub.code as number))
                        .selectedColor('#40A9FF')
                        .enabled(!sub.disabled)
                        .shape(CheckBoxShape.CIRCLE)
                        .onChange((value: boolean) => {
                          this.onSelectOptions(value, item.subMsgType, sub.code as number)
                        })
                    }
                    .width("100%")
                    .justifyContent(FlexAlign.SpaceBetween)
                    .alignItems(VerticalAlign.Center)
                    .padding(16)

                    CustomDivider()
                  }
                }
              })
            }
          }
        })
      }
      .width('100%')
      .height(this.screenHeight * 0.8 - 64)
      .sticky(StickyStyle.Header)
      .scrollBar(BarState.On)
    }
    .height(this.screenHeight * 0.8)
    .width(this.screenWidth)
    .borderRadius({ topLeft: 8, topRight: 8 })
    .backgroundColor(Color.White)
  }
}