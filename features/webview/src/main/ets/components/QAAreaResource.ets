import _ from '@wolfx/lodash'
import { judgeGroupIsEnd, PreferenceStorage, UserInfoModel } from '@xy/basic'
import { CustomLocalH5 } from './CustomLocalH5'

@Component
struct QAAreaResource {
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @StorageLink('PreferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage()
  @StorageLink('UserInfo') userInfo: UserInfoModel = new UserInfoModel()
  private param: Record<string, string | number | boolean | Record<string, string>> = {}

  aboutToAppear(): void {
    this.param = JSON.parse(String(this.pageInfos.getParamByName('qaAreaResource')[0]))
  }

  getUrlPath() {
    const item = this.param.item as Record<string, string>
    const loginRole = this.param.loginRole
    const currentTeam = this.preferenceStorage.currentTeam

    let path = '';
    if (!!item && loginRole === 1) {
      path = `#/paper_mobile/dayi/add/${currentTeam?.id}/${loginRole}`;
    } else {
      path = `#/paper_mobile/dayi/list/${currentTeam?.id}/${loginRole}`;
    }

    path += `?user_id=${this.userInfo.id}`;

    if (item) {
      path += `&node_id=${item?.id}&survey_question_id=${item?.question_id}`;
    }

    return path;
  }

  injectedExtraJavaScript = () => {
    const currentTeam = this.preferenceStorage.currentTeam
    let extra = '';
    let _siteId = '';
    let _courseEnd = '';
    if (!_.isEmpty(currentTeam)) {
      _siteId = `window.site_id="${currentTeam?.site_id}";`;
      _courseEnd = `window.courseEnd=${judgeGroupIsEnd(currentTeam as Record<string, string>, false)};`;
    }
    return `${_siteId}${_courseEnd}${extra}`;
  }

  build() {
    NavDestination() {
      CustomLocalH5({
        url: this.getUrlPath(),
        extraJavaScript: this.injectedExtraJavaScript(),
      })
    }
    .hideTitleBar(true)
  }
}

@Builder
export function QAAreaResourceBuilder() {
  QAAreaResource()
}