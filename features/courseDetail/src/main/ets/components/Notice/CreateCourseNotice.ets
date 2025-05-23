import _ from "@wolfx/lodash"
import {
  Api_Context,
  CustomNavTitle,
  CustomToast,
  HomeApi,
  judgeGroupIsEnd,
  PreferenceStorage,
  xyApiPost,
  xyApiPut
} from "@xy/basic"

@Component
struct CreateCourseNotice {
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @StorageLink('PreferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage()
  private courseInfo = this.preferenceStorage.currentTeam ?? {}
  private param: Record<string, string> = {}
  private content: string = ''

  build() {
    NavDestination() {
      Flex({ direction: FlexDirection.Column }) {
        TextArea({ placeholder: '请输入公告...' })
          .placeholderColor('#999999')
          .height(250)
          .borderRadius(4)
          .border({ color: '#d9d9d9', width: 1 })
          .backgroundColor(Color.White)
          .onChange((text: string) => {
            this.content = text
          })

        Button('发布', { type: ButtonType.Normal })
          .width('100%')
          .margin({ top: 20 })
          .backgroundColor('#41A9FF')
          .borderRadius(4)
          .fontColor(Color.White)
          .onClick(async () => {
            if (judgeGroupIsEnd(this.courseInfo as Record<string, string>)) {
              return
            }
            if (!_.trim(this.content)) {
              CustomToast.toast_fail('课程公告内容不能为空');
              return
            }
            const response = await xyApiPost(this.Api_Context.getApiPrefix('baseApi_inner') + HomeApi.addAnnouncement, {
              'group_id': this.courseInfo.id,
              'content': this.content,
            })
            if (response.success) {
              CustomToast.toast_success('发布公告成功')
              this.pageInfos.pop({ refresh: true })
            }
          })
      }
      .margin({ left: 12, right: 12 })
    }
    .title(CustomNavTitle('课程公告'))
    .backgroundColor('#f1f1f1')
  }
}

@Builder
export function CreateCourseNoticeBuilder() {
  CreateCourseNotice()
}
