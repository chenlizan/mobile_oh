import _ from '@wolfx/lodash'
import { Api_Context, CustomLocalH5, judgeRoleHasCourseOperationWeight, UserInfoModel } from '@xy/basic'

@Component
struct NoteRecourse {
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @StorageLink('UserInfo') userInfo: UserInfoModel = new UserInfoModel()
  private param: Record<string, string | number | boolean | Record<string, string>> = {}

  aboutToAppear(): void {
    this.param = JSON.parse(String(this.pageInfos.getParamByName('noteRecourse')[0]))
  }

  getUrlPath() {
    const item = this.param.item as Record<string, string>
    const loginRole = this.param.loginRole
    const isSub = this.param.isSub
    const isCourse = this.param.isCourse
    const isDocument = this.param.isDocument
    const fromBridge = this.param.fromBridge

    let path = '';
    const canEdit = judgeRoleHasCourseOperationWeight(loginRole as number);
    if (isCourse) {
      path = `#/note?node_id=${item.id}&group_id=${item.group_id}&type=${
      isSub ? 'subgroup' : 'course'
      }&mode=${(isSub && !item?.from_share) || canEdit ? 'edit' : 'preview'}`;
    } else if (fromBridge) {
      path = `#/note?node_id=${item.id}&group_id=${
      item.group_id
      }&type=course&mode=${canEdit ? 'edit' : 'preview'}`;
    } else if (isDocument) {
      if (item?.shared_from_type) {
        path = `#/note?node_id=${item.root_node_id}&resource_id=${
        item.id
        }&group_id=${null}&type=shared&mode=preview&user_id=${this.userInfo.id}`;
      } else {
        path = `#/note?node_id=${item.id}&resource_id=${
        item.id
        }&group_id=${null}&type=document&mode=edit`;
      }
    }
    return path;
  }

  build() {
    NavDestination() {
      CustomLocalH5({
        url: this.getUrlPath()
      })
    }
    .hideTitleBar(true)
  }
}

@Builder
export function NoteRecourseBuilder() {
  NoteRecourse()
}