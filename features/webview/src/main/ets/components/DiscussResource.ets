import _ from '@wolfx/lodash'
import { CustomToast, judgeGroupIsEnd, PreferenceStorage, UserInfoModel } from '@xy/basic'
import { CustomLocalH5, Toolkits } from './CustomLocalH5'
import { KnowledgeBar } from './KnowledgeBar'
import { webview } from '@kit.ArkWeb'

class DiscussToolkits extends Toolkits {
  onGetKeyboardSpace() {
    return 0
  }

  onRefreshTask() {
    // 改变的缓存数据
    CustomToast.toast_fail('onRefreshTask 没实现')
  }
}

@Component
struct DiscussResource {
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @StorageLink('PreferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage()
  @StorageLink('UserInfo') userInfo: UserInfoModel = new UserInfoModel()
  @State controller: webview.WebviewController = new webview.WebviewController()
  private param: Record<string, string | number | boolean | Record<string, string>> = {}

  aboutToAppear(): void {
    this.param = JSON.parse(String(this.pageInfos.getParamByName('discussResource')[0]))
  }

  getUrlPath() {
    const item = this.param.item as Record<string, string>
    const loginRole = this.param.loginRole
    const isSub = this.param.isSub
    const currentTeam = this.preferenceStorage.currentTeam

    let path = `#/paper_mobile/discuss/${item.group_id}/${item.id}/${item.quote_id}`
    if (isSub) {
      path = `#/paper_mobile/discuss/${item.group_id}/${item.id}/${item.quote_id}/${item.subgroup_id}`
    }
    if (currentTeam?.course_property === '2') {
      path = `#/paper_mobile/mooc/discuss/${item.group_id}/${item.id}/${item.quote_id}`
    }

    path += `?role=${loginRole}&user_id=${this.userInfo.id}`
    return path
  }

  injectedExtraJavaScript = () => {
    const currentTeam = this.preferenceStorage.currentTeam

    let extra = ''
    if (!_.isEmpty(currentTeam)) {
      extra += `window.site_id="${currentTeam?.site_id}"`

      extra += `window.courseEnd=${judgeGroupIsEnd(currentTeam as Record<string, string>, false)}`
    }

    if (this.userInfo.isSchoolFellow) {
      extra += 'window.isSchoolFellow=true'
    }
    return `${extra}`
  }

  build() {
    NavDestination() {
      Flex({ direction: FlexDirection.Column }) {
        CustomLocalH5({
          url: this.getUrlPath(),
          extraJavaScript: this.injectedExtraJavaScript(),
          toolkits: new DiscussToolkits(),
          controller: this.controller
        })
        if (!this.param.isSub && !this.param.fromBridge) {
          KnowledgeBar({ item: this.param.item as Record<string, string>, loginRole: this.param.loginRole as number })
        }
      }
    }
    .hideTitleBar(true)
  }
}

@Builder
export function DiscussResourceBuilder() {
  DiscussResource()
}