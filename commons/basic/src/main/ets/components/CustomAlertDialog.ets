import { ComponentContent, PromptAction, window } from "@kit.ArkUI"
import { AppIcon } from "./AppIcon"
import { IconConstants } from "../constants/IconConstants"

export class AlertDialogParam {
  message: string = '警告'
  title: string = ''
  dialogHeight: Length = 180
  autoCancel: boolean = false
  hideCloseBtn: Visibility = Visibility.Visible
  hideDivider: Visibility = Visibility.Visible
  onCloseBtn: () => void = () => {
  }
  onClickBtn: () => void = () => {
  }
  hide: () => void = () => {
  }
}

@Builder
function AlertDialogComponent(params: AlertDialogParam) {
  Flex({ direction: FlexDirection.Column }) {
    RelativeContainer() {
      Row() {
        Text(params.title || '警告')
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)

      Row() {
        AppIcon({
          iconCode: IconConstants.CLOSE,
          iconSize: 20,
          iconColor: '#999999',
          onClickBtn: () => {
            params.onCloseBtn()
            params.hide()
          }
        })
          .visibility(params.hideCloseBtn)
      }
      .alignRules({
        top: { anchor: "__container__", align: VerticalAlign.Top },
        right: { anchor: "__container__", align: HorizontalAlign.End },
      })
      .padding({ top: 12, right: 12 })
    }
    .flexBasis(42)
    .height(42)

    Row() {
      Row() {
      }
      .height(1)
      .borderWidth({ top: 1 })
      .layoutWeight(1)
      .borderColor('#33999999')
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
    .alignItems(VerticalAlign.Center)
    .visibility(params.hideDivider)

    Column() {
      Text(params.message)
        .padding(12)
        .fontColor('#999999')
    }
    .flexGrow(1)
    .justifyContent(FlexAlign.Center)
    .width('100%')

    Row() {
      Button('取消', { type: ButtonType.Normal })
        .height(40)
        .fontColor('#999999')
        .backgroundColor(Color.White)
        .borderWidth({ top: 1 })
        .borderColor('#33999999')
        .borderRadius({
          topLeft: 0,
          topRight: 0,
          bottomLeft: 8,
          bottomRight: 0
        })
        .flexGrow(1)
        .onClick(() => {
          params.onCloseBtn()
          params.hide()
        })
      Button('确定', { type: ButtonType.Normal })
        .height(40)
        .backgroundColor('#40A9FF')
        .borderWidth({ top: 1 })
        .borderColor('#40A9FF')
        .borderRadius({
          topLeft: 0,
          topRight: 0,
          bottomLeft: 0,
          bottomRight: 8
        })
        .flexGrow(1)
        .onClick(() => {
          params.onClickBtn()
          params.hide()
        })
    }
    .width('100%')

  }
  .height(params.dialogHeight || 180)
  .margin(48)
  .borderRadius(8)
  .backgroundColor(Color.White)
}

export class CustomAlertDialog {
  private promptAction: PromptAction | null = null
  private customDialog: ComponentContent<AlertDialogParam> | null = null

  constructor(params: AlertDialogParam) {
    this.show(params)
  }

  private async show(params: AlertDialogParam) {
    params.hide = (): void => this.hide()
    const windowClass = await window.getLastWindow(getContext())
    const uiContext = windowClass.getUIContext()
    this.customDialog = new ComponentContent(uiContext, wrapBuilder(AlertDialogComponent), params)
    this.promptAction = uiContext.getPromptAction()
    this.promptAction.openCustomDialog(this.customDialog, { autoCancel: params.autoCancel })
  }

  private hide() {
    if (this.promptAction && this.customDialog) {
      this.promptAction.closeCustomDialog(this.customDialog)
      this.customDialog.dispose()
    }
  }
}