import { emitter } from "@kit.BasicServicesKit";
import _ from "@wolfx/lodash";
import dayjs from "dayjs"
import {
  Api_Context,
  AppIcon,
  ccApiGet,
  CustomModalDialog,
  DownloadUtil,
  IconConstants,
  Notice,
  SystemApi,
  SystemNoticeStorage,
  UserInfoModel,
} from "@xy/basic";

@Component
export struct SystemNoticeModal {
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @StorageLink('SystemNoticeStorage') SystemNoticeStorage: SystemNoticeStorage = new SystemNoticeStorage()
  @StorageLink("map") message: Map<number, string> = new Map([[0, "a"], [1, "b"], [3, "c"]]);
  @StorageLink('UserInfo') userInfo: UserInfoModel = new UserInfoModel()
  @State title: string = `平台公告`
  @State visible: boolean = false
  @State systemNotice: Notice[] = []
  @State noticeId: string = ''

  aboutToAppear(): void {
    emitter.on("systemNotice", () => {
      this.getSystemNotice()
    });
  }

  async getSystemNotice() {
    const response = await ccApiGet(this.Api_Context.getApiPrefix('ccApi') + SystemApi.systemNotices)
    if (response.code === 200) {
      const systemNotice = _.orderBy(response.result ?? [], ['publishtime'], ['desc']) as Notice[]
      this.systemNotice = _.filter(systemNotice,
        notice =>!_.find(this.SystemNoticeStorage.get(this.userInfo.id), { id: notice.id }) &&
        dayjs().isBefore(notice.endTime))
      if (this.systemNotice.length !== 0) {
        this.visible = true
        this.title = `平台公告（${this.systemNotice.length}）`
      }
    }
  }

  handleSaveSystemNoticeReadInfo(ids: Notice | Notice[], visible: boolean) {
    const user_id = this.userInfo.id
    let info = this.SystemNoticeStorage.get(user_id,)
    if (_.isArray(ids)) {
      const rows = info ?? [];
      info = _.uniqBy([...rows, ...ids], item => item.id)
    } else {
      const rows = info ?? [];
      if (!_.find(rows, { id: ids.id })) {
        info = [...rows, ids]
      }
    }
    this.SystemNoticeStorage.set(user_id, info as Notice[])
    this.getSystemNotice()
    this.visible = visible
  }

  async handleDownload(attach: Record<string, string>) {
    const response =
      await ccApiGet(this.Api_Context.getApiPrefix("managerApi") + "oss/downloadByAttachId", { 'attachId': attach.id })
    if (response.code === 200) {
      DownloadUtil(response.result as string, attach.filename)
    }
  }

  @Builder
  BuildModalContent(systemNotice: Notice[]) {
    Column() {
      List() {
        ForEach(systemNotice, (item: Notice) => {
          ListItem() {
            Column() {
              Row() {
                AppIcon({
                  iconCode: this.noticeId === item.id ? IconConstants.DOWN : IconConstants.UP,
                  iconBackgroundColor: '#41a9fe',
                  iconColor: Color.White,
                  iconPadding: 4,
                  iconRadius: 50,
                  iconSize: 14,
                  onClickBtn: () => {
                    if (this.noticeId === item.id) {
                      this.noticeId = ''
                    } else {
                      this.noticeId = item.id
                    }
                  }
                })
                Text(item.title)
                  .margin({ left: 8 })
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
              }
              .width('100%')
              .padding(6)
              .justifyContent(FlexAlign.Start)

              if (this.noticeId !== item.id) {
                Column() {
                  Web({
                    src: `data:text/html, <html><head><style>body{font-size: 48px;}</style></head><body>${item.content}</body></html>`,
                    controller: new WebController
                  })
                    .backgroundColor('#f5f5f5')

                  Row() {
                    ForEach(item.attachmentInfoList, (attach: Record<string, string>) => {
                      Text(attach?.filename)
                        .fontColor('#40a9ff')
                        .fontSize(14)
                        .onClick(() => this.handleDownload(attach))
                    })
                  }
                  .width('100%')
                  .padding(4)
                  .justifyContent(FlexAlign.Start)

                  Row() {
                    Text('我知道了')
                      .fontColor('#40a9ff')
                      .fontSize(20)
                      .onClick(() => {
                        this.handleSaveSystemNoticeReadInfo(item, true)
                      })
                  }
                  .width('100%')
                  .padding(4)
                  .justifyContent(FlexAlign.End)
                }
                .padding(8)
              }
            }
            .width('100%')
            .backgroundColor('#f5f5f5')
            .borderRadius(8)
          }
          .margin({ bottom: 8 })
        })
      }
      .width('100%')
      .padding(16)
    }
  }

  build() {
    CustomModalDialog({
      dialogHeight: 400,
      visible: this.visible,
      title: this.title,
      contentBuilder: () => this.BuildModalContent(this.systemNotice),
      onCloseBtn: (): void => this.handleSaveSystemNoticeReadInfo(this.systemNotice, false)
    })
  }
}