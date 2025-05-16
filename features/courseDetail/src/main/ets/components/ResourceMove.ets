import { display } from "@kit.ArkUI"
import _ from "@wolfx/lodash"
import {
  Api_Context,
  AppIcon,
  CustomNavTitle,
  CustomToast,
  getTypeByAssignToType,
  getTypeByTaskType,
  HomeApi,
  IconConstants,
  PreferenceStorage,
  xyApiGet,
  xyApiPost
} from "@xy/basic"

@Component
struct ResourceMove {
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @StorageLink('PreferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage()
  @State screenWidth: number = 0
  @State rootResources: Record<string, string | number | boolean> [] = []
  @State subResources: Record<string, string | number | boolean> [] = []
  @State dataSource: Record<string, string | number | boolean> [] = []
  @State rootSource: Record<string, string | number | boolean> = {}
  @State selectFolder: Record<string, string | number | boolean> | null = null
  private param: Record<string, string | number> = {}
  private courseInfo = this.preferenceStorage.currentTeam ?? {}

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
      this.dataSource = this.rootResources.filter(res => res.type === 1)
    }
  }

  aboutToAppear(): void {
    this.screenWidth = px2vp(display.getDefaultDisplaySync().width)
    this.param = JSON.parse(String(this.pageInfos.getParamByName('resourceMove')[0]))
    this.queryCourseResources()
  }

  handleBack() {
    if (this.selectFolder?.parent_id === this.rootSource.id) {
      this.dataSource = this.rootResources.filter(res => res.type === 1)
      this.selectFolder = null
    } else {
      const resource = this.rootResources.filter(res => res.id === this.selectFolder?.parent_id)
      if (resource.length > 0) {
        this.dataSource =
          this.subResources.filter(res => res.parent_id === resource[0].id).filter(res => res.type === 1)
        this.selectFolder = resource[0]
      } else {
        this.dataSource =
          this.subResources.filter(res => res.parent_id === this.selectFolder?.parent_id).filter(res => res.type === 1)
        this.selectFolder = this.subResources.filter(res => res.id === this.dataSource[0].parent_id)[0]
      }
    }
  }

  async handleMove() {
    if (this.param.type === 1 && this.param.id === this.selectFolder?.id) {
      CustomToast.toast_info('您不能把文件夹移动到它的子文件夹中')
      return
    }
    const target_id = this.selectFolder ? this.selectFolder?.id : this.rootSource.id;
    if (this.param.parent_id === target_id) {
      CustomToast.toast_info('移至目录与源目录相同')
      return
    }
    const response = await xyApiPost(this.Api_Context.getApiPrefix('baseApi_inner') + HomeApi.moveResource, {
      'group_id': this.courseInfo.id,
      'node_ids': [this.param.id],
      'parent_id': target_id,
      'from_parent_id': this.param.parent_id,
    })
    if(response.success) {
      this.pageInfos.pop({ refresh: true })
    }
  }

  build() {
    NavDestination() {
      Column() {
        List() {
          if (this.dataSource.length > 0) {
            ForEach(this.dataSource, (item: Record<string, string | number | boolean>, index: number) => {
              ListItem() {
                Row() {
                  AppIcon({
                    'iconCode': IconConstants.FOLDER,
                    'iconColor': '#FCBB34',
                    'iconSize': 18
                  })
                  Text(String(item.name))
                    .margin({ left: 8, right: 8 })
                    .lineHeight(20)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.MARQUEE })
                }
                .onClick(() => {
                  this.dataSource =
                    this.subResources.filter(res => res.parent_id === item.id).filter(res => res.type === 1)
                  this.selectFolder = item
                })
              }
              .margin({ bottom: 16 })
            })
          } else {
            ListItem() {
              Text('暂无数据')
                .fontColor('#999999')
            }
            .width('100%')
            .margin({ top: 300 })
          }
        }
        .padding(12)
        .flexGrow(1)

        Row() {
          Button({ type: ButtonType.Normal, buttonStyle: ButtonStyleMode.TEXTUAL }) {
            Row() {
              AppIcon({
                'iconCode': IconConstants.FOLDER,
                'iconColor': '#41A9FF',
                'iconSize': 16
              })
              Text('新建文件夹')
                .margin({ left: 4 })
                .fontColor('#41A9FF')
                .fontSize(14)
            }
            .height(40)
          }
          .width((this.screenWidth - 56) / 3)
          .margin({ right: 4 })
          .backgroundColor(Color.White)
          .borderRadius(4)

          if (!!this.selectFolder) {
            Button('上一步', { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.TEXTUAL })
              .width((this.screenWidth - 56) / 3)
              .margin({ right: 4 })
              .backgroundColor('#41A9FF')
              .fontColor(Color.White)
              .fontSize(14)
              .borderRadius(4)
              .onClick(() => this.handleBack())
          }
          if (this.param.parent_id !== this.rootSource.id || !!this.selectFolder) {
            Button('移动到此', { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.TEXTUAL })
              .width((this.screenWidth - 56) / 3)
              .backgroundColor('#41A9FF')
              .fontColor(Color.White)
              .fontSize(14)
              .borderRadius(4)
              .onClick(() => this.handleMove())
          }
        }
        .flexShrink(0)
        .justifyContent(FlexAlign.SpaceBetween)
        .width('100%')
        .padding(12)
      }
      .width(this.screenWidth - 24)
      .height('100%')
      .margin({ left: 12, right: 12 })
      .backgroundColor(Color.White)
    }
    .title(CustomNavTitle('移动资源'))
    .backgroundColor('#f1f1f1')
  }
}

@Builder
export function ResourceMoveBuilder() {
  ResourceMove()
}