import _ from "@wolfx/lodash"
import { CustomNavTitle, PreferenceStorage } from "@xy/basic"
import dayjs from "dayjs"

@Component
struct TaskArchiveDetails {
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @StorageLink('PreferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage()
  @State finishRows: Record<string, string | number>[] = []
  @State unFinishRows: Record<string, string | number>[] = []
  private param: Record<string, Record<string, string | number>[] | string> = {}

  aboutToAppear(): void {
    this.param = JSON.parse(String(this.pageInfos.getParamByName('taskArchiveDetails')[0]))
    this.finishRows = _.filter(this.param.members as Record<string, string | number>[], (member) => member.finish === 2)
    this.unFinishRows =
      _.filter(this.param.members as Record<string, string | number>[], (member) => member.finish === 1)
  }

  build() {
    NavDestination() {
      Flex({ direction: FlexDirection.Column }) {
        Column() {
          Text(`已完成（${this.finishRows.length}）`)
            .padding(16)
            .fontWeight(FontWeight.Medium)
          Divider()
            .margin({ left: 12, right: 12 })
            .color('#d9d9d9')
            .strokeWidth(1.1)
          List() {
            ForEach(this.finishRows, (item: Record<string, string | number>) => {
              ListItem() {
                Column() {
                  Row() {
                    Text(item.name as string)
                      .fontSize(14)
                    Text(item.finish === 2 ? '已完成' : '未完成')
                      .fontColor(item.finish === 2 ? '#40A9FF' : '#FF4040')
                      .fontSize(13)
                  }
                  .justifyContent(FlexAlign.SpaceBetween)
                  .width('100%')

                  Row() {
                    Text(`观看时长: ${parseFloat(item.watched_duration as string).toFixed(2,)}s`)
                      .fontSize(14)
                      .visibility(item.watched_duration ? Visibility.Visible : Visibility.None)
                    Text(dayjs(item.finish_time).format('YYYY-MM-DD HH:mm:ss'))
                      .fontSize(14)
                      .visibility(item.finish_time ? Visibility.Visible : Visibility.None)
                  }
                  .justifyContent(FlexAlign.SpaceBetween)
                  .width('100%')
                  .margin({ top: 10 })
                  .visibility((item.finish_time && item.watched_duration) ? Visibility.Visible : Visibility.None)
                }
                .padding(12)
              }
            })
          }
          .divider({
            color: '#d9d9d9',
            strokeWidth: 1.1,
            startMargin: 12,
            endMargin: 12
          })
          .flexShrink(0)
        }
        .flexGrow(1)
        .alignItems(HorizontalAlign.Start)
        .backgroundColor(Color.White)
        .borderRadius(4)

        Column()
          .flexShrink(0)
          .height(12)
          .visibility(Visibility.Hidden)

        Column() {
          Text(`未完成（${this.unFinishRows.length}）`)
            .padding(16)
            .fontWeight(FontWeight.Medium)
          Divider()
            .margin({ left: 12, right: 12 })
            .color('#d9d9d9')
            .strokeWidth(1.1)
          List() {
            ForEach(this.unFinishRows, (item: Record<string, string | number>) => {
              ListItem() {
                Column() {
                  Row() {
                    Text(item.name as string)
                      .fontSize(14)
                    Text(item.finish === 2 ? '已完成' : '未完成')
                      .fontColor(item.finish === 2 ? '#40A9FF' : '#FF4040')
                      .fontSize(13)
                  }
                  .justifyContent(FlexAlign.SpaceBetween)
                  .width('100%')

                  Row() {
                    Text(`观看时长: ${parseFloat(item.watched_duration as string).toFixed(2,)}s`)
                      .fontSize(14)
                      .visibility(item.watched_duration ? Visibility.Visible : Visibility.None)
                    Text(dayjs(item.finish_time).format('YYYY-MM-DD HH:mm:ss'))
                      .fontSize(14)
                      .visibility(item.finish_time ? Visibility.Visible : Visibility.None)
                  }
                  .justifyContent(FlexAlign.SpaceBetween)
                  .width('100%')
                  .margin({ top: 10 })
                  .visibility((item.finish_time && item.watched_duration) ? Visibility.Visible : Visibility.None)
                }
                .padding(12)
              }
            })
          }
          .divider({
            color: '#d9d9d9',
            strokeWidth: 1.1,
            startMargin: 12,
            endMargin: 12
          })
          .flexShrink(0)
        }
        .flexGrow(1)
        .alignItems(HorizontalAlign.Start)
        .backgroundColor(Color.White)
        .borderRadius(4)
      }
      .margin({ left: 12, right: 12 })
    }
    .title(CustomNavTitle(this.param.name as string))
    .backgroundColor('#f1f1f1')
  }
}

@Builder
export function TaskArchiveDetailsBuilder() {
  TaskArchiveDetails()
}