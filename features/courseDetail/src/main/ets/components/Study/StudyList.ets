import { CustomList, CustomListItem, CustomNavTitle, CustomToast, PreferenceStorage } from "@xy/basic"

@Component
struct StudyList {
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
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
          if (this.courseInfo.course_property !== '2') {
            if ((this.courseInfo?.role ?? 1) === 1) {
              CustomListItem({
                text: '我的画像',
                itemBorder: {},
                itemMargin: { bottom: 12 },
                itemRadius: 4,
                iconBuilder: () => this.BuildLeftIcon($r('app.media.my_portrait')),
                onClickBtn: (): void => this.pageInfos.pushPath({
                  name: 'memberPortrait',
                  param: JSON.stringify({ self: true })
                })
              })
            } else {
              if (this.courseInfo.member_count <= 500) {
                CustomListItem({
                  text: '排行榜',
                  itemBorder: {},
                  itemMargin: { bottom: 12 },
                  itemRadius: 4,
                  iconBuilder: () => this.BuildLeftIcon($r('app.media.course_rank')),
                  onClickBtn: (): void => {
                    const path = `#/groupRank?group_id=${this.courseInfo.id}`
                    this.pageInfos?.pushPath({
                      name: 'h5Resource',
                      param: JSON.stringify({
                        hideNav: true,
                        source_url: path,
                        title: '排行榜',
                      })
                    })
                  }
                })
              }
            }
          }
          CustomListItem({
            text: '课程任务',
            itemBackgroundColor: '#EBEDF0',
            itemBorder: {},
            itemMargin: { bottom: 12 },
            itemRadius: 4,
            iconBuilder: () => this.BuildLeftIcon($r('app.media.course_task')),
            onClickBtn: (): void => CustomToast.toast_info('移动端暂未开放课程任务功能，请去web端查看。')
          })
          CustomListItem({
            text: '学习时长',
            itemBackgroundColor: '#EBEDF0',
            itemBorder: {},
            itemMargin: { bottom: 12 },
            itemRadius: 4,
            iconBuilder: () => this.BuildLeftIcon($r('app.media.study_length')),
            onClickBtn: (): void => CustomToast.toast_info('移动端暂未开放学习时长功能，请去web端查看。')
          })
          if ((this.courseInfo?.role ?? 1) === 1) {
            if (this.courseInfo.course_property !== '2') {
              CustomListItem({
                text: '签到记录',
                itemBorder: {},
                itemMargin: { bottom: 12 },
                itemRadius: 4,
                iconBuilder: () => this.BuildLeftIcon($r('app.media.course_sign')),
                onClickBtn: (): void => {
                }
              })
              CustomListItem({
                text: '课堂表现',
                itemBackgroundColor: '#EBEDF0',
                itemBorder: {},
                itemMargin: { bottom: 12 },
                itemRadius: 4,
                iconBuilder: () => this.BuildLeftIcon($r('app.media.course_performance')),
                onClickBtn: (): void => CustomToast.toast_info('移动端暂未开放课堂表现功能，请去web端查看。')
              })
              CustomListItem({
                text: '评价活动',
                itemBackgroundColor: '#EBEDF0',
                itemBorder: {},
                itemMargin: { bottom: 12 },
                itemRadius: 4,
                iconBuilder: () => this.BuildLeftIcon($r('app.media.tool_appraise')),
                onClickBtn: (): void => CustomToast.toast_info('移动端暂未开放评价活动功能，请去web端查看。')
              })
              CustomListItem({
                text: '错题本',
                itemBorder: {},
                itemMargin: { bottom: 12 },
                itemRadius: 4,
                iconBuilder: () => this.BuildLeftIcon($r('app.media.tool_wrong_book')),
                onClickBtn: (): void => {
                }
              })
            }
          } else {
            if (this.courseInfo.course_property !== '2') {
              CustomListItem({
                text: '签到',
                itemBorder: {},
                itemMargin: { bottom: 12 },
                itemRadius: 4,
                iconBuilder: () => this.BuildLeftIcon($r('app.media.course_sign')),
                onClickBtn: (): void => {
                }
              })
              CustomListItem({
                text: '课堂表现',
                itemBackgroundColor: '#EBEDF0',
                itemBorder: {},
                itemMargin: { bottom: 12 },
                itemRadius: 4,
                iconBuilder: () => this.BuildLeftIcon($r('app.media.course_performance')),
                onClickBtn: (): void => CustomToast.toast_info('移动端暂未开放课堂表现功能，请去web端查看。')
              })
              CustomListItem({
                text: '评价活动',
                itemBackgroundColor: '#EBEDF0',
                itemBorder: {},
                itemMargin: { bottom: 12 },
                itemRadius: 4,
                iconBuilder: () => this.BuildLeftIcon($r('app.media.tool_appraise')),
                onClickBtn: (): void => CustomToast.toast_info('移动端暂未开放评价活动功能，请去web端查看。')
              })
            }
            CustomListItem({
              text: '总评成绩',
              itemBackgroundColor: '#EBEDF0',
              itemBorder: {},
              itemMargin: { bottom: 12 },
              itemRadius: 4,
              iconBuilder: () => this.BuildLeftIcon($r('app.media.review_grade')),
              onClickBtn: (): void => CustomToast.toast_info('移动端暂未开放总评成绩功能，请去web端查看。')
            })
          }
        }
      }
      .margin({ left: 12, right: 12 })
    }
    .title(CustomNavTitle((this.courseInfo?.role ?? 1) === 1 ? '我的学情' : '学生学情'))
    .backgroundColor('#F5F5F5')
  }
}


@Builder
export function StudyListBuilder() {
  StudyList()
}