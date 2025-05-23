import _ from '@wolfx/lodash'
import { image } from '@kit.ImageKit'
import { display } from '@kit.ArkUI'
import {
  CustomList,
  CustomListItem,
  Api_Context,
  UserInfoModel,
  AppIcon,
  IconConstants,
  Avatar,
  ccApiGet,
  CCApi,
  CustomToast,
  PreferenceStorage,
  RouterConstants
} from "@xy/basic"

@Component
export struct MinePage {
  @Link globalPageIndex: string
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @StorageLink('PreferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage()
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @StorageLink('UserInfo') userInfo: UserInfoModel = new UserInfoModel()
  @State isRefreshing: boolean = false
  @State avatar: string = this.userInfo.avatar
  @State screenWidth: number = 0

  aboutToAppear(): void {
    this.screenWidth = px2vp(display.getDefaultDisplaySync().width)
  }

  async handleLoginOut() {
    CustomToast.toast_loading('退出登录中...')
    setTimeout(async () => {
      await ccApiGet(this.Api_Context.getApiPrefix('ccApi') + CCApi.logout)
      this.preferenceStorage.access_token = undefined
      this.preferenceStorage.refresh_token = undefined
      this.globalPageIndex = RouterConstants.LOGIN_PAGE_URL
      CustomToast.hide()
    }, 3000)
  }

  getSchools() {
    let news: string[] = [];
    _.forEach(this.userInfo.schools, (school: object) => {
      const schoolInfo = (school as Record<string, Record<string, string>>).schoolInfo
      const name = schoolInfo['schoolName']
      if (name) {
        news.push(name);
      }
    });
    return news.join('，');
  };

  @Builder
  BuildLeftIcon(src: image.PixelMap | ResourceStr | DrawableDescriptor) {
    Image(src)
      .width(20)
      .height(20)
      .margin({ right: 4 })
  }

  build() {
    Refresh({ refreshing: $$this.isRefreshing }) {
      Column() {
        Column() {
          Row() {
            Row() {
              Column() {
                Avatar({ avatar: $avatar })
                Row() {
                  Text((this.userInfo.fileCapacity as Record<string, string>)?.caseName)
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
              .margin({ left: 40, right: 18 })

              Column() {
                Text(this.userInfo.nickname)
                  .fontSize(20)
                  .fontColor(Color.White)
                  .fontWeight(FontWeight.Bold)
                  .textAlign(TextAlign.Start)
                  .width(160)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .ellipsisMode(EllipsisMode.END)
                  .wordBreak(WordBreak.BREAK_ALL)
                Text(this.getSchools())
                  .fontColor(Color.White)
                  .textAlign(TextAlign.Start)
              }
              .height(64)
              .alignItems(HorizontalAlign.Start)
              .justifyContent(FlexAlign.SpaceAround)
            }

            Row() {
              AppIcon({
                iconCode: IconConstants.RIGHT,
                iconSize: 16,
                iconColor: Color.White,
                iconPadding: 32,
                onClickBtn: () => {
                  this.pageInfos.pushPath({ name: 'userEdit' })
                }
              })
            }
          }
          .width('100%')
          .height(170)
          .justifyContent(FlexAlign.SpaceBetween)
          .backgroundColor(Color.Blue)
          .backgroundImage($r('app.media.homeBg'))
          .backgroundImageSize({ width: '100%', height: '100%' })
          .backgroundEffect({ radius: 25 })

          Column() {
            CustomList({ listPadding: { left: 16, right: 16 } }) {
              CustomListItem({
                iconBuilder: () => this.BuildLeftIcon($r('app.media.mine_report')),
                text: '个人年度报告',
                itemMargin: { top: 8 },
                itemRadius: 8,
                itemBorder: {},
                onClickBtn: () => {
                  this.pageInfos.pushPath({ name: 'userReport' })
                }
              })
              CustomListItem({
                iconBuilder: () => this.BuildLeftIcon($r('app.media.mine_portrait')),
                text: '个人数据看板',
                itemMargin: { top: 8 },
                itemRadius: 8,
                itemBorder: {},
                onClickBtn: () => {
                  this.pageInfos.pushPath({ name: 'userPortrait' })
                }
              })
              CustomListItem({
                iconBuilder: () => this.BuildLeftIcon($r('app.media.mine_reflect')),
                text: '反馈&建议',
                itemMargin: { top: 8 },
                itemRadius: 8,
                itemBorder: {},
                onClickBtn: () => {
                  this.pageInfos.pushPath({ name: 'userReflect' })
                }
              })
              CustomListItem({
                iconBuilder: () => this.BuildLeftIcon($r('app.media.mine_about')),
                text: '关于小雅',
                itemMargin: { top: 8 },
                itemRadius: 8,
                itemBorder: {},
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
            .margin(16)
            .width(this.screenWidth - 32)
            .height(40)
            .backgroundColor('#fcbb34')
            .borderRadius(4)
            .onClick(() => this.handleLoginOut())
        }
        .justifyContent(FlexAlign.End)

      }
      .width('100%')
      .height('100%')
      .backgroundColor('#f1f1f1')
    }
    .onRefreshing(() => {
      this.avatar = this.userInfo.avatar
      setTimeout(() => {
        this.isRefreshing = false
      }, 500)
    })
  }
}