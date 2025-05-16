import { display } from "@kit.ArkUI"
import _ from "@wolfx/lodash"
import {
  Api_Context,
  AppIcon,
  CustomAlertDialog,
  AlertDialogParam,
  CustomNavTitle,
  CustomToast,
  IconConstants,
  MessageApi,
  xyApiGet,
  HomeApi,
  xyApiPut,
  xyApiDelete,
  UserInfoModel,
} from "@xy/basic"
import dayjs from "dayjs"

@Component
struct MessageSystemDetail {
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @StorageLink('UserInfo') userInfo: UserInfoModel = new UserInfoModel()
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @State screenWidth: number = 0
  @State screenHeight: number = 0
  @State onlyUnread: boolean = true
  private param: Record<string, string | number> = {}

  aboutToAppear(): void {
    this.screenWidth = px2vp(display.getDefaultDisplaySync().width)
    this.screenHeight = px2vp(display.getDefaultDisplaySync().height)

    this.param = JSON.parse(String(this.pageInfos.getParamByName('messageSystemDetail')[0]))
    this.onUpdateMsgStatus(this.param.id as string, 1)
  }


  getCourseAvatarUrl = (user_id: string) => {
    return `${this.Api_Context.getApiPrefix(
      'baseApi_out',
    )}cloud/file/avatar/${user_id}?random=${dayjs().format('YYYY/MM/DD/HH')}`;
  }

  onEnterGroup = async (group_id: string) => {
    const response = await xyApiGet(this.Api_Context.getApiPrefix("baseApi_inner") + HomeApi.queryGroup +
      `/${group_id}`)

    if (response.success) {
      const group = response.data as Record<string, string | number>
      if (!_.isEmpty(group)) {
        if (group?.spType == 1 || group?.sp_type == 1) {
          // sp
        } else {
          if (group.course_property === '2') {
            // mooc
          } else {
          }
        }
      }
    }
  }
  onDeleteMsg = () => {
    CustomAlertDialog({
      title: '提示',
      message: '是否删除此消息？',
      onClickBtn: () => {
        xyApiDelete(this.Api_Context.getApiPrefix("baseApi_inner") + MessageApi.delMessage + this.param.id).then(response => {
          if (response.success) {
            CustomToast.toast_success("删除成功");
          }
        })
      }
    } as AlertDialogParam)
  }
  onUpdateMsgStatus = async (message_id: string, status: number) => {
    await xyApiPut(this.Api_Context.getApiPrefix("baseApi_inner") + MessageApi.updateMsgStatus, {
      "message_ids": [message_id],
      "status": status,
    })
  }

  @Builder
  BuildNavRightBtn() {
    Text('删除')
      .fontColor(Color.Red)
      .onClick(() => {
        this.onDeleteMsg()
      })
  }

  @Builder
  BuildPopupContent() {
    AppIcon({
      iconCode: IconConstants.INFO,
      iconSize: 16,
      iconColor: '#999999',
    }).enabled(false)
  }

  build() {
    NavDestination() {
      Flex({direction: FlexDirection.Column, alignItems: ItemAlign.Center}) {
        Text(dayjs(this.param?.createAt).format('YYYY-MM-DD HH:mm:ss'))
          .fontSize(13)
          .fontColor('#A9AFB8')
          .backgroundColor('#F1F1F1')

        Column(){
          if (this.param?.link_group) {
            Text(this.param?.title as string)
              .fontColor('#40A9FF')
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .onClick(() => this.onEnterGroup(this.param?.group_id as string))
          } else {
            Text(this.param?.title as string)
              .fontColor(Color.Black)
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
          }
          Text(this.param?.content as string)
            .fontColor('#999')
            .fontSize(13)
            .fontWeight(400)
            .margin({top: 12})
        }
        .width('100%')
        .margin(12)
        .padding(12)
        .backgroundColor('#F1F1F1')
        .borderRadius(4)
        .alignItems(HorizontalAlign.Start)

        if (!!this.param?.remind) {
          Text(this.param.remind as string)
            .fontColor('#FF4040')
            .fontSize(13)
            .fontWeight(400)
            .textAlign(TextAlign.Start)
        }
      }
      .padding(12)
      .margin({left:12,right:12})
      .flexGrow(1)
      .backgroundColor(Color.White)
    }
    .title(CustomNavTitle('系统消息详情', () => this.BuildNavRightBtn()))
    .backgroundColor("#f1f1f1")
  }
}

@Builder
export function MessageSystemDetailBuilder() {
  MessageSystemDetail()
}