import _ from '@wolfx/lodash'
import qs from '@open/qs'
import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit'
import { webview } from '@kit.ArkWeb'
import { BusinessError } from '@kit.BasicServicesKit'
import { CustomToast, navigateToResourceDetails, PreferenceStorage, RouterConstants } from '../../../../Index'

export class Toolkits {
  onGoBack() {
    const pageInfos = AppStorage.get<NavPathStack>('pageInfos')
    pageInfos?.pop()
  }

  onTokenInvalid() {
    const pageInfos = AppStorage.get<NavPathStack>('pageInfos')
    const preferenceStorage = AppStorage.get<PreferenceStorage>('PreferenceStorage')
    if (preferenceStorage) {
      preferenceStorage.access_token = undefined
      preferenceStorage.refresh_token = undefined
      AppStorage.set<PreferenceStorage>('PreferenceStorage', preferenceStorage)
    }
    CustomToast.toast_fail('登录已失效或账号在其他移动设备上登录，请重新登录')
    setTimeout(() => {
      pageInfos?.clear()
      AppStorage.set<string>('globalPageIndex', RouterConstants.LOGIN_PAGE_URL)
    }, 1500)
  }

  onCheckMicroPhonePermission() {
    return true
  }

  onOpenSystemSetting() {
    const context = getContext(this) as common.UIAbilityContext
    context.startAbility({
      bundleName: 'com.huawei.hmos.settings',
      abilityName: 'com.huawei.hmos.settings.MainAbility',
      uri: 'application_info_entry',
      parameters: {
        pushParams: context.abilityInfo.bundleName
      }
    })
  }

  onShowTeachDesign(dataSource: Record<string, string>) {
    const pageInfos = AppStorage.get<NavPathStack>('pageInfos')
    pageInfos?.pushPath({
      name: 'teachDesignRecourse',
      param: JSON.stringify({
        item: dataSource,
        loginRole: dataSource.role ? parseInt(dataSource.role, 10) : 1,
        fromBridge: dataSource.from !== 'area',
        isCourse: dataSource.from === 'area',
        isSub: false,
      })
    })
  }
}

@Component
export struct CustomLocalH5 {
  @StorageLink('PreferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage()
  @Prop toolkits: Toolkits | null = null
  @Prop extraJavaScript: string = ''
  @Prop url: string = ''
  controller: webview.WebviewController = new webview.WebviewController()

  getLrsHeader() {
    this.preferenceStorage.access_token = undefined
    return ({
      'x-lrs-device': ``,
      'x-lrs-domain': ``,
      'x-lrs-application': ``,
    } as Record<string, string>)
  }

  getJavaScript() {
    const access_token = this.preferenceStorage.access_token
    const refresh_token = this.preferenceStorage.refresh_token
    const access_group_token = this.preferenceStorage.access_group_token
    const lrs_headers = JSON.stringify(this.getLrsHeader())
    return `window.localStorage.setItem('refresh_token','${refresh_token}')
    window.localStorage.setItem('access_token','${access_token}')
    window.localStorage.setItem('access_group_token','${access_group_token ?? ''}')
    ${_.trim(this.extraJavaScript) ? this.extraJavaScript : ''}
    window.localStorage.setItem('lrs_headers','${lrs_headers}')`
  }

  @State scripts: Array<ScriptItem> = [
    { script: this.getJavaScript(), scriptRules: ['*'] }
  ]

  aboutToAppear() {
    webview.WebviewController.setWebDebuggingAccess(true)
    const queryParams: Record<string, string | number | undefined> = {}
    queryParams.school_code = this.preferenceStorage.school?.code
    queryParams.school_domain = this.preferenceStorage.school?.domain
    this.url += `&${qs.stringify(queryParams)}`
  }

  build() {
    Column() {
      Web({
        // src: 'resource://rawfile/localh5/index.html' + this.url,
        src: $rawfile('test.html'),
        controller: this.controller,
      })
        .domStorageAccess(true)
        .fileAccess(true)
        .javaScriptOnDocumentStart(this.scripts)
        .javaScriptProxy({
          object: this.toolkits ? this.toolkits : new Toolkits(),
          name: 'Toolkits',
          methodList: ['onGoBack', 'onTokenInvalid', 'onCheckMicroPhonePermission', 'onOpenSystemSetting'],
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
  let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager()
  let permissions: Array<Permissions> = ['ohos.permission.MICROPHONE', 'ohos.permission.CAMERA']
  atManager.requestPermissionsFromUser(context, permissions).then((data) => {
    let grantStatus: Array<number> = data.authResults
    let length: number = grantStatus.length
    for (let i = 0; i < length; i++) {
      if (grantStatus[i] === 0) {
        permissionResult(true)
      } else {
        permissionResult(false)
        return
      }
    }
  }).catch((err: BusinessError) => {
    permissionResult(false)
    console.error(`Failed to request permissions from user. Code is ${err.code}, message is ${err.message}`)
  })
}