import { ComponentContent, window } from "@kit.ArkUI"
import { AppIcon } from "./AppIcon"
import { IconConstants } from "../constants/IconConstants"

export class AlertDialogParam {
  message: string = ''
  title: string = ''
  dialogHeight: Length = 0
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
        Text(params.title)
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
            if (params.onCloseBtn) {
              params.onCloseBtn()
            }
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
          if (params.onCloseBtn) {
            params.onCloseBtn()
          }
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
          if (params.onClickBtn) {
            params.onClickBtn()
          }
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

export async function CustomAlertDialog(params: AlertDialogParam) {
  const windowClass = await window.getLastWindow(getContext())
  const uiContext = windowClass.getUIContext()
  const customDialog = new ComponentContent(uiContext, wrapBuilder(AlertDialogComponent), params)
  const promptAction = uiContext.getPromptAction()
  params.hide = () => {
    if (promptAction && customDialog) {
      promptAction.closeCustomDialog(customDialog)
      customDialog.dispose()
    }
  }
  promptAction.openCustomDialog(customDialog, { autoCancel: params.autoCancel || false })
}