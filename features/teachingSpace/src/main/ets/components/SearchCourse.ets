import _ from "@wolfx/lodash"
import { display } from "@kit.ArkUI"
import { Api_Context, AppIcon, CustomNavTitle, HomeApi, IconConstants, xyApiGet } from "@xy/basic"

@Component
struct SearchCourse {
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @State screenWidth: number = 0
  @State isRefreshing: boolean = false
  @State courseTeachList: Record<string, string>[] = []
  @State courseStuList: Record<string, string>[] = []
  @State resultList: Record<string, string>[] = []

  async queryTeacherGroups() {
    const response =
      await xyApiGet(this.Api_Context.getApiPrefix('baseApi_inner') + HomeApi.queryTeacherGroups)
    if (response.success) {
      this.courseTeachList = _.orderBy(response.data, ['start_time'], ['desc'])
    }
  }

  async queryStudentGroups() {
    const response =
      await xyApiGet(this.Api_Context.getApiPrefix('baseApi_inner') + HomeApi.queryStudentGroups)
    if (response.success) {
      this.courseStuList = _.orderBy(response.data, ['start_time'], ['desc'])
    }
  }

  aboutToAppear(): void {
    this.screenWidth = px2vp(display.getDefaultDisplaySync().width)
    this.queryTeacherGroups()
    this.queryStudentGroups()
  }

  build() {
    NavDestination() {
      Refresh({ refreshing: $$this.isRefreshing }) {
        Flex({ direction: FlexDirection.Column }) {
          Search({ placeholder: '搜索' })
            .margin({ left: 12, right: 12, bottom: 4 })
            .backgroundColor(Color.White)
            .borderRadius(4)
            .flexShrink(0)
            .onSubmit((value: string) => {
              if (_.trim(value)) {
                let rows: Record<string, string>[] = []
                rows = rows.concat(this.courseTeachList)
                rows = rows.concat(this.courseStuList)
                this.resultList = _.filter(
                  rows,
                  course =>
                  _.toLower(course?.name ?? '')?.indexOf(_.toLower(value)) !== -1,
                )
              } else {
                this.resultList = []
              }
            })
          if (_.isEmpty(this.resultList)) {
            Column() {
              Text('暂无数据')
                .fontColor('#999999')
            }
            .flexGrow(1)
            .justifyContent(FlexAlign.Center)
            .width(this.screenWidth)
          } else {
            List() {
              ForEach(this.resultList, (item: Record<string, string>) => {
                ListItem() {
                  Column() {
                    Row() {
                      Text(item.name)
                      Text('MOOC')
                        .padding({
                          left: 8,
                          right: 8,
                          top: 4,
                          bottom: 4
                        })
                        .backgroundColor('#EBEDF0')
                        .borderRadius(2)
                        .fontColor('#999999')
                        .fontSize(14)
                        .visibility(item.course_property === '2' ? Visibility.Visible : Visibility.None)
                    }
                    .justifyContent(FlexAlign.SpaceBetween)
                    .width(this.screenWidth - 40)
                    .margin({
                      left: 8,
                      right: 8,
                      top: 8,
                      bottom: 0
                    })

                    Row() {
                      Stack() {
                        Image(item.cover_img || $r('app.media.class_default_bg'))
                          .width(160)
                          .height(90)
                          .margin(8)
                          .borderRadius(4)
                        Column() {
                          Text(item.custom_info)
                            .padding({ top: 3, bottom: 3 })
                            .fontColor('#B9B9B9')
                            .fontSize(11)
                            .backgroundColor('rgba(0, 0, 0, 0.65)')
                          Text((() => {
                            return [item.term_name, (() => {
                              switch (item.public_type) {
                                case '1':
                                  return `私有`;
                                case '2':
                                  return `课内`;
                                case '3':
                                  return `校内`;
                                case '4':
                                  return `全网`;
                                default:
                                  return null;
                              }
                            })(), (() => {
                              if (item.origin_type === '2') {
                                return '自主开课';
                              } else {
                                return '教务开课';
                              }
                            })()].join(' | ')
                          })())
                            .width(160)
                            .padding({ top: 3, bottom: 3 })
                            .textAlign(TextAlign.Center)
                            .fontColor('#B9B9B9')
                            .fontSize(11)
                            .backgroundColor('rgba(0, 0, 0, 0.65)')
                            .borderRadius({ bottomLeft: 4, bottomRight: 4 })
                        }
                        .justifyContent(FlexAlign.SpaceBetween)
                        .alignItems(HorizontalAlign.Start)
                        .width(160)
                        .height(90)
                      }

                      Column() {
                        Text(`学院: ${item.department_name}`)
                          .fontColor('#999999')
                          .fontSize(13)
                          .width(this.screenWidth - 208)
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.MARQUEE })
                        Text(item.teacher_names)
                          .fontColor('#999999')
                          .fontSize(13)
                          .width(this.screenWidth - 208)
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.MARQUEE })
                        Flex({ justifyContent: FlexAlign.SpaceBetween }) {
                          Text(`访问量:${'' + item.visit_number}次`)
                            .fontColor('#999999')
                            .fontSize(13)
                          Row() {
                            AppIcon({
                              iconCode: IconConstants.USER,
                              iconSize: 13,
                              iconColor: '#999999',
                              iconMargin: { bottom: 2 }
                            })
                            Text(`${item.member_count}人`)
                              .fontColor('#999999')
                              .fontSize(13)
                          }
                        }
                      }
                      .justifyContent(FlexAlign.SpaceBetween)
                      .alignItems(HorizontalAlign.Start)
                      .width(this.screenWidth - 208)
                      .height(90)
                    }
                    .width(this.screenWidth - 40)
                  }
                  .width('auto')
                  .margin({ left: 12, right: 12, bottom: 8 })
                  .alignItems(HorizontalAlign.Start)
                  .backgroundColor(Color.White)
                  .borderRadius(4)
                  .onClick(() => {
                    console.log('进入课程')
                  })
                }
              })
            }
            .flexGrow(1)
          }
        }
      }
      .onRefreshing(() => {
        setTimeout(() => {
          this.isRefreshing = false
        }, 500)
      })
    }
    .title(CustomNavTitle('课程搜索'))
    .backgroundColor("#f1f1f1")
  }
}

@Builder
export function SearchCourseBuilder() {
  SearchCourse()
}