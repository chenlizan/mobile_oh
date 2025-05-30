import { common } from "@kit.AbilityKit"
import { window } from "@kit.ArkUI"
import { webview } from "@kit.ArkWeb"
import _ from "@wolfx/lodash"
import dayjs from "dayjs"
import { CustomLocalH5 } from "@xy/webview"
import {
  Api_Context,
  AppIcon,
  CCApi,
  ccApiGet,
  CustomNavTitle,
  getCourseAvatarUrl,
  getMemberRole,
  HomeApi,
  IconConstants,
  PreferenceStorage,
  UserInfoModel,
  xyApiGet
} from "@xy/basic"

const context: Context = getContext(this)

@Component
struct MemberPortrait {
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @StorageLink('PreferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage()
  @StorageLink('UserInfo') userInfo: UserInfoModel = new UserInfoModel()
  @State controller: webview.WebviewController = new webview.WebviewController()
  @State isRefreshing: boolean = false
  @State schoolList: Record<string, string>[] = []
  @State classList: Record<string, string>[] = []
  @State classMember: Record<string, string | number>[] = []
  @State statusBarHeight: number = 0
  @State bottomNavHeight: number = 0
  @State currentUser: Record<string, string | number> = {}
  private param: Record<string, boolean> = {}
  private windowClass = (context as common.UIAbilityContext).windowStage.getMainWindowSync()
  private courseInfo = this.preferenceStorage.currentTeam ?? {}
  private dialogController: CustomDialogController = new CustomDialogController({
    builder: MemberList({
      statusBarHeight: this.statusBarHeight,
      bottomNavHeight: this.statusBarHeight,
      classList: this.classList,
      classMember: this.classMember,
      onSelectItem: (item) => {
        this.currentUser = item
        this.queryUserSchoolInfo(this.currentUser.jw_user_id as string)
        this.dialogController.close()
      }
    }),
    alignment: DialogAlignment.CenterStart,
    customStyle: true,
    cancel: () => this.dialogController.close(),
    closeAnimation: { duration: 0 }
  })

  async queryUserSchoolInfo(userId: string = this.userInfo.userId) {
    const response =
      await ccApiGet(this.Api_Context.getApiPrefix('ccApi') + CCApi.queryUserSchoolInfo, { 'userId': userId })
    if (response.code === 200) {
      this.schoolList = response.result as Record<string, string>[]
    }
  }

  async queryClassList(): Promise<boolean> {
    const response =
      await xyApiGet(this.Api_Context.getApiPrefix('baseApi_inner') + HomeApi.groupClassList + '/' + this.courseInfo.id)
    if (response.success) {
      this.classList = response.data as Record<string, string>[]
      return true
    } else {
      return false
    }
  }

  async queryMembers() {
    const response = await xyApiGet(this.Api_Context.getApiPrefix('baseApi_inner') + HomeApi.queryMembers, {
      'group_id': this.courseInfo.id,
      'random': new Date().getTime(),
    })
    if (response.success) {
      this.classMember = response.data as Record<string, string>[]
      return true
    } else {
      return false
    }
  }

  getUrlPath() {
    let path =
      `#/memberPortrait?group_id=${this.courseInfo.id}&user_id=${this.currentUser.user_id}&role=${this.currentUser.role}`
    return path
  }

  async aboutToAppear(): Promise<void> {
    this.param = JSON.parse(String(this.pageInfos.getParamByName('memberPortrait')[0]))
    const avoidArea = this.windowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM)
    this.statusBarHeight = px2vp(avoidArea.topRect.height)
    this.bottomNavHeight = px2fp(avoidArea.bottomRect.height)
    await Promise.all([this.queryClassList(), this.queryMembers(), this.queryUserSchoolInfo()])
    this.currentUser = _.find(this.classMember, { user_id: this.userInfo.id }) as Record<string, string | number>
  }

  @Builder
  BuildNavRightBtn() {
    if(this.param.self === false) {
      AppIcon({
        iconCode: IconConstants.MENU,
        iconSize: 16,
        onClickBtn: () => {
          this.dialogController.open()
        }
      })
    }
  }

  build() {
    NavDestination() {
      Flex({ direction: FlexDirection.Column }) {
        Row() {
          Image(getCourseAvatarUrl(this.currentUser.user_id as string))
            .width(64)
            .height(64)
            .borderRadius(32)
          Column({ space: 8 }) {
            Text(this.currentUser.nickname as string)
              .fontSize(14)
            Row() {
              AppIcon({
                iconCode: IconConstants.COLLEGE,
                iconColor: '#999999',
                iconMargin: { right: 8 }
              })
              Text(`所属学校：${(
                () => {
                  return!
                  _.isEmpty(this.schoolList) ? _.map(this.schoolList, school => school.schoolName).join('、') :
                    ''
                })()}`)
                .fontColor('#999999')
                .fontSize(12)
            }

            Row() {
              AppIcon({
                iconCode: IconConstants.CARD,
                iconColor: '#999999',
                iconMargin: { right: 8 }
              })
              Text(`一卡通号：${this.currentUser.student_number}`)
                .fontColor('#999999')
                .fontSize(12)
            }

            Row() {
              AppIcon({
                iconCode: IconConstants.TIME,
                iconColor: '#999999',
                iconMargin: { right: 8 }
              })
              Text(`加入课程时间：${this.currentUser.last_join_time ?
              dayjs(this.currentUser.last_join_time).format('YYYY-MM-DD HH:mm') : '暂无数据'}`)
                .fontColor('#999999')
                .fontSize(12)
            }
          }
          .alignItems(HorizontalAlign.Start)
          .margin({ left: 8 })
        }
        .flexShrink(0)
        .width('100%')
        .margin({ bottom: 12 })

        if (this.currentUser.user_id && this.currentUser.role) {
          CustomLocalH5({
            url: this.getUrlPath(),
            controller: this.controller,
          })
        }
      }
      .margin({ left: 12, right: 12 })
    }
    .title(CustomNavTitle('', () => this.BuildNavRightBtn()))
    .backgroundColor('#f1f1f1')
  }
}

@CustomDialog
struct MemberList {
  @Prop statusBarHeight: number = 0
  @Prop bottomNavHeight: number = 0
  @Prop classList: Record<string, string>[] = []
  @Prop classMember: Record<string, string | number>[] = []
  @State selectClassId: string = ''
  private controller?: CustomDialogController
  onSelectItem: (item: Record<string, string | number>) => void = () => {
  }

  build() {
    Flex({ direction: FlexDirection.Column }) {
      Select([{ value: '全部班级' } as SelectOption].concat(this.classList.map((item) => {
        return { 'value': item.class_name } as SelectOption
      })))
        .selected(0)
        .margin({ top: 40, bottom: 12 })
        .fontColor('#999999')
        .font({ size: 15 })
        .value('全部班级')
        .width('100%')
        .backgroundColor(Color.White)
        .borderRadius(4)
        .onSelect((index: number) => {
          if (index > 0) {
            this.selectClassId = this.classList[index-1].class_id
          } else {
            this.selectClassId = ''
          }
        })
        .flexShrink(0)
      if (_.isEmpty(_.filter(this.classMember,
        item => !_.trim(this.selectClassId) || this.selectClassId === item.class_id))) {
        Column() {
          Text('暂无数据')
            .fontColor('#999999')
        }
        .flexGrow(1)
        .justifyContent(FlexAlign.Center)
        .width('100%')
      } else {
        List({ space: 12 }) {
          ForEach(_.filter(this.classMember,
            item => !_.trim(this.selectClassId) || this.selectClassId === item.class_id),
            (item: Record<string, string>) => {
              ListItem() {
                Row() {
                  Row() {
                    Image(getCourseAvatarUrl(item.user_id))
                      .width(36)
                      .height(36)
                      .borderRadius(18)
                    Text(item.nickname)
                      .margin({ left: 8 })
                      .fontSize(14)
                  }

                  Text(getMemberRole(Number(item.role)))
                    .fontColor('#999999')
                    .fontSize(14)
                }
                .justifyContent(FlexAlign.SpaceBetween)
                .width('100%')
                .padding(12)
                .backgroundColor(Color.White)
                .borderRadius(4)
                .onClick(() => this.onSelectItem(item))
              }
            })
        }
        .flexGrow(1)
      }
    }
    .width('75%')
    .margin({
      top: this.statusBarHeight,
      bottom: this.bottomNavHeight
    })
    .padding({ left: 12, right: 12 })
    .backgroundColor('#f1f1f1')
    .borderRadius({ topRight: 8, bottomRight: 8 })
    .transition(TransitionEffect.move(TransitionEdge.START).animation({ duration: 300 }))
  }
}

@Builder
export function MemberPortraitBuilder() {
  MemberPortrait()
}