import { display } from "@kit.ArkUI"
import _ from "@wolfx/lodash"
import {
  Api_Context,
  AppIcon,
  CCApi,
  ccApiPost,
  IconConstants,
  PreferenceStorage,
  UserInfoModel
} from "@xy/basic"

@Component
struct CourseDetailPage {
  @StorageLink('UserInfo') userInfo: UserInfoModel = new UserInfoModel()
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @StorageLink('PreferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage()
  @State screenWidth: number = 0
  @State siteCerts: Record<string, Record<string, string>[]> = {}
  private courseInfo = this.preferenceStorage.currentTeam ?? {}

  async querySiteCertificate() {
    const response = await ccApiPost(this.Api_Context.getApiPrefix('ccApi') + CCApi.getSiteCertificate,
      [String(this.courseInfo.site_id)])
    if (response.code === 200) {
      this.siteCerts = response.result as Record<string, Record<string, string>[]>
    }
  }

  aboutToAppear(): void {
    this.screenWidth = px2vp(display.getDefaultDisplaySync().width)
    this.querySiteCertificate()
  }

  @Builder
  BuildNavRightBtn() {
    AppIcon({
      iconCode: IconConstants.QRCODE,
      iconSize: 16,
      iconMargin: { right: 12 },
      onClickBtn: async () => {
      }
    })
    AppIcon({
      iconCode: IconConstants.SCAN,
      iconSize: 16,
      onClickBtn: async () => {
      }
    })
  }

  build() {
    NavDestination() {
      Flex({ direction: FlexDirection.Column }) {
        Column() {
          Column() {
            Row() {
              AppIcon({
                iconCode: IconConstants.LEFT,
                iconColor: Color.White,
                iconSize: 16,
                onClickBtn: () => {
                  this.pageInfos.pop()
                }
              })
              Row() {
                AppIcon({
                  iconCode: IconConstants.QRCODE,
                  iconColor: Color.White,
                  iconSize: 16,
                  iconMargin: { right: 12 },
                  onClickBtn: () => {
                  }
                })
                AppIcon({
                  iconCode: IconConstants.SCAN,
                  iconColor: Color.White,
                  iconSize: 16,
                  onClickBtn: () => {
                  }
                })
              }
            }
            .justifyContent(FlexAlign.SpaceBetween)
            .width('100%')
            .margin({ top: 12, bottom: 12 })

            Row() {
              Text(String(this.courseInfo.name))
                .fontColor(Color.White)
            }
            .width('100%')

            Flex({ direction: FlexDirection.RowReverse, justifyContent: FlexAlign.End }) {
              ForEach((() => {
                return _.isEmpty(this.siteCerts) ? [] : (this.siteCerts[this.courseInfo.site_id] ?? [])
              })(), (item: Record<string, string>, index: number) => {
                Text(item.siteCertificateLevelName)
                  .margin({ left: (this.siteCerts[item.siteId] ?? []).length - index === 1 ? 0 : -8 })
                  .padding({
                    left: (this.siteCerts[item.siteId] ?? []).length - index === 1 ? 8 : 16,
                    right: 8,
                    top: 4,
                    bottom: 4
                  })
                  .borderRadius({ topLeft: 4, bottomRight: 10 })
                  .backgroundColor('#FCBB34')
                  .fontColor(Color.White)
                  .fontSize(12)
                  .shadow(ShadowStyle.OUTER_DEFAULT_SM)
              })
            }
            .height(22)
            .margin({ top: 12, bottom: 12 })

            Row() {
              Text(String(this.courseInfo.teacher_names))
                .fontColor(Color.White)
                .fontSize(14)
                .width('100%')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.MARQUEE })
            }

            Row() {
              Text((() => {
                return [this.courseInfo.term_name, (() => {
                  switch (this.courseInfo.public_type) {
                    case '1':
                      return `私有`
                    case '2':
                      return `课内`
                    case '3':
                      return `校内`
                    case '4':
                      return `全网`
                    default:
                      return null
                  }
                })(), (() => {
                  if (this.courseInfo.origin_type === '2') {
                    return '自主开课'
                  } else {
                    return '教务开课'
                  }
                })()].join(' | ')
              })())
                .textAlign(TextAlign.Center)
                .fontColor(Color.White)
                .fontSize(14)

              Row() {
                Text('查看记录')
                  .fontColor(Color.White)
                AppIcon({
                  iconCode: IconConstants.RIGHT,
                  iconSize: 14
                })
              }
              .onClick(() => {

              })
            }
            .justifyContent(FlexAlign.SpaceBetween)
            .width('100%')
            .margin({ top: 12, bottom: 12 })
          }
          .margin({ left: 12, right: 12 })

          Swiper() {
            ForEach(new Array(Math.ceil(getCourseFuncItems(Number(this.courseInfo.role)).length / 4)).fill(0),
              (item: number, paper: number) => {
                Row() {
                  ForEach([0, 1, 2, 3], (item: number, index: number) => {
                    Column() {
                      Image(getCourseFuncItems(Number(this.courseInfo.role))[4 * paper+index]?.icon)
                        .width(24)
                        .height(24)
                      Text(getCourseFuncItems(Number(this.courseInfo.role))[4 * paper+index]?.title)
                        .margin({ top: 8 })
                        .fontSize(14)
                    }
                    .width(80)
                    .height(80)
                    .padding(12)
                  })
                }
                .justifyContent(FlexAlign.SpaceAround)
              })
          }
          .loop(false)
          .indicator(
            Indicator.dot()
              .selectedColor('#FCBB34')
              .bottom(-4)
          )
          .width(this.screenWidth - 24)
          .margin({ left: 12, right: 12 })
          .backgroundColor(Color.White)
          .borderRadius(8)
        }
        .flexShrink(0)
        .width(this.screenWidth)
        .height(220)
        .backgroundImage(String(this.courseInfo.cover_img))
        .backgroundImageSize({ width: '100%', height: '100%' })
        .backgroundEffect({ radius: 25 })
      }
    }
    .hideTitleBar(true)
    .backgroundColor("#f1f1f1")
  }
}

@Builder
export function CourseDetailPageBuilder() {
  CourseDetailPage()
}

export const getCourseFuncItems = (role: number) => {
  const item: Record<string, string | Resource>[] = [
    {
      'title': '作业任务',
      'icon': $r('app.media.class_task'),
      'type': 'task',
    },
    {
      'title': '课程工具',
      'icon': $r('app.media.class_tool'),
      'type': 'tool',
    },
    {
      'title': '分组',
      'icon': $r('app.media.class_group'),
      'type': 'group',
    },
  ]

  if (role !== 1) {
    item.push({
      'title': '学生学情',
      'icon': $r('app.media.class_study'),
      'type': 'study',
    },
      {
        'title': '课程画像',
        'icon': $r('app.media.class_board'),
        'type': 'board',
      },
      {
        'title': '课程管理',
        'icon': $r('app.media.class_setting'),
        'type': 'manager',
      },
      {
        'title': '通知公告',
        'icon': $r('app.media.class_notice'),
        'type': 'notice',
      }
    )
  } else {
    item.push(
      {
        'title': '我的学情',
        'icon': $r('app.media.class_study'),
        'type': 'study',
      },
      {
        'title': '课程画像',
        'icon': $r('app.media.class_board'),
        'type': 'board',
      },
      {
        'title': '课程概况',
        'icon': $r('app.media.class_setting'),
        'type': 'manager',
      },
      {
        'title': '通知公告',
        'icon': $r('app.media.class_notice'),
        'type': 'notice',
      },
    )
  }
  return item
}