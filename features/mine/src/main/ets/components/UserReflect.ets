import _ from '@wolfx/lodash'
import { webview } from '@kit.ArkWeb'
import { CustomNavTitle, PreferenceStorage, } from '@xy/basic'

@Component
struct UserReflect {
  @StorageLink('PreferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage();
  @State source_url: string = ''
  controller: webview.WebviewController = new webview.WebviewController();

  aboutToAppear(): void {
    this.getReflectUrl()
  }

  getReflectUrl() {
    const configCenter = AppStorage.get<PreferenceStorage>('PreferenceStorage')?.configCenter
    this.source_url = _.find(configCenter, { key: 'feedback_questionnaire_url' })?.value ?? ''
  }

  build() {
    NavDestination() {
      Web({
        src: this.source_url,
        controller: this.controller
      })
    }
    .title(CustomNavTitle('反馈&建议'))
    .backgroundColor("#f1f1f1")
  }
}

@Builder
export function UserReflectBuilder() {
  UserReflect()
}