import { CustomList, CustomListItem, CustomNavTitle, CustomToast } from "@xy/basic"

@Component
struct NoticeList {
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()

  @Builder
  BuildLeftIcon(src: Resource) {
    Image(src)
      .width(32)
      .height(32)
      .margin({ right: 10 })
      .borderRadius(4)
  }

  build() {
    NavDestination() {
      Flex({ direction: FlexDirection.Column }) {
        CustomList() {
          CustomListItem({
            text: '课程公告',
            itemBorder: {},
            itemMargin: { top: 12 },
            itemRadius: 4,
            iconBuilder: () => this.BuildLeftIcon($r('app.media.course_notice')),
            onClickBtn: (): void => this.pageInfos.pushPath({ name: 'courseNotice' })
          })
          CustomListItem({
            text: '课程日志',
            itemBackgroundColor: '#EBEDF0',
            itemBorder: {},
            itemMargin: { top: 12 },
            itemRadius: 4,
            iconBuilder: () => this.BuildLeftIcon($r('app.media.course_active')),
            onClickBtn: (): void => CustomToast.toast_info('移动端暂未开放课程日志功能，请去web端查看。')
          })
        }
      }
      .margin({ left: 12, right: 12 })
    }
    .title(CustomNavTitle('通知公告'))
    .backgroundColor('#f1f1f1')
  }
}

@Builder
export function NoticeListBuilder() {
  NoticeList()
}