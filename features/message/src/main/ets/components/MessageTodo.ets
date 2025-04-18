import { display } from "@kit.ArkUI"
import { Api_Context, AppIcon, CustomNavTitle, IconConstants } from "@xy/basic"

@Component
struct MessageTodo {
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @State isRefreshing: boolean = false
  @State screenWidth: number = 0
  @State screenHeight: number = 0


  aboutToAppear(): void {
    this.screenWidth = px2vp(display.getDefaultDisplaySync().width)
    this.screenHeight = px2vp(display.getDefaultDisplaySync().height)
    this.handleRefresh()
  }

  handleRefresh = () => {

  }

  @Builder
  BuildNavRightBtn() {
    AppIcon({
      iconCode: IconConstants.MORE,
      iconSize: 24,
      onClickBtn: () => {
      }
    })
  }

  build() {
    NavDestination() {
      Refresh({ refreshing: $$this.isRefreshing }) {
        Column() {
        }
        .width(this.screenWidth - 24)
      }
      .onRefreshing(() => {
        this.handleRefresh()
      })
    }
    .title(CustomNavTitle('代办事项', () => this.BuildNavRightBtn()))
    .backgroundColor("#f1f1f1")
  }
}


@Builder
export function MessageTodoBuilder() {
  MessageTodo()
}