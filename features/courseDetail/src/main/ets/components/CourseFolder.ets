import { ComponentContent, display, LengthMetrics, window } from "@kit.ArkUI"
import _ from "@wolfx/lodash"
import {
  Api_Context,
  AppIcon,
  CustomAlertDialog,
  CustomNavTitle,
  CustomTag,
  CustomToast,
  getTypeByAssignToType,
  getTypeByTaskType,
  getIconByFileType,
  HomeApi,
  IconConstants,
  judgeGroupIsEnd,
  judgeRoleHasCourseOperationWeight,
  PreferenceStorage,
  regularFilename,
  UploadResources,
  xyApiGet,
  xyApiPost,
  getFolderPublicStatusText,
  getFolderDownloadStatusText,
  navigateToResourceDetails,
  getAllSubResources,
  UserInfoModel,
  verifyNameIsSpecial,
  CustomModalDialog
} from "@xy/basic"
import {
  BuildAddResourceMenu,
  BuildOperResourceMenu,
  BuildRenameModal,
  BuildResourceLinkModal,
  MenuParam
} from "./CourseDetailPage"

@Component
struct CourseFolder {
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @StorageLink('PreferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage()
  @StorageLink('UserInfo') userInfo: UserInfoModel = new UserInfoModel()
  @State screenWidth: number = 0
  @State isRefreshing: boolean = false
  @State currentCourse: Record<string, string | number | boolean> = {}
  @State subResources: Record<string, string | number | boolean> [] = []
  @State activityTags: Record<string, string>[] = []
  @State tagTitle: string = '设置活动标签'
  @State tagVisible: boolean = false
  @State tagEdit: boolean = false
  @State tagValue: string = ''
  @State tagNodeId: string = ''
  private courseInfo = this.preferenceStorage.currentTeam ?? {}
  private rootSource: Record<string, string | number | boolean> = {}
  private param: Record<string, string> = {}

  async queryActivityTags() {
    const response = await xyApiGet(this.Api_Context.getApiPrefix('baseApi_inner') + HomeApi.getActivityTags)
    if (response.success) {
      this.activityTags = response.data as Record<string, string>[]
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
      this.rootSource = this.param
      this.subResources = _.filter(
        real_resources,
        res => res.parent_id !== rootSource.id,
      )
    }
  }

  async createCourseResource(type: number, name: string) {
    const canOperation = judgeRoleHasCourseOperationWeight(Number(this.courseInfo?.role ?? 1))
    if (!canOperation && !_.isEmpty(this.courseInfo) && judgeGroupIsEnd(this.courseInfo as Record<string, string>)) {
      return
    }
    const body: Record<string, string | number | Record<string, string | number | boolean | Array<Record<string, string>>>> =
      {
        'group_id': String(this.courseInfo.id),
        'parent_id': String(this.rootSource.id),
        'name': regularFilename(name, this.subResources as Record<string, string>[]),
        'type': type
      }
    const addResource = async () => {
      const response = await xyApiPost(this.Api_Context.getApiPrefix('baseApi_inner') + HomeApi.addResource, body)
      if (response.success) {
        this.queryCourseResources()
        if (type === 7) {
          CustomToast.toast_success('资源创建成功')
        } else {
          CustomToast.toast_success(
            `资源创建成功${
            this.courseInfo?.is_resource_auto_public ? '，已设置学生可见' : ''
            }`)
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
      case 6:
        UploadResources((file) => {
          body.name = file.filename as string
          body.resource = {
            'files': [{
              'id': file.id,
              'filename': file.filename,
              'mimetype': file.mimetype
            } as Record<string, string>]
          }
          addResource()
        })
        break
      case 8:
        this.pageInfos.pushPath({
          name: 'createDiscuss', param: JSON.stringify({
            isSubGroup: false,
            group_id: String(this.courseInfo.id),
            parent_id: String(this.rootSource.id),
            courseInfo: this.courseInfo
          }), onPop: () => {
            this.queryCourseResources()
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

  async moveCourseResource(original_index: number, target_index: number,
    item: Record<string, string | number | boolean>) {
    const sort_content = _.map(
      _.map(this.subResources, (r, i) => {
        r.sort_position = i
        return r
      }),
      (node: Record<string, number>) => {
        if (item.id === node.id) {
          node.sort_position = target_index
        } else {
          if (target_index > original_index) {
            if (
              node.sort_position > original_index &&
                node.sort_position <= target_index
            ) {
              node.sort_position = node.sort_position - 1
            }
          } else {
            if (
              node.sort_position < original_index &&
                node.sort_position >= target_index
            ) {
              node.sort_position = node.sort_position + 1
            }
          }
        }
        return {
          'node_id': node.id,
          'sort_position': node.sort_position,
        } as Record<string, string | number>
      },
    )
    const response = await xyApiPost(this.Api_Context.getApiPrefix('baseApi_inner') + HomeApi.sortResource, {
      'group_id': String(this.courseInfo.id),
      'sort_content': JSON.stringify(sort_content),
    })
    if (response.success) {
      this.queryCourseResources()
    }
  }

  async deleteCourseResource(item: Record<string, string | number | boolean>) {
    const canDelete =
      this.userInfo.id === item.creator || judgeRoleHasCourseOperationWeight(Number(this.courseInfo?.role ?? 1))
    if (canDelete) {
      CustomAlertDialog({
        title: '提示',
        message: `是否确定删除《${item.name}》？课程内的资源删除后无法找回，发布的任务会被取消，请谨慎操作`,
        onClickBtn: async () => {
          if (judgeGroupIsEnd(this.courseInfo as Record<string, string>)) {
            return
          }
          const isFile = item.type === 1
          if (isFile) {
            let sub_nodes = []
            getAllSubResources(item as Record<string, string | number>, this.subResources, sub_nodes)
            if (_.filter(sub_nodes, (node: Record<string, number>) => node.published === 1).length > 0) {
              CustomToast.toast_fail('文件夹中存在已发布的资源，需要撤销所有已发布的任务才能删除')
              return
            }
          } else {
            if (item.published === 1) {
              const response =
                await xyApiPost(this.Api_Context.getApiPrefix('baseApi_inner') + HomeApi.revokePublishRecord, {
                  'group_id': item.group_id,
                  'activity_node_ids': item.id,
                })
              if (!response.success) {
                CustomToast.toast_fail('删除失败')
                return
              }
            }
          }
          const response = await xyApiPost(this.Api_Context.getApiPrefix('baseApi_inner') + HomeApi.delResource,
            { 'node_id': item.id, 'group_id': item.group_id })
          if (response.success) {
            this.queryCourseResources()
          }
        }
      })
    } else {
      CustomAlertDialog({
        title: '提示',
        message: '无法删除该资源，仅该资源的创建者或主讲教师才有权限删除'
      })
    }
  }

  async viewQAArea(item: Record<string, string | number | boolean>) {
    if (item && (this.courseInfo?.role ?? 1) === 1 &&
    judgeGroupIsEnd(this.courseInfo as Record<string, string>, false)) {
      CustomToast.toast_info('课程已结束，您只能查看答疑区内容')
      return
    }
    this.pageInfos?.pushPath({
      name: 'qaAreaResource',
      param: JSON.stringify({
        loginRole: this.courseInfo?.role ?? 1,
      })
    })
  }

  async viewResourceLinkModal(item: Record<string, string | number | boolean>) {
    const windowClass = await window.getLastWindow(getContext())
    const uiContext = windowClass.getUIContext()
    const params = new MenuParam()
    params.hide = () => {
      if (promptAction && customDialog) {
        promptAction.closeCustomDialog(customDialog)
        customDialog.dispose()
      }
    }
    params.resource = item
    params.codeStr =
      `${this.Api_Context.getApiPrefix('base_homepage')}mycourse/${item.group_id}/resource/${item.parent_id}/${item.id}`
    const customDialog = new ComponentContent(uiContext, wrapBuilder(BuildResourceLinkModal), params)
    const promptAction = uiContext.getPromptAction()
    promptAction.openCustomDialog(customDialog)
  }

  async viewRenameModal(item: Record<string, string | number | boolean>) {
    const windowClass = await window.getLastWindow(getContext())
    const uiContext = windowClass.getUIContext()
    const params = new MenuParam()
    let newName = ''
    params.hide = () => {
      if (promptAction && customDialog) {
        promptAction.closeCustomDialog(customDialog)
        customDialog.dispose()
      }
    }
    params.resource = item
    params.operResource = (value: string) => {
      newName = value
    }
    params.onClickBtn = async () => {
      if (!_.trim(newName)) {
        CustomToast.toast_info('请输入名字')
        return
      }
      if (newName.length > 255) {
        CustomToast.toast_fail('资源名称不能超过255个字符')
        return
      }
      if (verifyNameIsSpecial(newName)) {
        CustomToast.toast_fail('资源名称中不能包含\\ : * ? " < > | 等特殊字符')
        return
      }
      const response = await xyApiPost(this.Api_Context.getApiPrefix('baseApi_inner') + HomeApi.updateResource, {
        'node_id': item.id,
        'group_id': item.group_id,
        'name': newName,
      })
      if (response.success) {
        this.queryCourseResources()
      }
    }
    const customDialog = new ComponentContent(uiContext, wrapBuilder(BuildRenameModal), params)
    const promptAction = uiContext.getPromptAction()
    promptAction.openCustomDialog(customDialog, { autoCancel: false })
  }

  async downloadSetup(item: Record<string, string | number | boolean>, param: number) {
    const reqFun = async () => {
      const response =
        await xyApiPost(this.Api_Context.getApiPrefix('baseApi_inner') + HomeApi.updateResourceAttribute, {
          'node_id': item.id,
          'group_id': item.group_id,
          'download': param,
        })
      if (response.success) {
        if (param === 1) {
          CustomToast.toast_success('取消学生可下载设置成功')
        } else {
          CustomToast.toast_success('允许学生可下载设置成功')
        }
        this.queryCourseResources()
      }
    }
    const sub_nodes: Record<string, string | number | boolean>[] = []
    const getAllSubFileResourcesAndDepth = (item: Record<string, string | number | boolean>) => {
      let maxFoldersDepth: number = 0
      if (item.type === 1) {
        const resource = _.filter(this.subResources, { parent_id: item.id })
        if (resource) {
          _.forEach(resource, item => {
            if (item.type === 1) {
              maxFoldersDepth = Math.max(maxFoldersDepth, getAllSubFileResourcesAndDepth(item))
            } else {
              if (item.type === 6 || item.type === 9 || item.type === 10) {
                sub_nodes.push(item)
              }
            }
          })
        }
      }
      return maxFoldersDepth + 1
    }
    if (item.type === 1) {
      CustomAlertDialog({
        title: '请确认',
        message: param === 2 ?
          '设置文件夹为【允许学生可下载】仅将文件夹内已有的资源设置为允许学生下载，该设置对此后新创建或上传的资源无效' :
          '是否确认将文件夹内的资源设置为学生不可下载？',
        onClickBtn: () => {
          const maxFoldersDepth = getAllSubFileResourcesAndDepth(item)
          if (sub_nodes.length > 500) {
            CustomToast.toast_fail('批量设置文件数量超出限制')
            return
          }
          if (maxFoldersDepth > 100) {
            CustomToast.toast_fail('批量设置文件夹层级数超出限制')
            return
          }
          reqFun()
        }
      })
    } else {
      reqFun()
    }
  }

  async visibleSetup(item: Record<string, string | number | boolean>, param: boolean) {
    const reqFun = async () => {
      const nodeIds: string[] = []
      const targets = _.filter(sub_nodes, res => res.type !== 7)
      targets.forEach(node => {
        nodeIds.push(String(node.id))
      })
      if (_.isEmpty(nodeIds) && item.type === 1) {
        CustomToast.toast_fail('所选资源均不支持学生可见功能')
        return
      }
      const response = await xyApiPost(this.Api_Context.getApiPrefix('baseApi_inner') + HomeApi.publicResources, {
        'activity_node_ids': nodeIds.join(','),
        'group_id': item.group_id,
        'pub': param ? 2 : 1,
      })
      if (response.success) {
        if (_.isEmpty(response.data)) {
          CustomToast.toast_success('资源已不存在，请刷新后操作')
          return
        }
        if (item.type === 1 && param) {
          CustomToast.toast_success('文件夹设置学生可见成功')
        } else {
          CustomToast.toast_success('设置成功')
        }
        this.queryCourseResources()
      }
    }
    if (judgeGroupIsEnd(this.courseInfo as Record<string, string>)) {
      return
    }
    let isSub = false
    const sub_nodes: Record<string, string | number | boolean>[] = []
    const getAllSubResources = (item: Record<string, string | number | boolean>) => {
      if (item.type === 1) {
        const resource = _.filter(this.subResources, { parent_id: item.id })
        if (resource) {
          _.forEach(resource, item => {
            if (item.type === 1) {
              getAllSubResources(item)
            } else {
              sub_nodes.push(item)
            }
          })
        }
      }
    }
    if (item.type === 1) {
      isSub = true
      getAllSubResources(item)
    } else {
      sub_nodes.push(item)
    }
    if (item.type === 1) {
      CustomAlertDialog({
        title: '请确认',
        message: param ?
          '1.对文件夹【设置学生可见】只是对文件夹内的课件资源进行批量设置，之后再创建的新资源并非学生可见。\n' +
            '2.作业/测练必须发布任务后学生才能查看与参与，无法设置学生可见' :
          '是否确认将文件夹内的资源设置为学生不可见？',
        onClickBtn: () => {
          reqFun()
        }
      })
    } else {
      reqFun()
    }
  }

  async operateCourseResource(name: string, item: Record<string, string | number | boolean>, param?: boolean | number) {
    switch (name) {
      case '删除':
        this.deleteCourseResource(item)
        break
      case '查看学生问题':
      case '我要提问':
        this.viewQAArea(item)
        break
      case '资源二维码':
        this.viewResourceLinkModal(item)
        break
      case '移动到':
        this.pageInfos.pushPath({
          name: 'resourceMove', param: JSON.stringify(item), onPop: () => {
            this.queryCourseResources()
          }
        })
      case '重命名':
        this.viewRenameModal(item)
        break
      case '下载':
        this.downloadSetup(item, param as number)
        break
      case '可见':
        this.visibleSetup(item, param as boolean)
        break
      case '编辑作业/测练':
        this.pageInfos.pushPath({
          name: 'questionEditorResource', param: JSON.stringify({ item }), onPop: () => {
            this.queryCourseResources()
          }
        })
        break
      case '活动标签':
        this.tagVisible = true
        this.tagEdit = param as boolean
        this.tagTitle = `${this.tagEdit ? '编辑' : '设置'}活动标签`
        this.tagValue = this.tagEdit ? String(item.tag) : ''
        this.tagNodeId = item.id as string
        break
      default:
        break
    }
  }

  aboutToAppear(): void {
    this.screenWidth = px2vp(display.getDefaultDisplaySync().width)
    this.param =
      JSON.parse(String(this.pageInfos.getParamByName('courseFolder')[this.pageInfos.getParamByName('courseFolder')
        .length-1]))
    this.queryCourseResources()
    this.queryCurrentCourse()
    this.queryActivityTags()
  }

  @Builder
  BuildExtendEnd(length: number, index: number, item: Record<string, string | number | boolean>) {
    Row() {
      Button('移动到', { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.TEXTUAL })
        .height('100%')
        .backgroundColor('#41A9FF')
        .fontColor(Color.White)
        .fontSize(13)
        .onClick(() => {
          this.pageInfos.pushPath({
            name: 'resourceMove', param: JSON.stringify(item), onPop: () => {
              this.queryCourseResources()
            }
          })
        })
      if (index !== 0) {
        Button('置顶', { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.TEXTUAL })
          .height('100%')
          .backgroundColor('#63BDFF')
          .fontColor(Color.White)
          .fontSize(13)
          .onClick(() => this.moveCourseResource(index, 0, item))
        Button('上移', { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.TEXTUAL })
          .height('100%')
          .backgroundColor('#83D0FF')
          .fontColor(Color.White)
          .fontSize(13)
          .onClick(() => this.moveCourseResource(index, index - 1, item))
      }
      if (index !== (length - 1)) {
        Button('下移', { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.TEXTUAL })
          .height('100%')
          .backgroundColor('#A5DFFF')
          .fontColor(Color.White)
          .fontSize(13)
          .onClick(() => this.moveCourseResource(index, index + 1, item))
      }
    }
    .height('100%')
  }

  @Builder
  BuildTagContent() {
    Row() {
      Text('活动标签:')
      Select(this.activityTags.map((item) => {
        return { 'value': item.title } as SelectOption
      }))
        .value(_.find(this.activityTags, { 'title': this.tagValue })?.title ?? '请选择')
        .onSelect((index: number) => {
          this.tagValue = this.activityTags[index].title
        })
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .padding({ left: 16, right: 16, top: 16 })

    Column() {
      TextInput({ placeholder: '请输入自定义活动标签', text: this.tagValue })
        .showUnderline(true)
        .underlineColor({ typing: '#40A9FF' })
        .onChange((value: string) => {
          this.tagValue = value
        })
      if (!_.trim(this.tagValue) && this.tagEdit) {
        Text('标签内容为空时，点击确定会删除标签')
          .fontColor('#FF4040')
          .padding(12)
      }
    }
    .padding(16)

    Row() {
      Button('取消', { type: ButtonType.Normal })
        .height(40)
        .fontColor('#999999')
        .backgroundColor(Color.White)
        .borderWidth({ top: 1 })
        .borderColor('#33999999')
        .borderRadius({
          topLeft: 0,
          topRight: 0,
          bottomLeft: 8,
          bottomRight: 0
        })
        .flexGrow(1)
        .onClick(() => {
          this.tagVisible = false
        })
      Button('确定', { type: ButtonType.Normal })
        .height(40)
        .backgroundColor('#40A9FF')
        .borderWidth({ top: 1 })
        .borderColor('#40A9FF')
        .borderRadius({
          topLeft: 0,
          topRight: 0,
          bottomLeft: 0,
          bottomRight: 8
        })
        .flexGrow(1)
        .onClick(async () => {
          const response = await xyApiPost(this.Api_Context.getApiPrefix('baseApi_inner') + HomeApi.updateResource, {
            'node_id': this.tagNodeId,
            'group_id': String(this.courseInfo.id),
            'tag': this.tagValue,
          })
          if (response.success) {
            this.queryCourseResources()
          }
          this.tagVisible = false
        })
    }
    .width('100%')
  }

  build() {
    NavDestination() {
      Flex({ direction: FlexDirection.Column }) {
        Flex({ direction: FlexDirection.Column }) {
          Column() {
            Refresh({ refreshing: $$this.isRefreshing }) {
              List() {
                ForEach(_.filter(this.subResources, res => res.parent_id === this.rootSource.id),
                  (item: Record<string, string | number | boolean>, index: number) => {
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
                              params.operResource = (name: string, param?: boolean | number) => {
                                this.operateCourseResource(name, item, param)
                                params.hide()
                              }
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
                              CustomTag({
                                text: String(item._taskTypeText), tagMargin: { right: 8 }, onClickBtn: () => {
                                  // this.pageInfos.pushPath({ name: 'taskDetails' }) TODO
                                }
                              })
                            } else {
                              CustomTag({
                                text: String(item._taskTypeText),
                                tagBorderColor: '#40A9FF',
                                fontColor: '#40A9FF',
                                tagMargin: { right: 8 },
                                onClickBtn: () => {
                                  // this.pageInfos.pushPath({ name: 'taskDetails' }) TODO
                                }
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
                    .onClick(() => {
                      if (item.type === 1) {
                        this.pageInfos.pushPath({
                          name: 'courseFolder', param: JSON.stringify(item), onPop: () => {
                            this.queryCourseResources()
                          }
                        })
                      } else {
                        navigateToResourceDetails(item as Record<string, string | number>,
                          Number(this.courseInfo?.role ?? 1))
                      }
                    })
                    .swipeAction({
                      end: () => {
                        this.BuildExtendEnd(this.subResources.length, index, item)
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

      CustomModalDialog({
        title: this.tagTitle,
        visible: $tagVisible,
        hideCloseBtn: Visibility.Hidden,
        contentBuilder: () => this.BuildTagContent()
      })
    }
    .title(CustomNavTitle(this.param.name))
    .backgroundColor('#f1f1f1')
  }
}

@Builder
export function CourseFolderBuilder() {
  CourseFolder()
}