import { ComponentContent, display, LengthMetrics, window } from "@kit.ArkUI"
import _ from "@wolfx/lodash"
import {
  Api_Context,
  AppIcon,
  CCApi,
  ccApiPost,
  CustomAlertDialog,
  CustomTag,
  CustomToast,
  getCourseInfo,
  getFolderDownloadStatus,
  getFolderDownloadStatusText,
  getFolderPublicStatus,
  getFolderPublicStatusText,
  getIconByFileType,
  getTypeByAssignToType,
  getTypeByTaskType,
  HomeApi,
  IconConstants,
  judgeGroupIsEnd,
  judgeRoleHasCourseOperationWeight,
  PreferenceStorage,
  regularFilename,
  UserInfoModel,
  xyApiGet,
  xyApiPost
} from "@xy/basic"

@Component
struct CourseDetailPage {
  @StorageLink('UserInfo') userInfo: UserInfoModel = new UserInfoModel()
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @StorageLink('PreferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage()
  @State screenWidth: number = 0
  @State screenHeight: number = 0
  @State isRefreshing: boolean = false
  @State siteCerts: Record<string, Record<string, string>[]> = {}
  @State rootResources: Record<string, string | number | boolean> [] = []
  @State subResources: Record<string, string | number | boolean> [] = []
  @State currentCourse: Record<string, string | number | boolean> = {}
  private courseInfo = this.preferenceStorage.currentTeam ?? {}
  private funcItems: Record<string, string | Resource>[] = []
  private rootSource: Record<string, string | number | boolean> = {}

  async querySiteCertificate() {
    const response = await ccApiPost(this.Api_Context.getApiPrefix('ccApi') + CCApi.getSiteCertificate,
      [String(this.courseInfo.site_id)])
    if (response.code === 200) {
      this.siteCerts = response.result as Record<string, Record<string, string>[]>
    }
  }

  async queryCourseResources() {
    const response = await xyApiGet(this.Api_Context.getApiPrefix('baseApi_inner') + HomeApi.queryCourseResources, {
      'group_id': this.courseInfo.id,
    })
    if (response.success) {
      const rootSource = _.filter(response.data as Record<string, string>[], res => res.parent_id === '1')[0]
      const resources =
        _.filter(response.data as Record<string, string | number>[], res => res.parent_id !== '1' && res.del !== 2)
      const real_resources = _.orderBy(
        _.map(resources, (item: Record<string, string | number | boolean>) => {
          if (item.task_id) {
            item._formatKey = Number(this.courseInfo.role) === 1 ? 'student' : 'teacher'
            item._isSurveyTask = item.task_type >= 2 && item.task_type <= 6
            item._assignTypeText = getTypeByAssignToType(item.assign_to_type as number, item.finish_type as number)
            item._taskTypeText = getTypeByTaskType(item.task_type as number)
          }
          item._formatKey = Number(this.courseInfo.role) === 1 ? 'student' : 'teacher'
          return item
        }),
        ['sort_position'],
        ['asc']
      )
      this.rootSource = rootSource
      this.rootResources = _.filter(
        real_resources,
        res => res.parent_id === rootSource.id,
      )
      this.subResources = _.filter(
        real_resources,
        res => res.parent_id !== rootSource.id,
      )
    }
  }

  async queryCurrentCourse() {
    const response = await xyApiGet(this.Api_Context.getApiPrefix('baseApi_inner') + HomeApi.getOpenCourse, {
      'group_id': this.courseInfo.id,
      'is_in_course': 2,
    })
    if (response.success) {
      this.currentCourse = response.data as Record<string, string | number | boolean>
    }
  }

  async createCourseResource(type: number, name: string) {
    const canOperation = judgeRoleHasCourseOperationWeight(Number(this.courseInfo?.role ?? 1))
    if (!canOperation && !_.isEmpty(this.courseInfo) && judgeGroupIsEnd(this.courseInfo as Record<string, string>)) {
      return
    }
    const body: Record<string, string | number | Record<string, string>> = {
      'group_id': String(this.courseInfo.id),
      'parent_id': String(this.rootSource.id),
      'name': regularFilename(name, this.rootResources as Record<string, string>[]),
      'type': type,
    }
    const addResource = async () => {
      const response = await xyApiPost(this.Api_Context.getApiPrefix('baseApi_inner') + HomeApi.addResource, body)
      if (response.success) {
        this.queryCourseResources()
        if (type === 8) {

        } else if (type === 7) {
          CustomToast.toast_success('资源创建成功')
        } else {
          CustomToast.toast_success(
            `资源创建成功${
            this.courseInfo?.is_resource_auto_public ? '，已设置学生可见' : ''
            }`,
          )
        }
      }
    }

    switch (type) {
      case 2:
        body.resource = {
          'content': '{"entityMap":{},"blocks":[{"type":"header-one","text":"笔记标题"},{"type":"paragraph","text":"内容"}]}'
        }
        addResource()
        break
      case 3:
        CustomAlertDialog({
          title: '提示',
          message: '创建导图后，需要去web端编辑完善，是否继续创建导图？',
          onCloseBtn: () => {
            return
          },
          onClickBtn: () => {
            addResource()
          }
        })
        break
      case 11:
        CustomAlertDialog({
          title: '提示',
          message: '创建教学设计后，需要去web端编辑完善，是否继续创建教学设计？',
          onCloseBtn: () => {
            return
          },
          onClickBtn: () => {
            addResource()
          }
        })
        break
      default:
        addResource()
    }
  }

  getCourseFuncItems(role: number) {
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
    this.funcItems = item
  }

  aboutToAppear(): void {
    this.screenWidth = px2vp(display.getDefaultDisplaySync().width)
    this.screenHeight = px2vp(display.getDefaultDisplaySync().height)
    this.querySiteCertificate()
    this.getCourseFuncItems(Number(this.courseInfo.role))
    this.queryCourseResources()
    this.queryCurrentCourse()
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

  @Builder
  BuildExtendEnd() {
    Row() {
      Button('移动到', { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.TEXTUAL })
        .height('100%')
        .backgroundColor('#41A9FF')
        .fontColor(Color.White)
        .fontSize(13)
      Button('置顶', { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.TEXTUAL })
        .height('100%')
        .backgroundColor('#63BDFF')
        .fontColor(Color.White)
        .fontSize(13)
      Button('上移', { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.TEXTUAL })
        .height('100%')
        .backgroundColor('#83D0FF')
        .fontColor(Color.White)
        .fontSize(13)
      Button('下移', { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.TEXTUAL })
        .height('100%')
        .backgroundColor('#A5DFFF')
        .fontColor(Color.White)
        .fontSize(13)
    }
    .height('100%')
  }

  build() {
    NavDestination() {
      Flex({ direction: FlexDirection.Column }) {
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
                  return _.isEmpty(this.siteCerts) ? [] : (this.siteCerts[this.courseInfo.site_id as number] ?? [])
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
                Text(getCourseInfo(this.courseInfo as Record<string, string>))
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
              ForEach(new Array(Math.ceil(this.funcItems.length / 4)).fill(0),
                (item: number, paper: number) => {
                  Row() {
                    ForEach([0, 1, 2, 3], (item: number, index: number) => {
                      Column() {
                        Image(this.funcItems[4 * paper+index]?.icon)
                          .width(24)
                          .height(24)
                        Text(this.funcItems[4 * paper+index]?.title)
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
        .flexShrink(0)
        .height(244)

        Flex({ direction: FlexDirection.Column }) {
          Row() {
            Row() {
              Text(this.courseInfo?.role === 1 ? '课程内容' : '备授课')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .padding(12)

              AppIcon({
                iconCode: IconConstants.QA_AREA,
                iconColor: '#999999',
                iconSize: 28,
                onClickBtn: () => {
                  this.pageInfos?.pushPath({
                    name: 'qaAreaResource',
                    param: JSON.stringify({
                      loginRole: this.courseInfo?.role ?? 1,
                    })
                  })
                }
              })
            }

            if (judgeRoleHasCourseOperationWeight(Number(this.courseInfo?.role ?? 1))) {
              AppIcon({
                iconCode: IconConstants.MORE,
                iconColor: '#40A9FF',
                iconSize: 20,
                iconBorderColor: '#40A9FF',
                iconBorderWidth: 2,
                iconRadius: 20,
                iconMargin: 12,
                onClickBtn: async () => {
                  const windowClass = await window.getLastWindow(getContext())
                  const uiContext = windowClass.getUIContext()
                  const params = new MenuParam()
                  params.hide = () => {
                    if (promptAction && customDialog) {
                      promptAction.closeCustomDialog(customDialog)
                      customDialog.dispose()
                    }
                  }
                  params.currentTeam = this.courseInfo
                  const customDialog = new ComponentContent(uiContext, wrapBuilder(BuildResourceVisibleMenu), params)
                  const promptAction = uiContext.getPromptAction()
                  promptAction.openCustomDialog(customDialog)
                }
              })
            }
          }
          .flexShrink(0)
          .justifyContent(FlexAlign.SpaceBetween)
          .width('100%')

          Divider()
            .flexShrink(0)
            .color('#33999999')
            .strokeWidth(1)
            .margin({ left: 12, right: 12 })
          Column() {
            Refresh({ refreshing: $$this.isRefreshing }) {
              List() {
                ForEach(this.rootResources, (item: Record<string, string | number | boolean>) => {
                  ListItem() {
                    Column() {
                      if (item.tag) {
                        CustomTag({ text: String(item.tag), fontColor: '#FF4040', tagBackgroundColor: '#ebebeb' })
                      }
                      Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Start }) {
                        Flex() {
                          AppIcon(getIconByFileType(Number(item.type), String(item.name), String(item.mimetype)))
                          Text(String(item.name))
                            .margin({ left: 8, right: 8 })
                            .lineHeight(20)
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.MARQUEE })
                        }
                        .flexGrow(1)

                        AppIcon({
                          iconCode: IconConstants.MORE,
                          iconColor: '#999999',
                          iconSize: 22,
                          onClickBtn: async () => {
                            const windowClass = await window.getLastWindow(getContext())
                            const uiContext = windowClass.getUIContext()
                            const params = new MenuParam()
                            params.hide = () => {
                              if (promptAction && customDialog) {
                                promptAction.closeCustomDialog(customDialog)
                                customDialog.dispose()
                              }
                            }
                            params.currentTeam = this.courseInfo
                            params.resource = item
                            params.subResources = this.subResources
                            const customDialog =
                              new ComponentContent(uiContext, wrapBuilder(BuildOperResourceMenu), params)
                            const promptAction = uiContext.getPromptAction()
                            promptAction.openCustomDialog(customDialog, { autoCancel: false })
                          }
                        })
                      }
                      .width('100%')
                      .height(20)
                      .margin({ top: 6, bottom: 6 })

                      Row() {
                        if (item._taskTypeText && item.published === 1) {
                          if ((this.courseInfo?.role ?? 1) === 1) {
                            CustomTag({ text: String(item._taskTypeText), tagMargin: { right: 8 } })
                          } else {
                            CustomTag({
                              text: String(item._taskTypeText),
                              tagBorderColor: '#40A9FF',
                              fontColor: '#40A9FF',
                              tagMargin: { right: 8 }
                            })
                          }
                        }
                        if (!!_.trim(getFolderPublicStatusText(Number(item.type),
                          item as Record<string, string | number>,
                          this.subResources, Number(this.courseInfo?.role ?? 1)))) {
                          CustomTag({
                            text: String(getFolderPublicStatusText(Number(item.type),
                              item as Record<string, string | number>,
                              this.subResources, Number(this.courseInfo?.role ?? 1))),
                            tagMargin: { right: 8 }
                          })
                        }
                        if (!!_.trim(getFolderDownloadStatusText(Number(item.type),
                          item as Record<string, string | number>,
                          this.subResources, Number(this.courseInfo?.role ?? 1)))) {
                          CustomTag({
                            text: String(getFolderDownloadStatusText(Number(item.type),
                              item as Record<string, string | number>,
                              this.subResources, Number(this.courseInfo?.role ?? 1))),
                            tagMargin: { right: 8 }
                          })
                        }
                      }
                    }
                    .alignItems(HorizontalAlign.Start)
                    .margin({ left: 12, right: 12, bottom: 12 })
                  }
                  .swipeAction({
                    end: () => {
                      this.BuildExtendEnd()
                    }
                  })
                })
              }
              .width('100%')
            }
            .onRefreshing(() => {
              this.queryCourseResources()
              this.queryCurrentCourse()
              setTimeout(() => {
                this.isRefreshing = false
              }, 500)
            })
          }
          .flexGrow(1)
          .margin({ top: 8, bottom: 8 })
        }
        .flexGrow(1)
        .width(this.screenWidth - 24)
        .margin({ left: 12, right: 12, top: 12 })
        .backgroundColor(Color.White)
        .borderRadius(8)

        Flex({ space: { main: LengthMetrics.vp(12) } }) {
          if ((this.courseInfo?.role ?? 1) !== 1) {
            Button({ type: ButtonType.Normal, }) {
              Row() {
                Text('+')
                  .margin({ right: 6 })
                  .fontColor('#FCBB34')
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                Text('新增')
              }
              .justifyContent(FlexAlign.Center)
              .width(86)
            }
            .flexGrow(1)
            .height(40)
            .backgroundColor(Color.White)
            .borderRadius(8)
            .onClick(async () => {
              const windowClass = await window.getLastWindow(getContext())
              const uiContext = windowClass.getUIContext()
              const params = new MenuParam()
              params.hide = () => {
                if (promptAction && customDialog) {
                  promptAction.closeCustomDialog(customDialog)
                  customDialog.dispose()
                }
              }
              params.addResource = (type: number, name: string) => {
                this.createCourseResource(type, name)
                params.hide()
              }
              const customDialog = new ComponentContent(uiContext, wrapBuilder(BuildAddResourceMenu), params)
              const promptAction = uiContext.getPromptAction()
              promptAction.openCustomDialog(customDialog, { autoCancel: false })
            })
          }
          if ((this.courseInfo?.role ?? 1) !== 1 && this.currentCourse?.status !== 1) {
            Button({ type: ButtonType.Normal }) {
              Row() {
                AppIcon({
                  iconCode: IconConstants.CLASS,
                  iconColor: '#FCBB34',
                  iconSize: 16,
                  iconMargin: { right: 6 }
                })
                Text('开始上课')
              }
              .width(86)
            }
            .flexGrow(1)
            .height(40)
            .backgroundColor(Color.White)
            .borderRadius(8)
          }
        }
        .flexShrink(0)
        .width(this.screenWidth - 24)
        .margin(12)
        .visibility((this.courseInfo?.role ?? 1) !== 1 ||
          (this.courseInfo?.role ?? 1) !== 1 && this.currentCourse?.status !== 1 ? Visibility.Visible : Visibility.None)
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

class MenuParam {
  currentTeam: Record<string, string | number | boolean> = {}
  subResources: Record<string, string | number | boolean> [] = []
  resource: Record<string, string | number | boolean> = {}
  addResource: (type: number, name: string) => void = () => {
  }
  hide: () => void = () => {
  }
}

@Builder
function BuildResourceVisibleMenu(params: MenuParam) {
  Column() {
    Button('全部设为可见', { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.TEXTUAL })
      .width('100%')
      .fontColor(Color.Black)
      .onClick(() => {
        params.hide()
        CustomAlertDialog({
          dialogHeight: 220,
          title: '请确认',
          message: '1.是否确定将课程内所有资源设置学生可见？\n' +
            '2.请注意：作业/测练资源必须发布任务后学生才能查看与参与，无法设置学生可见。',
          onClickBtn: async () => {
            if (judgeGroupIsEnd(params.currentTeam as Record<string, string>)) {
              return
            }
            const Api_Context = AppStorage.get<Api_Context>('Api_Context')
            const response =
              await xyApiPost(Api_Context?.getApiPrefix('baseApi_inner') + HomeApi.groupResourceAllPublic, {
                'group_id': params.currentTeam.id,
                'is_all_public': true,
              })
            if (response?.success) {
              CustomToast.toast_success(`设置${true ? '全部公开' : '全部取消'}成功`)
            }
          }
        })
      })
    Button('全部设为不可见', { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.TEXTUAL })
      .width('100%')
      .fontColor(Color.Black)
      .onClick(() => {
        params.hide()
        CustomAlertDialog({
          dialogHeight: 220,
          title: '请确认',
          message: '是否确定将课程内所有资源取消学生可见？',
          onClickBtn: async () => {
            if (judgeGroupIsEnd(params.currentTeam as Record<string, string>)) {
              return
            }
            const Api_Context = AppStorage.get<Api_Context>('Api_Context')
            const response =
              await xyApiPost(Api_Context?.getApiPrefix('baseApi_inner') + HomeApi.groupResourceAllPublic, {
                'group_id': params.currentTeam.id,
                'is_all_public': true,
              })
            if (response?.success) {
              CustomToast.toast_success(`设置${false ? '全部公开' : '全部取消'}成功`)
            }
          }
        })
      })
    Divider()
      .color('#33999999')
      .strokeWidth(1)
    Row() {
      Checkbox()
        .select(!!params.currentTeam?.is_resource_auto_public)
        .selectedColor('#FCBB34')
        .shape(CheckBoxShape.ROUNDED_SQUARE)
        .onChange((value: boolean) => {
          params.hide()
          CustomAlertDialog({
            dialogHeight: 220,
            title: '请确认',
            message: '1.勾选【新增资源默认学生可见】之后，新增资源默认设置为学生可见。\n' +
              '2.取消勾选【新增资源默认学生可见】之后，新增资源默认设置为学生不可见。',
            onClickBtn: async () => {
              if (judgeGroupIsEnd(params.currentTeam as Record<string, string>)) {
                return
              }
              const Api_Context = AppStorage.get<Api_Context>('Api_Context')
              const preferenceStorage = AppStorage.get<PreferenceStorage>('PreferenceStorage')
              const response =
                await xyApiPost(Api_Context?.getApiPrefix('baseApi_inner') + HomeApi.groupResourceAutoPublic, {
                  'group_id': params.currentTeam.id,
                  'is_resource_auto_public': value,
                })
              if (response?.success) {
                CustomToast.toast_success(`设置成功`)
                const currentTeam = preferenceStorage?.currentTeam
                if (currentTeam) {
                  currentTeam.is_resource_auto_public =
                    (response.data as Record<string, boolean>).is_resource_auto_public
                  preferenceStorage.currentTeam = currentTeam
                }
              }
            }
          })
        })
      Text('新增资源默认学生可见')
        .padding({
          left: 4,
          top: 12,
          bottom: 12
        })
      AppIcon({
        iconCode: IconConstants.INFO,
        iconSize: 14,
        iconPadding: 8,
        onClickBtn: () => {
          CustomToast.toast_info('1.勾选【新增资源默认学生可见】之后，新增资源默认设置为学生可见。\n' +
            '2.取消勾选【新增资源默认学生可见】之后，新增资源默认设置为学生不可见。')
        }
      })
    }
  }
  .margin(48)
  .backgroundColor(Color.White)
  .borderRadius(8)
}

@Builder
function BuildAddResourceMenu(params: MenuParam) {
  Column() {
    Button('文件夹', { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.TEXTUAL })
      .width('100%')
      .fontColor('#40A9FF')
      .onClick(() => params.addResource(1, '新建文件夹'))
    Divider()
      .color('#33999999')
      .strokeWidth(1)
    Button('笔记', { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.TEXTUAL })
      .width('100%')
      .fontColor('#40A9FF')
      .onClick(() => params.addResource(2, '新建笔记'))
    Divider()
      .color('#33999999')
      .strokeWidth(1)
    Button('导图', { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.TEXTUAL })
      .width('100%')
      .fontColor('#40A9FF')
      .onClick(() => params.addResource(3, '新建导图'))
    Divider()
      .color('#33999999')
      .strokeWidth(1)
    Button('作业/测练', { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.TEXTUAL })
      .width('100%')
      .fontColor('#40A9FF')
      .onClick(() => params.addResource(7, '作业/测练'))
    Divider()
      .color('#33999999')
      .strokeWidth(1)
    Button('讨论', { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.TEXTUAL })
      .width('100%')
      .fontColor('#40A9FF')
    Divider()
      .color('#33999999')
      .strokeWidth(1)
    Button('教学设计', { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.TEXTUAL })
      .width('100%')
      .fontColor('#40A9FF')
    Divider()
      .color('#33999999')
      .strokeWidth(1)
    Button('本地资源', { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.TEXTUAL })
      .width('100%')
      .fontColor('#40A9FF')
    Divider()
      .color('#33999999')
      .strokeWidth(1)
    Button('取消', { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.TEXTUAL })
      .width('100%')
      .fontColor('#999999')
      .onClick(() => params.hide())
  }
  .margin(48)
  .backgroundColor(Color.White)
  .borderRadius(8)
}

@Builder
function BuildOperResourceMenu(params: MenuParam) {
  Column() {
    if (params.resource.type !== 1) {
      Button('查看学习时长', { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.TEXTUAL })
        .width('100%')
        .fontColor('#FCBB34')
      Divider()
        .color('#33999999')
        .strokeWidth(1)
    }
    if (params.currentTeam?.role ?? 1 !== 1) {
      Button(!!_.trim(params.resource.tag as string) ? '编辑活动标签' : '设置活动标签',
        { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.TEXTUAL })
        .width('100%')
        .fontColor('#40A9FF')
      Divider()
        .color('#33999999')
        .strokeWidth(1)

      if (params.resource.type !== 1) {
        if (params.resource.type !== 11) {
          Button(params.resource.published === 1 ? '修改发布' : '发布任务',
            { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.TEXTUAL })
            .width('100%')
            .fontColor('#40A9FF')
          Divider()
            .color('#33999999')
            .strokeWidth(1)
        }
      }
      if (params.resource.type === 7) {
        Button('编辑作业/测练',
          { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.TEXTUAL })
          .width('100%')
          .fontColor('#40A9FF')
        Divider()
          .color('#33999999')
          .strokeWidth(1)
      }
      if (params.resource.type === 1) {
        Button(getFolderPublicStatus(params.resource as Record<string, string | number>, params.subResources) === 3 ?
          '取消学生可见' : '设置学生可见',
          { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.TEXTUAL })
          .width('100%')
          .fontColor('#40A9FF')
        Divider()
          .color('#33999999')
          .strokeWidth(1)
      } else {
        if (params.resource.type !== 7) {
          Button(params.resource.public === 2 ? '取消学生可见' : '设置学生可见',
            { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.TEXTUAL })
            .width('100%')
            .fontColor('#40A9FF')
          Divider()
            .color('#33999999')
            .strokeWidth(1)
        }
      }
      if (params.resource.type === 1) {
        Button(getFolderDownloadStatus(params.resource as Record<string, string | number>, params.subResources) === 3 ?
          '取消学生可下载' : '允许学生可下载',
          { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.TEXTUAL })
          .width('100%')
          .fontColor('#40A9FF')
        Divider()
          .color('#33999999')
          .strokeWidth(1)
      } else {
        if (params.resource.type === 6 || params.resource.type === 9) {
          Button(params.resource.download === 2 ? '取消学生可下载' : '允许学生可下载',
            { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.TEXTUAL })
            .width('100%')
            .fontColor('#40A9FF')
          Divider()
            .color('#33999999')
            .strokeWidth(1)
        }
      }
      Button('重命名',
        { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.TEXTUAL })
        .width('100%')
        .fontColor('#40A9FF')
      Divider()
        .color('#33999999')
        .strokeWidth(1)
      if (params.resource.type !== 1 && params.resource.type !== 8) {
        Button('文档复制',
          { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.TEXTUAL })
          .width('100%')
          .fontColor('#40A9FF')
        Divider()
          .color('#33999999')
          .strokeWidth(1)
      }
      Button('移动到',
        { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.TEXTUAL })
        .width('100%')
        .fontColor('#40A9FF')
      Divider()
        .color('#33999999')
        .strokeWidth(1)
      if (params.resource.type !== 1) {
        Button('资源二维码',
          { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.TEXTUAL })
          .width('100%')
          .fontColor('#40A9FF')
        Divider()
          .color('#33999999')
          .strokeWidth(1)
      }
      Button('关联知识点',
        { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.TEXTUAL })
        .width('100%')
        .fontColor('#40A9FF')
        .onClick(() => {
          CustomToast.toast_info('移动端暂未开放关联知识点功能，请去web端查看。')
          params.hide()
        })
      Divider()
        .color('#33999999')
        .strokeWidth(1)

      if (params.resource.type !== 1) {
        Button('查看学生问题',
          { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.TEXTUAL })
          .width('100%')
          .fontColor('#40A9FF')
        Divider()
          .color('#33999999')
          .strokeWidth(1)
      }
      Button('删除',
        { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.TEXTUAL })
        .width('100%')
        .fontColor('#FF4040')
      Divider()
        .color('#33999999')
        .strokeWidth(1)
    } else {
      Button('我要提问',
        { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.TEXTUAL })
        .width('100%')
        .fontColor('#40A9FF')
      Divider()
        .color('#33999999')
        .strokeWidth(1)
    }
    Button('取消',
      { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.TEXTUAL })
      .width('100%')
      .fontColor('#999999')
      .onClick(() => {
        params.hide()
      })
  }
  .margin(48)
  .backgroundColor(Color.White)
  .borderRadius(8)
}