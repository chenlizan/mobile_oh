import _ from '@wolfx/lodash'
import { CustomToast, judgeGroupIsEnd, judgeRoleIsSpecial, PreferenceStorage, UserInfoModel } from '@xy/basic'
import { CustomLocalH5, Toolkits } from './CustomLocalH5'
import { KnowledgeBar } from './KnowledgeBar'

class QuestionToolkits extends Toolkits {
  onRefreshTask() {
    CustomToast.toast_fail('onRefreshTask 没实现')
  }

  onRefreshResource() {
    CustomToast.toast_fail('onRefreshResource 没实现')
  }

  onChangeKnowledgeStatus() {
    CustomToast.toast_fail('onChangeKnowledgeStatus 没实现')
  }
}

@Component
struct QuestionResource {
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @StorageLink('PreferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage()
  @StorageLink('UserInfo') userInfo: UserInfoModel = new UserInfoModel()
  @State knowledgePickerVisible: boolean = false
  private param: Record<string, string | number | boolean | Record<string, string>> = {}

  aboutToAppear(): void {
    this.param = JSON.parse(String(this.pageInfos.getParamByName('questionResource')[0]))
  }

  getUrlPath() {
    const item = this.param.item as Record<string, string>
    const loginRole = this.param.loginRole
    const isSub = this.param.isSub
    const isDocument = this.param.isDocument
    const currentTeam = this.preferenceStorage.currentTeam

    let path = `#/paper_mobile/exam/info/student/course/${null}/${
    item.paper_id
    }/${item.id}/${item.group_id}`
    if (loginRole !== 1 || isSub || isDocument) {
      path = `#/paper_mobile/exam/info/teacher/${null}/${item.paper_id}/${
      item.id
      }/${item.group_id}`
    }

    path += `?site_id=${currentTeam?.site_id ?? ''}`

    if (currentTeam?.course_property === '2') {
      path += '&isMooc=1'
    }

    return path
  }

  injectedExtraJavaScript = () => {
    const loginRole = this.param.loginRole as number
    const currentTeam = this.preferenceStorage.currentTeam

    let extra = ''
    if (loginRole === 1) {
      extra += 'window.isStudent=true'
    } else if (loginRole === 2) {
      extra += 'window.isAssistant=true'
    } else if (loginRole === 7) {
      extra += 'window.isVisit=true'
    } else if (judgeRoleIsSpecial(loginRole)) {
      extra += 'window.isSpecial=true'
    }

    if (this.userInfo.isSchoolFellow) {
      extra += 'window.isSchoolFellow=true'
    }

    if (currentTeam?.course_property === '2') {
      extra += 'window.isMooc=true'
    }

    let _siteId = ''
    let _courseEnd = ''
    if (!_.isEmpty(currentTeam)) {
      _siteId = `window.site_id="${currentTeam?.site_id}"`
      _courseEnd = `window.courseEnd=${judgeGroupIsEnd(currentTeam as Record<string, string>, false)}`
    }

    return `${_siteId}${_courseEnd}${extra}`
  }

  build() {
    NavDestination() {
      Flex({ direction: FlexDirection.Column }) {
        CustomLocalH5({
          url: this.getUrlPath(),
          extraJavaScript: this.injectedExtraJavaScript(),
          toolkits: new QuestionToolkits()
        })
        KnowledgeBar({ item: this.param.item as Record<string, string> })
      }
    }
    .hideTitleBar(true)
  }
}

@Builder
export function QuestionResourceBuilder() {
  QuestionResource()
}