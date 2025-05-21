import { webview } from '@kit.ArkWeb'
import { Api_Context, CustomModalDialog, CustomNavTitle, PreferenceStorage, UserInfoModel } from '@xy/basic'

@Component
struct UserReport {
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @StorageLink('PreferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage()
  @StorageLink('UserInfo') userInfo: UserInfoModel = new UserInfoModel()
  @State source_url: string = ''
  @State title: string = '选择学校'
  @State visible: boolean = false
  controller: webview.WebviewController = new webview.WebviewController()

  aboutToAppear(): void {
    const schools = this.userInfo.schools
    if (schools.length > 1) {
      setTimeout(() => {
        this.visible = true
      }, 500)
    } else {
      this.source_url = this.getReportUrl()
    }
  }

  getReportUrl(schoolId: string | undefined = this.preferenceStorage.school?.id) {
    const access_token = this.preferenceStorage.access_token
    return `${this.Api_Context.getApiPrefix('hostApi')}/app/jx-report-2024/index.html?school_id=${schoolId}&xy_bearer=${access_token}`
  }

  @Builder
  buildContent(): void {
    Column() {
      Text(`您有${this.userInfo.schools.length}份用户年报，请选择要查看的`)
        .padding(8)
        .fontColor('#999999')
      ForEach(this.userInfo.schools, (school: Record<string, Record<string, string>>) => {
        Button(school.schoolInfo?.schoolName, { type: ButtonType.Normal })
          .buttonStyle(ButtonStyleMode.TEXTUAL)
          .onClick(() => {
            this.visible = false
            this.controller.loadUrl(this.getReportUrl(school.schoolInfo?.id))
          })
      })
      Button('退出', { type: ButtonType.Normal })
        .buttonStyle(ButtonStyleMode.TEXTUAL)
        .onClick(() => {
          this.visible = false
          this.pageInfos.pop()
        })
    }
    .width('100%')
  }

  build() {
    NavDestination() {
      Web({
        src: this.source_url,
        controller: this.controller
      })

      CustomModalDialog({
        visible: $visible,
        title: this.title,
        hideCloseBtn: Visibility.Hidden,
        contentBuilder: () => this.buildContent()
      })
    }
    .title(CustomNavTitle('个人年度报告'))
    .backgroundColor("#f1f1f1")
  }
}

@Builder
export function UserReportBuilder() {
  UserReport()
}