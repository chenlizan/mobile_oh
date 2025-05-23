import { ComponentContent, display, LengthMetrics, window } from "@kit.ArkUI"
import _ from "@wolfx/lodash"
import {
  Api_Context,
  AppIcon,
  CCApi,
  ccApiPost,
  CustomAlertDialog,
  CustomModalDialog,
  CustomTag,
  CustomToast,
  getAllSubResources,
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
  navigateToResourceDetails,
  PreferenceStorage,
  regularFilename,
  UploadResources,
  UserInfoModel,
  verifyNameIsSpecial,
  xyApiGet,
  xyApiPost
} from "@xy/basic"
import { pasteboard } from "@kit.BasicServicesKit"

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
  @State activityTags: Record<string, string>[] = []
  @State tagTitle: string = '设置活动标签'
  @State tagVisible: boolean = false
  @State tagEdit: boolean = false
  @State tagValue: string = ''
  @State tagNodeId: string = ''
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

  async queryActivityTags() {
    const response = await xyApiGet(this.Api_Context.getApiPrefix('baseApi_inner') + HomeApi.getActivityTags)
    if (response.success) {
      this.activityTags = response.data as Record<string, string>[]
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
        'name': regularFilename(name, this.rootResources as Record<string, string>[]),
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
      _.map(this.rootResources, (r, i) => {
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
    this.queryActivityTags()
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
                      this.pageInfos.pushPath({ name: 'courseQrcode', param: JSON.stringify(this.courseInfo) })
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

              Column() {
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
                .margin({ top: 12 })
                .visibility(_.isEmpty(this.siteCerts) ? Visibility.None : Visibility.Visible)

                Row() {
                  Text(String(this.courseInfo.teacher_names))
                    .fontColor(Color.White)
                    .fontSize(14)
                    .width('100%')
                    .margin({ top: 12 })
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.MARQUEE })
                }
              }
              .height(64)

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
                    iconColor: Color.White,
                    iconSize: 14
                  })
                }
                .onClick(() => {
                  this.pageInfos.pushPath({ name: 'browseHistory', param: JSON.stringify(this.courseInfo) })
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
                      .onClick(() => {
                        switch (this.funcItems[4 * paper+index]?.type) {
                          case 'notice':
                            this.pageInfos.pushPath({ name: 'noticeList' })
                            break
                        }
                      })
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
                ForEach(this.rootResources, (item: Record<string, string | number | boolean>, index: number) => {
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
                      this.BuildExtendEnd(this.rootResources.length, index, item)
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
    .hideTitleBar(true)
    .backgroundColor("#f1f1f1")
  }
}

@Builder
export function CourseDetailPageBuilder() {
  CourseDetailPage()
}

export class MenuParam {
  currentTeam: Record<string, string | number | boolean> = {}
  subResources: Record<string, string | number | boolean> [] = []
  resource: Record<string, string | number | boolean> = {}
  codeStr: string = ''
  isEdit: boolean = false
  addResource: (type: number, name: string) => void = () => {
  }
  operResource: (name: string, param?: boolean | number) => void = () => {
  }
  hide: () => void = () => {
  }
  onClickBtn: () => void = () => {
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
export function BuildAddResourceMenu(params: MenuParam) {
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
      .onClick(() => params.addResource(8, '讨论'))
    Divider()
      .color('#33999999')
      .strokeWidth(1)
    Button('教学设计', { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.TEXTUAL })
      .width('100%')
      .fontColor('#40A9FF')
      .onClick(() => params.addResource(11, '教学设计'))
    Divider()
      .color('#33999999')
      .strokeWidth(1)
    Button('本地资源', { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.TEXTUAL })
      .width('100%')
      .fontColor('#40A9FF')
      .onClick(() => params.addResource(6, '本地资源'))
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
export function BuildOperResourceMenu(params: MenuParam) {
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
        .onClick(() => params.operResource('活动标签', !!_.trim(params.resource.tag as string)))
      Divider()
        .color('#33999999')
        .strokeWidth(1)

      if (params.resource.type !== 1) {
        if (params.resource.type !== 11) {
          Button(params.resource.published === 1 ? '修改发布' : '发布任务',
            { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.TEXTUAL })
            .width('100%')
            .fontColor('#40A9FF')
            .enabled(false)
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
          .onClick(() => params.operResource('编辑作业/测练'))
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
          .onClick(() => params.operResource('可见',
            getFolderPublicStatus(params.resource as Record<string, string | number>,
              params.subResources) !== 3))
        Divider()
          .color('#33999999')
          .strokeWidth(1)
      } else {
        if (params.resource.type !== 7) {
          Button(params.resource.public === 2 ? '取消学生可见' : '设置学生可见',
            { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.TEXTUAL })
            .width('100%')
            .fontColor('#40A9FF')
            .onClick(() => params.operResource('可见', params.resource.public !== 2))
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
          .onClick(() => params.operResource('下载',
            getFolderDownloadStatus(params.resource as Record<string, string | number>, params.subResources) === 3 ? 1 :
              2))
        Divider()
          .color('#33999999')
          .strokeWidth(1)
      } else {
        if (params.resource.type === 6 || params.resource.type === 9) {
          Button(params.resource.download === 2 ? '取消学生可下载' : '允许学生可下载',
            { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.TEXTUAL })
            .width('100%')
            .fontColor('#40A9FF')
            .onClick(() => params.operResource('下载', params.resource.download === 2 ? 1 : 2))
          Divider()
            .color('#33999999')
            .strokeWidth(1)
        }
      }
      Button('重命名',
        { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.TEXTUAL })
        .width('100%')
        .fontColor('#40A9FF')
        .onClick(() => params.operResource('重命名'))
      Divider()
        .color('#33999999')
        .strokeWidth(1)
      if (params.resource.type !== 1 && params.resource.type !== 8) {
        Button('文档复制',
          { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.TEXTUAL })
          .width('100%')
          .fontColor('#40A9FF')
          .onClick(() => params.operResource('文档复制'))
          .enabled(false)
        Divider()
          .color('#33999999')
          .strokeWidth(1)
      }
      Button('移动到',
        { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.TEXTUAL })
        .width('100%')
        .fontColor('#40A9FF')
        .onClick(() => params.operResource('移动到'))
      Divider()
        .color('#33999999')
        .strokeWidth(1)
      if (params.resource.type !== 1) {
        Button('资源二维码',
          { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.TEXTUAL })
          .width('100%')
          .fontColor('#40A9FF')
          .onClick(() => params.operResource('资源二维码'))
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
          .onClick(() => params.operResource('查看学生问题'))
        Divider()
          .color('#33999999')
          .strokeWidth(1)
      }
      Button('删除',
        { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.TEXTUAL })
        .width('100%')
        .fontColor('#FF4040')
        .onClick(() => params.operResource('删除'))
      Divider()
        .color('#33999999')
        .strokeWidth(1)
    } else {
      Button('我要提问',
        { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.TEXTUAL })
        .width('100%')
        .fontColor('#40A9FF')
        .onClick(() => params.operResource('我要提问'))
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

@Builder
export function BuildResourceLinkModal(params: MenuParam) {
  Column() {
    Text('课程资源链接')
      .margin(12)
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
    Divider()
      .flexShrink(0)
      .color('#33999999')
      .strokeWidth(1.1)
      .padding({ left: 16, right: 16 })

    Text(params.resource.name as string)
      .margin(10)
    QRCode(params.codeStr).width(240).height(240)
    Row() {
      Text('*可以复制链接在浏览器打开，或者用小雅App扫码查看。如果教师没有公开资源，可能无法查看')
        .fontColor('#d9999999')
        .fontSize(13)
    }
    .margin(16)

    Row() {
      Button('复制链接', { type: ButtonType.Normal })
        .width(120)
        .backgroundColor('#40A9FF')
        .borderRadius(4)
        .fontColor(Color.White)
        .onClick(() => {
          const pasteData: pasteboard.PasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, params.codeStr)
          const systemPasteboard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard()
          systemPasteboard.setData(pasteData, (err, data) => {
            if (err) {
              return
            }
            CustomToast.toast_success('复制链接成功')
          })
        })
      Button('关闭', { type: ButtonType.Normal })
        .width(120)
        .margin({ left: 12 })
        .backgroundColor('#F5F5F5')
        .borderRadius(4)
        .fontColor('#999999')
        .onClick(() => params.hide())
    }
    .margin({ bottom: 16 })
  }
  .margin({ left: 16, right: 16 })
  .backgroundColor(Color.White)
}

@Builder
export function BuildRenameModal(params: MenuParam) {
  Column() {
    Row() {
      Text('重命名')
        .margin(12)
    }

    Divider()
      .flexShrink(0)
      .color('#33999999')
      .strokeWidth(1.1)

    TextArea({ placeholder: '请输入名字', text: params.resource.name as string })
      .height(120)
      .margin(12)
      .backgroundColor(Color.White)
      .borderColor('#d9d9d9')
      .borderRadius(4)
      .borderWidth(1)
      .placeholderColor('#999999')
      .maxLength(255)
      .onChange((value: string) => params.operResource(value))

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
          if (params.hide) {
            params.hide()
          }
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
        .onClick(() => {
          if (params.onClickBtn) {
            params.onClickBtn()
          }
          if (params.hide) {
            params.hide()
          }
        })
    }
    .width('100%')
  }
  .height(220)
  .margin(16)
  .borderRadius(8)
  .backgroundColor(Color.White)
}