import _ from '@wolfx/lodash';
import qs from '@open/qs'
import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { webview } from '@kit.ArkWeb';
import { BusinessError } from '@kit.BasicServicesKit';
import { CustomToast, PreferenceStorage } from '../../../../Index';

class Toolkits {
  onGoBack() {
    CustomToast.toast_success('onGoBack')
  }
}

@Component
export struct CustomLocalH5 {
  @StorageLink('PreferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage();
  @State toolkits: Toolkits = new Toolkits()
  @State extraJavaScript: string = ''
  @Prop url: string = ''
  controller: webview.WebviewController = new webview.WebviewController();

  getLrsHeader() {
    return ({
      'x-lrs-device': ``,
      'x-lrs-domain': ``,
      'x-lrs-application': ``,
    } as Record<string, string>);
  }

  getJavaScript() {
    const access_token = this.preferenceStorage.access_token
    const refresh_token = this.preferenceStorage.refreshToken
    const lrs_headers = JSON.stringify(this.getLrsHeader());
    return `window.localStorage.setItem('refresh_token','${refresh_token}');
    window.localStorage.setItem('access_token','${access_token}');
    window.localStorage.setItem('access_group_token','${
    'global?.access_group_token ' ?? ''
    }');
    ${_.trim(this.extraJavaScript) ? this.extraJavaScript : ''};
    window.localStorage.setItem('lrs_headers','${lrs_headers}');`;
  }

  @State scripts: Array<ScriptItem> = [
    { script: this.getJavaScript(), scriptRules: ["*"] }
  ];

  aboutToAppear() {
    // webview.WebviewController.setWebDebuggingAccess(true);
    const queryParams: Record<string, string | number | undefined> = {}
    queryParams.school_code = this.preferenceStorage.school?.code
    queryParams.school_domain = this.preferenceStorage.school?.domain
    this.url += `&${qs.stringify(queryParams)}`
  }

  build() {
    Column() {
      Web({
        src: 'resource://rawfile/localh5/index.html#' + this.url,
        controller: this.controller,
        incognitoMode: true
      })
        .domStorageAccess(true)
        .fileAccess(true)
        .javaScriptOnDocumentStart(this.scripts)
        .javaScriptProxy({
          object: this.toolkits,
          name: "Toolkits",
          methodList: ["onGoBack",],
          controller: this.controller,
        })
        .onPermissionRequest((event) => {
          if (event) {
            requestMicrophonePermission(getContext() as common.UIAbilityContext, (result: boolean) => {
              if (result) {
                event.request.grant(event.request.getAccessibleResource())
              } else {
                event.request.deny()
              }
            })
          }
        })
        .width('100%')
        .height('100%')
    }
  }
}

function requestMicrophonePermission(context: common.UIAbilityContext,
  permissionResult: (allow: boolean) => void): void {
  let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
  let permissions: Array<Permissions> = ['ohos.permission.MICROPHONE', 'ohos.permission.CAMERA'];
  atManager.requestPermissionsFromUser(context, permissions).then((data) => {
    let grantStatus: Array<number> = data.authResults;
    let length: number = grantStatus.length;
    for (let i = 0; i < length; i++) {
      if (grantStatus[i] === 0) {
        permissionResult(true);
      } else {
        permissionResult(false);
        return;
      }
    }
  }).catch((err: BusinessError) => {
    permissionResult(false);
    console.error(`Failed to request permissions from user. Code is ${err.code}, message is ${err.message}`);
  })
}