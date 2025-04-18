import { display } from "@kit.ArkUI";
import { AppIcon, CustomList, CustomListItem, IconConstants } from "@xy/basic";


@Component
export struct MessagePage {
  @Link globalPageIndex: string
  @State isRefreshing: boolean = false
  @State screenWidth: number = 0

  aboutToAppear(): void {
    this.screenWidth = px2vp(display.getDefaultDisplaySync().width)
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
  BuildLeftIcon(iconCode: IconConstants) {
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
    .backgroundColor('#709DDD')
    .borderRadius(4)
  }

  @Builder
  BuildOperate() {
    Row() {
      Badge({
        count: 2,
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
            iconBuilder: () => this.BuildLeftIcon(IconConstants.TO_DO_LIST),
            operateBuilder: () => this.BuildOperate(),
            text: '待办事项',
            fontSize: 14,
            lineHeight: 14,
            itemRadius: 4,
            itemPadding: 8,
            itemBorder: '',
            onClickBtn: () => {
              // this.pageInfos.pushPath({ name: 'userReport' })
            }
          })
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#f1f1f1')
    }
    .onRefreshing(() => {
      setTimeout(() => {
        this.isRefreshing = false
      }, 500)
    })
  }
}
