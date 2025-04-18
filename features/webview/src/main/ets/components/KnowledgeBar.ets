import { componentUtils } from '@kit.ArkUI';
import { AppIcon, IconConstants } from '@xy/basic';

@Component
export struct KnowledgeBar {
  @State tabArray: Array<string> = ['知识点', '标签']
  @State currentIndex: number = 0
  @State indicatorLeftMargin: number = 16
  @State indicatorWidth: number = 0
  onCloseBtn: () => void = () => {
    this.dialogController.close()
  }
  dialogController: CustomDialogController = new CustomDialogController({
    builder: LeftTab({
      onCloseBtn: this.onCloseBtn,
      tabArray: $tabArray,
      currentIndex: $currentIndex,
      indicatorLeftMargin: $indicatorLeftMargin,
      indicatorWidth: $indicatorWidth
    }),
    alignment: DialogAlignment.Bottom,
    customStyle: true,
    cancel: () => this.dialogController.close(),
    closeAnimation: { duration: 0 }
  })

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

      Column()
        .width(this.indicatorWidth)
        .height(1.5)
        .backgroundColor('#40A9FF')
        .borderRadius(1)
        .margin({ left: this.indicatorLeftMargin, top: 50 })
    }
  }
}

@CustomDialog
export struct LeftTab {
  @Link tabArray: Array<string>
  @Link currentIndex: number
  @Link indicatorLeftMargin: number
  @Link indicatorWidth: number
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
            Row() {
              Text(item)
            }
            .justifyContent(FlexAlign.Center)
            .width('100%')
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
