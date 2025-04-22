import { componentUtils } from '@kit.ArkUI'
import _ from '@wolfx/lodash'
import { Api_Context, AppIcon, CustomModalDialog, CustomTag, HomeApi, IconConstants, xyApiGet } from '@xy/basic'

@Component
struct PaperKnowledgeModal {
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @Link @Watch("visibleChange") visible: boolean
  @Link group_id: string
  @Link paper_id: string
  @Link type: string
  @Link item: Record<string, string>
  @State title: string = ''
  @State dataSource: Record<string, Record<string, string>[]> = {}

  async getSurveyKnowledgeBind() {
    const response = await xyApiGet(this.Api_Context.getApiPrefix('baseApi_inner') + HomeApi.getSurveyKnowledgeBind, {
      'group_id': this.group_id,
      'paper_id': this.paper_id,
      'knowledge_id': this.item.id,
    })
    if (response.success) {
      this.dataSource = (response.data ?? []) as Record<string, Record<string, string>[]>
    }
  }

  visibleChange() {
    if (this.visible) {
      const text = this.item.title?.length > 6 ? this.item.title.slice(0, 6) + '...' : this.item.title
      this.title = `“${text}”与试题对应`
      this.getSurveyKnowledgeBind()
    }
  }

  @Builder
  BuildModalContent() {
    Column() {
      List() {
        ForEach(this.dataSource.question_types, (item: Record<string, string | number | Record<string, string>[]>) => {
          ListItem() {
            Column() {
              Row() {
                Text(`题型：${QuestionTypeInfo(item.type as number)?.text ?? ''}`)
                  .fontColor('#999999')
                  .fontSize(14)
                  .lineHeight(18)
                Text(`总分：${item.total_score ?? 0}`)
                  .fontColor('#999999')
                  .fontSize(14)
                  .lineHeight(18)
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceBetween)

              Row() {
                Text(`题号：${_.map(item.questions as Record<string, string>[], q => q.no).join('、')}`)
                  .fontColor('#999999')
                  .fontSize(14)
                  .lineHeight(18)
                Text()
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceBetween)
            }
            .padding(10)
            .backgroundColor('#EBEDF0')
            .borderRadius(4)
          }
          .padding(16)
        })
      }
      .width('100%')
      .height(180)

      Text(`总计：该知识点共包含${this.dataSource.count ?? 0}道题，涉及分数${this.dataSource.total_score ?? 0}分。`)
        .padding({ left: 16, right: 16 })
    }

  }

  @Builder
  BuildModalFooter() {
    Row() {
      Text('知道了')
        .padding(10)
        .fontColor('#40A9FF')
        .onClick(() => {
          this.visible = false
        })
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .borderWidth({ top: 1 })
    .borderColor('#33999999')
  }

  build() {
    CustomModalDialog({
      visible: $visible,
      title: this.title,
      dialogHeight: 300,
      contentBuilder: () => this.BuildModalContent(),
      footerBuilder: () => this.BuildModalFooter()
    })
  }
}

@Component
struct KnowledgeModal {
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @Link @Watch("visibleChange") visible: boolean
  @Link group_id: string
  @Link type: string
  @Link item: Record<string, string>
  @State title: string = ''
  @State knowledge: Record<string, string> = {}

  async getLabelKgs() {
    const response = await xyApiGet(this.Api_Context.getApiPrefix('baseApi_inner') + HomeApi.getLabelKgs, {
      'group_id': this.group_id,
      'label_id': this.item.id,
    })
    if (response.success) {
      this.initData(this.type, this.item, (response.data ?? []) as Record<string, string>)
    }
  }

  async getKnowledgeKgs() {
    const response = await xyApiGet(this.Api_Context.getApiPrefix('baseApi_inner') + HomeApi.getKnowledgeKgs, {
      'group_id': this.group_id,
      'knowledge_id': this.item.id,
    })
    if (response.success) {
      this.initData(this.type, this.item, (response.data ?? []) as Record<string, string>)
    }
  }

  initData(type: string, item: Record<string, string>, data: Record<string, string>) {
    if (!_.isEmpty(data)) {
      item.kg_name = _.map(data, (i: Record<string, string>) => i.name).join('，')
    } else {
      item.kg_name = ''
    }
    this.knowledge = item
  }

  visibleChange() {
    if (this.visible) {
      if (this.type === 'label') {
        this.getLabelKgs()
      } else if (this.type === 'knowledge') {
        this.getKnowledgeKgs()
      }
      this.title = `${this.type === 'knowledge' ? '知识点' : '标签'}详情`
    }
  }

  @Builder
  BuildModalContent() {
    Column() {
      Text(`${this.type === 'knowledge' ? '知识点' : '标签'}名称：${this.knowledge.title}`)
        .fontColor('#999999')
        .lineHeight(20)
      Text(`${this.type === 'knowledge' ? '知识点' : '标签'}ID：${this.knowledge.id}`)
        .fontColor('#999999')
        .lineHeight(20)
      Text(`所属图谱：${this.knowledge.kg_name}`)
        .fontColor('#999999')
        .lineHeight(20)
    }
    .alignItems(HorizontalAlign.Start)
    .padding(16)
  }

  @Builder
  BuildModalFooter() {
    Row() {
      Text('知道了')
        .padding(10)
        .fontColor('#40A9FF')
        .onClick(() => {
          this.visible = false
        })
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .borderWidth({ top: 1 })
    .borderColor('#33999999')
  }

  build() {
    CustomModalDialog({
      visible: $visible,
      title: this.title,
      dialogHeight: 300,
      contentBuilder: () => this.BuildModalContent(),
      footerBuilder: () => this.BuildModalFooter()
    })
  }
}

@Component
export struct KnowledgeBar {
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @Prop item: Record<string, string | number>
  @Prop loginRole: number
  @State tabArray: Array<string> = ['知识点', '标签']
  @State currentIndex: number = 0
  @State indicatorLeftMargin: number = 16
  @State indicatorWidth: number = 0
  @State knowledge: Array<string> = []
  @State tags: Array<string> = []
  onCloseBtn: () => void = () => {
    this.dialogController.close()
  }
  dialogController: CustomDialogController = new CustomDialogController({
    builder: LeftTab({
      onCloseBtn: this.onCloseBtn,
      tabArray: $tabArray,
      currentIndex: $currentIndex,
      indicatorLeftMargin: $indicatorLeftMargin,
      indicatorWidth: $indicatorWidth,
      paper_id: this.item.paper_id as string,
      group_id: this.item.group_id as string,
      knowledge: this.knowledge,
      tags: this.tags
    }),
    alignment: DialogAlignment.Bottom,
    customStyle: true,
    cancel: () => this.dialogController.close(),
    closeAnimation: { duration: 0 }
  })

  aboutToAppear(): void {
    this.getResourceKnowledge()
    this.getResourceBindTag()
  }

  async getResourceKnowledge() {
    const response = await xyApiGet(this.Api_Context.getApiPrefix('baseApi_inner') + HomeApi.getResourceKnowledge, {
      'group_id': this.item.group_id,
      'activity_node_id': this.item.node_id,
    })
    if (response.success) {
      const result = response?.data ?? []
      const text_knows = _.filter(result, (i: Record<string, string>) => _.isEmpty(i.kg_ids))
      const atlas_knows = _.filter(result, (i: Record<string, string>) => !_.isEmpty(i.kg_ids))
      this.knowledge = [...atlas_knows, ...text_knows]
    }
  }

  async getResourceBindTag() {
    const response = await xyApiGet(this.Api_Context.getApiPrefix('baseApi_inner') + HomeApi.getResourceBindTag, {
      'group_id': this.item.group_id,
      'activity_node_id': this.item.node_id,
    })
    if (response.success) {
      const result = response?.data ?? []
      const no_bind_tags = _.filter(result, (i: Record<string, string>) => _.isEmpty(i.kg_ids))
      const bind_tags = _.filter(result, (i: Record<string, string>) => !_.isEmpty(i.kg_ids))
      this.tags = [...bind_tags, ...no_bind_tags]
    }
  }

  @Builder
  tab(tabName: string, tabIndex: number) {
    Row() {
      Text(tabName)
        .fontSize(16)
        .lineHeight(22)
        .fontColor(tabIndex === this.currentIndex ? '#000000' : '#999999')
        .id(tabIndex.toString())
        .onAreaChange((_, newValue: Area) => {
          if (this.currentIndex === tabIndex && (this.indicatorLeftMargin === 0 || this.indicatorWidth === 0)) {
            let positionX: number
            let width: number = Number.parseFloat(newValue.width.toString())
            if (newValue.position.x !== undefined) {
              positionX = Number.parseFloat(newValue.position.x?.toString())
              this.indicatorLeftMargin = Number.isNaN(positionX) ? 0 : positionX + 16
            }
            this.indicatorWidth = width
          }
        })
    }
    .justifyContent(FlexAlign.Center)
    .constraintSize({ minWidth: 35 })
    .width(64)
    .height(50)
    .onClick(() => {
      this.currentIndex = tabIndex
      const targetIndexInfo = getTextInfo(tabIndex)
      animateTo({
        duration: 300,
        curve: Curve.Linear,
        iterations: 1,
        playMode: PlayMode.Normal,
      }, () => {
        this.indicatorLeftMargin = targetIndexInfo.left
        this.indicatorWidth = targetIndexInfo.width
      })
    })
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Row() {
        ForEach(this.tabArray, (item: string, index: number) => {
          this.tab(item, index)
        }, (item: number, _index: number) => item.toString())
        Blank()
        AppIcon({
          iconCode: IconConstants.UP,
          iconColor: '#999999',
          iconSize: 14,
          iconPadding: 16,
          onClickBtn: () => {
            this.dialogController.open()
          }
        })
      }
      .justifyContent(FlexAlign.Start)
      .width('100%')
      .flexBasis(50)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#f5f5f5')
      .borderColor("#999999")
      .borderRadius({ topLeft: 8, topRight: 8 })
      .borderWidth({ top: 0.2 })

      Column()
        .width(this.indicatorWidth)
        .height(1.5)
        .backgroundColor('#40A9FF')
        .borderRadius(1)
        .margin({ left: this.indicatorLeftMargin, top: 50 })
    }
    .visibility((_.isEmpty(this.knowledge) && _.isEmpty(this.tags) && this.loginRole === 1) ? Visibility.None :
    Visibility.Visible)
  }
}

@CustomDialog
struct LeftTab {
  @Link tabArray: Array<string>
  @Link currentIndex: number
  @Link indicatorLeftMargin: number
  @Link indicatorWidth: number
  @Prop knowledge: Array<string> = []
  @Prop tags: Array<string> = []
  @Prop paper_id: string
  @Prop group_id: string
  @State knowledgeVisible: boolean = false
  @State paperKnowledgeVisible: boolean = false
  @State curr_type: string = ''
  @State curr_item: Record<string, string> = {}
  onCloseBtn: () => void = () => {
  }
  private tabsController: TabsController = new TabsController()
  private customDialogController?: CustomDialogController

  private startAnimateTo(duration: number, leftMargin: number, width: number) {
    animateTo({
      duration: duration,
      curve: Curve.Linear,
      iterations: 1,
      playMode: PlayMode.Normal,
    }, () => {
      this.indicatorLeftMargin = leftMargin
      this.indicatorWidth = width
    })
  }

  @Builder
  tab(tabName: string, tabIndex: number) {
    Row() {
      Text(tabName)
        .fontSize(16)
        .lineHeight(22)
        .fontColor(tabIndex === this.currentIndex ? '#000000' : '#999999')
        .id(tabIndex.toString())
        .onAreaChange((_, newValue: Area) => {
          if (this.currentIndex === tabIndex && (this.indicatorLeftMargin === 0 || this.indicatorWidth === 0)) {
            let positionX: number
            let width: number = Number.parseFloat(newValue.width.toString())
            if (newValue.position.x !== undefined) {
              positionX = Number.parseFloat(newValue.position.x?.toString())
              this.indicatorLeftMargin = Number.isNaN(positionX) ? 0 : positionX + 16
            }
            this.indicatorWidth = width
          }
        })
    }
    .justifyContent(FlexAlign.Center)
    .constraintSize({ minWidth: 35 })
    .width(64)
    .height(50)
    .onClick(() => {
      this.tabsController.changeIndex(tabIndex)
      this.currentIndex = tabIndex
      const targetIndexInfo = getTextInfo(tabIndex)
      animateTo({
        duration: 300,
        curve: Curve.Linear,
        iterations: 1,
        playMode: PlayMode.Normal,
      }, () => {
        this.indicatorLeftMargin = targetIndexInfo.left
        this.indicatorWidth = targetIndexInfo.width
      })
    })
  }

  @Builder
  BuildPaperItem(item: Record<string, string>, type: string) {
    Row() {
      Text((item.title ?? '')?.length > 6 ? item.title.slice(0, 6) + '...' : item.title)
        .padding({
          left: 8,
          right: 8,
          top: 4,
          bottom: 4
        })
        .fontColor(_.isEmpty(item.kg_ids) ? '#1EB38F' : '#40A9FF')
        .fontSize(12)
        .onClick(() => {
          this.curr_type = type
          this.curr_item = item
          this.knowledgeVisible = true
        })
      Divider().vertical(true).color(_.isEmpty(item.kg_ids) ? '#1EB38F' : '#40A9FF').height(14).strokeWidth(1)
      AppIcon({
        iconCode: IconConstants.OTHER,
        iconColor: _.isEmpty(item.kg_ids) ? '#1EB38F' : '#40A9FF',
        iconPadding: {
          left: 8,
          right: 8,
          top: 4,
          bottom: 4
        },
        onClickBtn: () => {
          this.curr_type = type
          this.curr_item = item
          this.paperKnowledgeVisible = true
        }
      })
    }
    .margin({ right: 8 })
    .borderWidth(1)
    .borderColor(_.isEmpty(item.kg_ids) ? '#1EB38F' : '#40A9FF')
  }

  @Builder
  BuildItem(item: Record<string, string>, type: string) {
    CustomTag({
      text: item.title,
      tagBorderColor: _.isEmpty(item.kg_ids) ? '#1EB38F' : '#40A9FF',
      fontColor: _.isEmpty(item.kg_ids) ? '#1EB38F' : '#40A9FF',
      tagMargin: { right: 8 },
      onClickBtn: () => {
        this.curr_type = type
        this.curr_item = item
        this.knowledgeVisible = true
      }
    })
  }

  @Builder
  BuildKnowledge() {
    Flex() {
      ForEach(this.knowledge, (item: Record<string, string>) => {
        if (this.paper_id) {
          this.BuildPaperItem(item, 'knowledge')
        } else {
          this.BuildItem(item, 'knowledge')
        }
      })
    }
    .height('100%')
    .padding(12)
  }

  @Builder
  BuildTags() {
    Flex({ wrap: FlexWrap.Wrap }) {
      ForEach(this.tags, (item: Record<string, string>) => {
        this.BuildItem(item, 'label')
      })
    }
    .height('100%')
    .padding(12)
  }

  build() {
    Column() {
      Stack({ alignContent: Alignment.TopStart }) {
        Row() {
          ForEach(this.tabArray, (item: string, index: number) => {
            this.tab(item, index)
          }, (item: number, _index: number) => item.toString())
          Blank()
          AppIcon({
            iconCode: IconConstants.DOWN,
            iconColor: '#999999',
            iconSize: 14,
            iconPadding: 16,
            onClickBtn: () => {
              this.onCloseBtn()
            }
          })
        }
        .justifyContent(FlexAlign.Start)
        .width('100%')
        .padding({ left: 16, right: 16 })
        .backgroundColor('#f5f5f5')
        .borderRadius({ topLeft: 8, topRight: 8 })

        Column()
          .width(this.indicatorWidth)
          .height(1.5)
          .backgroundColor('#40A9FF')
          .borderRadius(1)
          .margin({ left: this.indicatorLeftMargin, top: 50 })
      }
      .height(50)

      Tabs({ controller: this.tabsController, index: this.currentIndex }) {
        ForEach(this.tabArray, (item: string) => {
          TabContent() {
            if (item === '知识点') {
              if (_.isEmpty(this.knowledge)) {
                Text('暂未添加知识点')
              } else {
                this.BuildKnowledge()
              }
            } else if (item === '标签') {
              if (_.isEmpty(this.tags)) {
                Text('暂未添加标签')
              } else {
                this.BuildTags()
              }
            }
          }
        })
      }
      .barWidth('100%')
      .barHeight(0)
      .width('100%')
      .height('100%')
      .onAnimationStart((_index: number, targetIndex: number, _event: TabsAnimationEvent) => {
        this.currentIndex = targetIndex
        let targetIndexInfo = getTextInfo(targetIndex)
        this.startAnimateTo(300, targetIndexInfo.left, targetIndexInfo.width)
      })

      KnowledgeModal({
        visible: $knowledgeVisible,
        group_id: this.group_id,
        type: this.curr_type,
        item: this.curr_item
      })

      PaperKnowledgeModal({
        visible: $paperKnowledgeVisible,
        group_id: this.group_id,
        paper_id: this.paper_id,
        type: this.curr_type,
        item: this.curr_item
      })
    }
    .height(320)
    .borderRadius({ topLeft: 8, topRight: 8 })
    .backgroundColor(Color.White)
    .transition(TransitionEffect.move(TransitionEdge.BOTTOM).animation({ duration: 300 }))

  }
}

function getTextInfo(index: number): Record<string, number> {
  let modePosition: componentUtils.ComponentInfo = componentUtils.getRectangleById(index.toString())
  return { 'left': px2vp(modePosition.windowOffset.x), 'width': px2vp(modePosition.size.width) }
}

function QuestionTypeInfo(type: number): Record<string, string> | null {
  switch (type) {
    case 1:
      return { 'text': '单选题' }
    case 2:
      return { 'text': '多选题' }
    case 4:
      return { 'text': '填空题' }
    case 5:
      return { 'text': '判断题' }
    case 6:
      return { 'text': '简答题' }
    case 7:
      return { 'text': '附件题' }
    case 8:
      return { 'text': '投票题' }
    case 9:
      return { 'text': '题组题' }
    case 10:
      return { 'text': '编程题' }
    case 11:
      return { 'text': '量表题' }
    case 12:
      return { 'text': '排序题' }
    case 13:
      return { 'text': '匹配题' }
    default:
      return null
  }
}
