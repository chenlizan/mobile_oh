import _ from '@wolfx/lodash'
import { CustomList, CustomListItem, Api_Context, UserInfoModel, AppIcon, IconConstants, Avatar } from "@xy/basic";
import { image } from '@kit.ImageKit';

@Entry
@Component
export struct MinePage {
  @StorageLink('access_token') token: string = ''
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @StorageLink('UserInfo') userInfo: UserInfoModel = new UserInfoModel()

  async aboutToAppear() {
  }

  @Builder
  BuildLeftIcon(src: image.PixelMap | ResourceStr | DrawableDescriptor) {
    Image(src)
      .width(20)
      .height(20)
      .margin({ top: 4, right: 4 })
  }

  build() {
    Column() {
      Column() {
        Row() {
          Row() {
            Column() {
              Avatar({ avatar: this.userInfo.avatar })
              Row() {
                Text('高级用户')
                  .padding({
                    top: 4,
                    bottom: 4,
                    left: 8,
                    right: 8
                  })
                  .fontSize(8)
                  .fontColor('#fcbb34')
              }
              .margin({ top: -16 })
              .borderRadius(30)
              .backgroundColor('#404040')
              .borderColor(Color.White)
              .borderWidth(0.5)
            }
            .margin({ left: 40, right: 16 })

            Column() {
              Text(this.userInfo.nickname)
                .fontSize(20)
                .fontColor(Color.White)
                .fontWeight(FontWeight.Bold)
                .textAlign(TextAlign.Start)
              Text('华中师范大学')
                .fontColor(Color.White)
                .textAlign(TextAlign.Start)
            }
            .height('40%')
            .alignItems(HorizontalAlign.Start)
            .justifyContent(FlexAlign.SpaceAround)
          }

          Row() {
            AppIcon({ iconCode: IconConstants.RIGHT, iconSize: 16, iconColor: Color.White })
          }
          .margin({ right: 32 })
        }
        .width('100%')
        .height('170vp')
        .justifyContent(FlexAlign.SpaceBetween)
        .backgroundColor(Color.Blue)
        .backgroundImage($r('app.media.homeBg'))
        .backgroundImageSize({ width: '100%', height: '100%' })
        .backgroundEffect({ radius: 25 })

        Column() {
          CustomList({ listPadding: { left: 16, right: 16 } }) {
            // CustomListItem({
            //   iconBuilder: () => this.BuildLeftIcon($r('app.media.mine_report')),
            //   text: '个人年度报告',
            //   itemMargin: { top: '8vp' },
            //   itemRadius: '8vp',
            //   itemBorder: ''
            // })
            // CustomListItem({
            //   iconBuilder: () => this.BuildLeftIcon($r('app.media.mine_portrait')),
            //   text: '个人数据看板',
            //   itemMargin: { top: '8vp' },
            //   itemRadius: '8vp',
            //   itemBorder: ''
            // })
            // CustomListItem({
            //   iconBuilder: () => this.BuildLeftIcon($r('app.media.mine_reflect')),
            //   text: '反馈&建议',
            //   itemMargin: { top: '8vp' },
            //   itemRadius: '8vp',
            //   itemBorder: ''
            // })
            CustomListItem({
              iconBuilder: () => this.BuildLeftIcon($r('app.media.mine_about')),
              text: '关于小雅',
              itemMargin: { top: '8vp' },
              itemRadius: '8vp',
              itemBorder: '',
              onClickBtn: () => {
                this.pageInfos.pushPath({ name: "about" })
              }
            })
          }
        }
        .margin({ top: -24 })
      }
      .flexGrow(1)

      Column() {
        Button('退出小雅', { type: ButtonType.Normal })
          .margin({ bottom: 16 })
          .width('94%')
          .backgroundColor('#fcbb34')
          .borderRadius(4)
      }
      .height(60)
      .justifyContent(FlexAlign.End)

    }
    .width('100%')
    .height('100%')
    .backgroundColor("#f1f1f1")
  }
}