import { display } from "@kit.ArkUI";
import { Api_Context, AppIcon, CustomList, CustomListItem, IconConstants, MessageApi,
  MessageCountModel,
  xyApiGet } from "@xy/basic";


@Component
export struct MessagePage {
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @StorageLink('messageCount') messageCount: MessageCountModel = new MessageCountModel()
  @Link globalPageIndex: string
  @State isRefreshing: boolean = false
  @State screenWidth: number = 0

  aboutToAppear(): void {
    this.screenWidth = px2vp(display.getDefaultDisplaySync().width)

    this.getMsgUnReadInfo()
  }

  async getMsgUnReadInfo() {
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
            lineHeight: 14,
            itemRadius: 4,
            itemPadding: 8,
            itemMargin: { top: 8 },
            itemBorder: '',
            onClickBtn: () => {
              this.pageInfos.pushPath({ name: 'messageTodo' })
            }
          })
          CustomListItem({
            iconBuilder: () => this.BuildLeftIcon(IconConstants.COURSE_LIST, '#45BA94'),
            operateBuilder: () => this.BuildCourseOperate(),
            text: '课程消息',
            fontSize: 14,
            lineHeight: 14,
            itemRadius: 4,
            itemPadding: 8,
            itemMargin: { top: 8 },
            itemBorder: '',
            onClickBtn: () => {
              // this.pageInfos.pushPath({ name: 'messageCourse' })
            }
          })
          CustomListItem({
            iconBuilder: () => this.BuildLeftIcon(IconConstants.PERSON_LIST, '#F27D5D'),
            operateBuilder: () => this.BuildPersonOperate(),
            text: '个人消息',
            fontSize: 14,
            lineHeight: 14,
            itemRadius: 4,
            itemPadding: 8,
            itemMargin: { top: 8 },
            itemBorder: '',
            onClickBtn: () => {
              // this.pageInfos.pushPath({ name: 'messagePerson' })
            }
          })
          CustomListItem({
            iconBuilder: () => this.BuildLeftIcon(IconConstants.SYSTEM_LIST, '#7BA5E1'),
            operateBuilder: () => this.BuildSystemOperate(),
            text: '系统消息',
            fontSize: 14,
            lineHeight: 14,
            itemRadius: 4,
            itemPadding: 8,
            itemMargin: { top: 8 },
            itemBorder: '',
            onClickBtn: () => {
              // this.pageInfos.pushPath({ name: 'messageSystem' })
            }
          })
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#f1f1f1')
    }
    .onRefreshing(() => {
      this.getMsgUnReadInfo()
      setTimeout(() => {
        this.isRefreshing = false
      }, 500)
    })
  }
}
