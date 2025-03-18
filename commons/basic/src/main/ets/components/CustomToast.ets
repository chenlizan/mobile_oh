import { ComponentContent, PromptAction, window } from "@kit.ArkUI";
import { AppIcon } from "./AppIcon";
import { IconConstants } from "../constants/IconConstants";

interface ToastParam {
  message?: string
  icon?: IconConstants
}

@Builder
function customDialogComponent(param: ToastParam) {
  Column() {
    if (param.icon === IconConstants.LOADING) {
      LoadingProgress()
        .color(Color.White)
        .size({ width: 50, height: 50 })
    } else if (param.icon !== null) {
      AppIcon({
        iconCode: param.icon,
        iconColor: Color.White,
        iconSize: 32
      })
    }
    Text(param.message)
      .margin({ top: param.icon ? param.icon === IconConstants.LOADING ? 8 : 16 : 0 })
      .fontColor(Color.White)
      .fontSize(16)
  }
  .width(120)
  .height(120)
  .justifyContent(FlexAlign.Center)
  .backgroundColor('#b2000000')
  .borderRadius(8)
}

class Toast {
  private promptAction: PromptAction | null = null
  private customDialog: ComponentContent<ToastParam> | null = null

  private async show(message?: string, icon?: IconConstants, autoCancel: boolean = true) {
    const params: ToastParam = { message, icon: icon }
    const windowClass = await window.getLastWindow(getContext())
    const uiContext = windowClass.getUIContext()
    this.customDialog = new ComponentContent(uiContext, wrapBuilder(customDialogComponent), params)
    this.promptAction = uiContext.getPromptAction()
    this.promptAction.openCustomDialog(this.customDialog, { autoCancel: autoCancel })
    if (icon !== IconConstants.LOADING) {
      setTimeout(() => {
        this.hide()
      }, 1500)
    }
  }

  public hide() {
    if (this.promptAction && this.customDialog) {
      this.promptAction.closeCustomDialog(this.customDialog)
      this.customDialog.dispose()
    }
  }

  public toast_success(message: string) {
    this.show(message, IconConstants.AGREE)
  }

  public toast_fail(message: string) {
    this.show(message, IconConstants.CLOSE)
  }

  public toast_info(message: string) {
    this.show(message)
  }

  public toast_loading(message: string) {
    this.show(message, IconConstants.LOADING, false)
  }
}

export const CustomToast = new Toast
