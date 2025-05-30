import _ from "@wolfx/lodash"
import {
  Api_Context,
  CustomList,
  CustomListItem,
  CustomNavTitle,
  CustomToast,
  HomeApi,
  PreferenceStorage,
  UserInfoModel,
  xyApiGet
} from "@xy/basic"

@Component
struct BoardList {
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @StorageLink('UserInfo') userInfo: UserInfoModel = new UserInfoModel()
  @StorageLink('PreferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage()
  private courseInfo = this.preferenceStorage.currentTeam ?? {}

  @Builder
  BuildLeftIcon(src: Resource) {
    Image(src)
      .width(32)
      .height(32)
      .margin({ right: 10 })
      .borderRadius(4)
  }

  build() {
    NavDestination() {
      Flex({ direction: FlexDirection.Column }) {
        CustomList() {
          CustomListItem({
            text: '课程看板',
            itemBorder: {},
            itemMargin: { bottom: 12 },
            itemRadius: 4,
            iconBuilder: () => this.BuildLeftIcon($r('app.media.course_board')),
            onClickBtn: (): void => {
              const path = `#/${this.courseInfo.course_property === '2' ? 'mooc/groupBoard' :
                'groupBoard'}?group_id=${this.courseInfo.id}`
              this.pageInfos?.pushPath({
                name: 'h5Resource',
                param: JSON.stringify({
                  hideNav: true,
                  source_url: path,
                  title: '课程看板',
                })
              })
            }
          })
          if ((this.courseInfo?.role ?? 1) !== 1) {
            CustomListItem({
              text: '成员画像',
              itemBorder: {},
              itemMargin: { bottom: 12 },
              itemRadius: 4,
              iconBuilder: () => this.BuildLeftIcon($r('app.media.member_portrait')),
              onClickBtn: (): void => this.pageInfos.pushPath({
                name: 'memberPortrait',
                param: JSON.stringify({ self: false })
              })
            })
            CustomList() {
              CustomListItem({
                text: '课堂实录分析',
                itemBorder: {},
                itemMargin: { bottom: 12 },
                itemRadius: 4,
                iconBuilder: () => this.BuildLeftIcon($r('app.media.teach_trace')),
                onClickBtn: (): void => this.pageInfos.pushPath({ name: 'courseAnalysis' })
              })
            }

            if (this.courseInfo.course_property !== '2') {
              CustomListItem({
                text: '课堂教学活动轨迹',
                itemBackgroundColor: '#EBEDF0',
                itemBorder: {},
                itemMargin: { bottom: 12 },
                itemRadius: 4,
                iconBuilder: () => this.BuildLeftIcon($r('app.media.teach_trace')),
                onClickBtn: (): void => CustomToast.toast_info('移动端暂未开放课堂教学活动轨迹功能，请去web端查看。')
              })
            }
          }
          if (this.courseInfo.course_property !== '2') {
            CustomListItem({
              text: '班级画像',
              itemBorder: {},
              itemMargin: { bottom: 12 },
              itemRadius: 4,
              iconBuilder: () => this.BuildLeftIcon($r('app.media.class_portrait')),
              onClickBtn: async (): Promise<void> => {
                let path = `#/classPortrait?group_id=${this.courseInfo.id}`;
                if ((this.courseInfo?.role ?? 1) === 1) {
                  const response =
                    await xyApiGet(this.Api_Context.getApiPrefix('baseApi_inner') + HomeApi.queryMembers, {
                      'group_id': this.courseInfo.id,
                      'random': new Date().getTime(),
                    })
                  const user = _.find(response.data as Record<string, string>[], { 'user_id': this.userInfo.id })
                  path += `&class_id=${user?.class_id}`;
                }
                this.pageInfos?.pushPath({
                  name: 'h5Resource',
                  param: JSON.stringify({
                    hideNav: true,
                    source_url: path,
                    title: '班级画像',
                  })
                })
              }
            })
          }
          CustomListItem({
            text: 'AI+应用看板',
            itemBackgroundColor: '#EBEDF0',
            itemBorder: {},
            itemMargin: { bottom: 12 },
            itemRadius: 4,
            iconBuilder: () => this.BuildLeftIcon($r('app.media.ai_helper')),
            onClickBtn: (): void => CustomToast.toast_info('移动端暂未开放AI+应用看板功能，请去web端查看。')
          })
        }
      }
      .margin({ left: 12, right: 12 })
    }
    .title(CustomNavTitle('课程画像'))
    .backgroundColor('#F5F5F5')
  }
}

@Builder
export function BoardListBuilder() {
  BoardList()
}