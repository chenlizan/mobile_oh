import _ from '@wolfx/lodash'
import { CustomLocalH5, CustomToast, judgeGroupIsEnd, PreferenceStorage, Toolkits, UserInfoModel } from '@xy/basic'

class DiscussToolkits extends Toolkits {
  onGetKeyboardSpace() {
    CustomToast.toast_fail('onGetKeyboardSpace 没实现')
  }

  onRefreshTask() {
    CustomToast.toast_fail('onRefreshTask 没实现')
  }
}

@Component
struct DiscussResource {
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @StorageLink('PreferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage()
  @StorageLink('UserInfo') userInfo: UserInfoModel = new UserInfoModel()
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
      CustomLocalH5({
        url: this.getUrlPath(),
        extraJavaScript: this.injectedExtraJavaScript(),
        toolkits: new DiscussToolkits()
      })
    }
    .hideTitleBar(true)
  }
}

@Builder
export function DiscussResourceBuilder() {
  DiscussResource()
}