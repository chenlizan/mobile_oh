import _ from "@wolfx/lodash";
import scanBarcode from "@hms.core.scan.scanBarcode";
import { display } from "@kit.ArkUI";
import {
  Api_Context,
  AppIcon,
  Avatar,
  CCApi,
  ccApiGet,
  IconConstants,
  PreferenceStorage,
  RouterConstants,
  UserInfoModel
} from "@xy/basic";
import { DragComponent } from "./DragComponent";

@Component
export struct TeachingPage {
  @Link globalPageIndex: string;
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @StorageLink('PreferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage()
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @StorageLink('UserInfo') userInfo: UserInfoModel = new UserInfoModel()
  @State avatar: string = this.userInfo.avatar
  @State isRefreshing: boolean = false
  @State screenWidth: number = 0
  @State screenHeight: number = 0
  @State teach: number = 0
  @State study: number = 0
  preOffsetX: number = 0;
  preOffsetY: number = 0;
  @State imgOffSetX: number = 0;
  @State imgOffSetY: number = 0;

  aboutToAppear(): void {
    this.handleSiteCountNum()
    this.screenWidth = px2vp(display.getDefaultDisplaySync().width)
    this.screenHeight = px2vp(display.getDefaultDisplaySync().height)
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

  async handleSiteCountNum() {
    const response = await ccApiGet(this.Api_Context.getApiPrefix('ccApi_common') + CCApi.getSiteCountNum)
    if (response.code === 0) {
      const teamCountNum = response.result as Record<string, number>
      this.teach = (teamCountNum?.t1 ?? 0) + (teamCountNum?.t2 ?? 0) + (teamCountNum?.t3 ?? 0);
      this.study = (teamCountNum?.s1 ?? 0) + (teamCountNum?.s2 ?? 0) + (teamCountNum?.s3 ?? 0);
    }
  }

  @Builder
  BuildClassInfo() {
    Column() {
      Row() {
        Column() {
          Text(this.teach.toString())
            .fontColor('#FF931E')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
          Text('授课课程')
            .margin({ top: 4 })
            .fontColor(Color.White)
            .fontSize(8)
        }
        .padding(10)

        Column() {
          Text(this.study.toString())
            .fontColor('#FF931E')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
          Text('学习课程')
            .margin({ top: 4 })
            .fontColor(Color.White)
            .fontSize(8)
        }
      }
      .justifyContent(FlexAlign.SpaceAround)
      .flexGrow(1)
      .margin(16)
      .backgroundColor('#80000000')
      .borderRadius(4)
      .width(this.screenWidth - 32)
    }
    .width('100%')
  }

  build() {
    Refresh({ refreshing: $$this.isRefreshing }) {
      Column() {
        Column() {
          Row() {
            AppIcon({
              iconCode: IconConstants.SCAN,
              iconSize: 16,
              iconColor: Color.White,
              onClickBtn: async () => {
                await scanBarcode.startScanForResult(getContext())
              }
            })
            if (!_.isEmpty(this.userInfo.manageSpaces)) {
              AppIcon({
                iconCode: IconConstants.MENU,
                iconSize: 16,
                iconColor: Color.White,
                onClickBtn: () => {
                  this.globalPageIndex = RouterConstants.IDENTITY_PAGE_URL
                }
              })
            }
          }
          .width('100%')
          .padding(16)
          .justifyContent(FlexAlign.SpaceBetween)
          .reverse(true)

          Row() {
            Row() {
              Column() {
                Avatar({ avatar: $avatar })
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
                Row() {
                  Text(this.getSchools())
                    .fontColor(Color.White)
                    .textAlign(TextAlign.Start)
                  if (this.userInfo.isSchoolFellow) {
                    Image($r('app.media.school_fellow'))
                      .width(22)
                      .height(22)
                      .margin({ left: 4 })
                  }
                }
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
          .justifyContent(FlexAlign.SpaceBetween)

          this.BuildClassInfo()
        }
        .backgroundImage($r('app.media.homeBg'))
        .backgroundImageSize({ width: '100%', height: '100%' })
        .backgroundEffect({ radius: 25 })

        Grid() {
          GridItem() {
            Column() {
              Image($r('app.media.home_course'))
                .width(48)
                .height(48)
              Text('我的课程')
                .fontColor('#666666')
                .margin({ top: 12 })
            }
          }
          .enabled(false)

          GridItem() {
            Column() {
              Image($r('app.media.home_note'))
                .width(48)
                .height(48)
              Text('我的文档')
                .fontColor('#666666')
                .margin({ top: 12 })
            }
          }
          .enabled(false)

          GridItem() {
            Column() {
              Image($r('app.media.home_task'))
                .width(48)
                .height(48)
              Text('任务提醒')
                .fontColor('#666666')
                .margin({ top: 12 })
            }
          }
          .enabled(false)

          GridItem() {
            Column() {
              Image($r('app.media.home_discover'))
                .width(48)
                .height(48)
              Text('发现')
                .fontColor('#666666')
                .margin({ top: 12 })
            }
            .onClick(() => {
              this.pageInfos.pushPath({ name: 'testBuilder' })
            })
          }
          .enabled(false)
        }
        .height(this.screenWidth)
        .rowsTemplate('1fr 1fr')
        .columnsTemplate('1fr 1fr')

        DragComponent({
          src: $r('app.media.ai_service'),
          imgOffSetX: this.screenWidth - 70,
          imgOffSetY: this.screenHeight - 260,
          onClickBtn: () => {
            this.pageInfos.pushPath({ name: 'aIService' })
          }
        })

        DragComponent({
          src: $r('app.media.ai_helper'),
          imgOffSetX: this.screenWidth - 70,
          imgOffSetY: this.screenHeight - 200,
          onClickBtn: () => {
            this.pageInfos.pushPath({ name: 'aIHelper' })
          }
        })
      }

      .height('100%')
      .backgroundColor('#f1f1f1')

    }
    .onRefreshing(() => {
      this.handleSiteCountNum()
      this.avatar = this.userInfo.avatar
      setTimeout(() => {
        this.isRefreshing = false
      }, 500)
    })
  }
}