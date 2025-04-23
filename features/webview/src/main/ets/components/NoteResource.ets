import _ from '@wolfx/lodash'
import { AppIcon, CustomNavTitle, IconConstants, judgeRoleHasCourseOperationWeight, UserInfoModel } from '@xy/basic'
import { CustomLocalH5 } from './CustomLocalH5'
import { webview } from '@kit.ArkWeb'
import { KnowledgeBar } from './KnowledgeBar'
import { TaskFinishItem } from './TaskFinishItem'
import { display } from '@kit.ArkUI'

@Component
struct NoteResource {
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @StorageLink('UserInfo') userInfo: UserInfoModel = new UserInfoModel()
  @State controller: webview.WebviewController = new webview.WebviewController()
  @State screenWidth: number = 0
  @State screenHeight: number = 0
  private param: Record<string, string | number | boolean | Record<string, string>> = {}

  aboutToAppear(): void {
    this.param = JSON.parse(String(this.pageInfos.getParamByName('noteResource')[0]))
    this.screenWidth = px2vp(display.getDefaultDisplaySync().width)
    this.screenHeight = px2vp(display.getDefaultDisplaySync().height)
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

  @Builder
  BuildNavRightBtn() {
    Row() {
      AppIcon({
        iconCode: IconConstants.REFRESH,
        iconColor: '#999999',
        iconSize: 16,
        iconMargin: { right: 10 },
        onClickBtn: () => {
          this.controller.refresh()
        }
      })
    }
  }

  build() {
    NavDestination() {
      Flex({ direction: FlexDirection.Column }) {
        CustomLocalH5({
          url: this.getUrlPath(),
          controller: this.controller
        })
        if (!this.param.isSub && !this.param.isDocument && !this.param.fromBridge) {
          KnowledgeBar({ item: this.param.item as Record<string, string>, loginRole: this.param.loginRole as number })
        }
      }

      if (this.param.showFinish) {
        TaskFinishItem({
          imgOffSetX: this.screenWidth - 70,
          imgOffSetY: this.screenHeight - 260,
          isSub: this.param.isSub as boolean,
          item: this.param.item as Record<string, string>
        })
      }
    }
    .title(CustomNavTitle((this.param.item as Record<string, string>).name, () => this.BuildNavRightBtn()))
  }
}

@Builder
export function NoteResourceBuilder() {
  NoteResource()
}