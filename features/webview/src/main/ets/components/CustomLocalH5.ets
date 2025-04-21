import _ from '@wolfx/lodash'
import qs from '@open/qs'
import { webview } from '@kit.ArkWeb'
import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
import {
  Api_Context,
  CustomToast,
  getLrsTraceElement,
  PreferenceStorage,
  RouterConstants,
  SystemApi,
  xyApiPost
} from '@xy/basic/Index'
import { display } from '@kit.ArkUI'

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

  async onRecodeLrsTrace(dataSource: Record<string, string>) {
    const Api_Context = AppStorage.get<Api_Context>('Api_Context')
    const body = getLrsTraceElement(dataSource);
    if (_.isEmpty(body)) {
      return;
    }
    await xyApiPost(Api_Context?.getApiPrefix('lrsApi') + SystemApi.buriedTrack, body)
  }

  onGetLrsHeader() {
    return ({
      'x-lrs-device': ``,
      'x-lrs-domain': ``,
      'x-lrs-application': ``,
    } as Record<string, string>)
  }

  onShowTeachDesign(dataSource: Record<string, string>) {
    const pageInfos = AppStorage.get<NavPathStack>('pageInfos')
    pageInfos?.pushPath({
      name: 'teachDesignResource',
      param: JSON.stringify({
        item: dataSource,
        loginRole: dataSource.role ? parseInt(dataSource.role, 10) : 1,
        ccc: dataSource.from !== 'area',
        isCourse: dataSource.from === 'area',
        isSub: false,
      })
    })
  }

  onOpenWebview(dataSource: Record<string, string>) {
    const pageInfos = AppStorage.get<NavPathStack>('pageInfos')
    pageInfos?.pushPath({
      name: 'h5Resource',
      param: JSON.stringify({
        hideNav: dataSource.hideNav,
        isLocal: dataSource.isLocal,
        source_url: dataSource.url,
        title: dataSource.title,
      })
    })
  }

  onOpenRobot(dataSource: Record<string, string>) {
    CustomToast.toast_fail('onOpenRobot 没实现')
  }

  onShowQAArea(dataSource: Record<string, string>) {
    const pageInfos = AppStorage.get<NavPathStack>('pageInfos')
    pageInfos?.pushPath({
      name: 'qaAreaResource',
      param: JSON.stringify({
        item: dataSource,
        loginRole: dataSource.role ? parseInt(dataSource.role, 10) : 1,
      })
    })
  }

  onShowPaper(dataSource: Record<string, string>) {
    const pageInfos = AppStorage.get<NavPathStack>('pageInfos')
    pageInfos?.pushPath({
      name: 'questionResource',
      param: JSON.stringify({
        item: dataSource,
        loginRole: dataSource.role ? parseInt(dataSource.role, 10) : 1,
        fromBridge: dataSource.from !== 'area',
        isCourse: dataSource.from === 'area',
      })
    })
  }

  onShowNote(dataSource: Record<string, string>) {
    const pageInfos = AppStorage.get<NavPathStack>('pageInfos')
    pageInfos?.pushPath({
      name: 'noteResource',
      param: JSON.stringify({
        item: dataSource,
        loginRole: dataSource.role ? parseInt(dataSource.role, 10) : 1,
        fromBridge: dataSource.from !== 'area',
        isCourse: dataSource.from === 'area',
        showFinish: !!dataSource.is_assigned,
      })
    })
  }

  onShowMindMap(dataSource: Record<string, string>) {
    const pageInfos = AppStorage.get<NavPathStack>('pageInfos')
    pageInfos?.pushPath({
      name: 'mindMapResource',
      param: JSON.stringify({
        item: dataSource,
        loginRole: dataSource.role ? parseInt(dataSource.role, 10) : 1,
        fromBridge: dataSource.from !== 'area',
        isCourse: dataSource.from === 'area',
        showFinish: !!dataSource.is_assigned,
      })
    })
  }

  onShowDiscuss(dataSource: Record<string, string>) {
    const pageInfos = AppStorage.get<NavPathStack>('pageInfos')
    pageInfos?.pushPath({
      name: 'discussResource',
      param: JSON.stringify({
        item: dataSource,
        loginRole: dataSource.role ? parseInt(dataSource.role, 10) : 1,
        fromBridge: dataSource.from !== 'area',
        isCourse: dataSource.from === 'area',
      })
    })
  }

  onShowCode(dataSource: Record<string, string>) {
    const pageInfos = AppStorage.get<NavPathStack>('pageInfos')
    pageInfos?.pushPath({
      name: 'codeResource',
      param: JSON.stringify({
        item: dataSource,
        loginRole: dataSource.role ? parseInt(dataSource.role, 10) : 1,
        fromBridge: dataSource.from !== 'area',
        isCourse: dataSource.from === 'area',
        showFinish: !!dataSource.is_assigned,
      })
    })
  }

  onShowImage(dataSource: Record<string, string>) {
    CustomToast.toast_fail('onShowImage 没实现')
  }

  onShowVideo(dataSource: Record<string, string>) {
    CustomToast.toast_fail('onShowVideo 没实现')
  }

  onShowAudio(dataSource: Record<string, string>) {
    CustomToast.toast_fail('onShowAudio 没实现')
  }

  onShowOffice(dataSource: Record<string, string>) {
    CustomToast.toast_fail('onShowOffice 没实现')
  }
}

@Component
export struct CustomLocalH5 {
  @StorageLink('PreferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage()
  @Prop controller: webview.WebviewController = new webview.WebviewController()
  @Prop toolkits: Toolkits | null = null
  @Prop extraJavaScript: string = ''
  @Prop url: string = ''
  @Prop isLocal: boolean = true
  @State screenHeight: number = 0
  @State scripts: Array<ScriptItem> = [
    { script: this.getJavaScript(), scriptRules: ['*'] }
  ]

  getLrsHeader() {
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

  aboutToAppear() {
    this.screenHeight = px2vp(display.getDefaultDisplaySync().height)
    webview.WebviewController.setWebDebuggingAccess(true)
    const queryParams: Record<string, string | number | undefined> = {}
    queryParams.school_code = this.preferenceStorage.school?.code
    queryParams.school_domain = this.preferenceStorage.school?.domain
    this.url += `&${qs.stringify(queryParams)}`
  }

  build() {
    Column() {
      Web({
        src: this.isLocal ? 'resource://rawfile/localh5/index.html' + this.url : this.url,
        // src: $rawfile('test.html'),
        controller: this.controller,
      })
        .domStorageAccess(true)
        .fileAccess(true)
        .javaScriptOnDocumentStart(this.scripts)
        .javaScriptProxy({
          object: this.toolkits ? this.toolkits : new Toolkits(),
          name: 'Toolkits',
          methodList: ['onGoBack', 'onTokenInvalid', 'onCheckMicroPhonePermission', 'onOpenSystemSetting',
            'onShowTeachDesign', 'onShowQAArea', 'onShowMindMap', 'onShowNote', 'onShowDiscuss', 'onShowPaper',
            'onShowCode', 'onShowOffice', 'onShowImage', 'onShowAudio', 'onShowVideo', 'onRecodeLrsTrace',
            'onGetLrsHeader'],
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
        .onControllerAttached(() => {
          CustomToast.toast_loading('')
        })
        .onPageEnd(() => {
          CustomToast.hide()
        })
        .width('100%')
        .flexGrow(1)
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