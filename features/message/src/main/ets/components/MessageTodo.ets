import { display } from "@kit.ArkUI"
import _ from "@wolfx/lodash"
import {
  Api_Context,
  AppIcon,
  CustomNavTitle,
  getMemberRole,
  IconConstants,
  MessageApi,
  MessageContentType,
  xyApiGet
} from "@xy/basic"
import dayjs from "dayjs"

@Component
struct MessageTodo {
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @State isRefreshing: boolean = false
  @State screenWidth: number = 0
  @State screenHeight: number = 0
  @State onlyUnread: boolean = true
  @State last_msg_id: string | null = null
  @State msgData: Record<string, string | number | boolean>[] = []

  aboutToAppear(): void {
    this.screenWidth = px2vp(display.getDefaultDisplaySync().width)
    this.screenHeight = px2vp(display.getDefaultDisplaySync().height)
    this.handleRefresh()
  }

  handleRefresh = async () => {
    const response = await xyApiGet(this.Api_Context.getApiPrefix("baseApi_inner") + MessageApi.queryTodoNotices, {
      "page_size": 20,
      "msg_status": this.onlyUnread ? 0 : null,
      "last_msg_id": this.last_msg_id,
    })

    if (response.success) {
      const data = response.data as Record<string, string | number | Record<string, string | number>[]>
      this.msgData =
        _.map(data?.list as Record<string, string | number>[], (datum: Record<string, string | number>) => {

          const fixedMsg: Record<string, string | number | boolean> = {};
          const group_id = _.get(datum, 'body.msgBody.group.id');
          fixedMsg.group_id = group_id;
          fixedMsg.avatar = `${this.Api_Context.getApiPrefix(
            'baseApi_out',
          )}cloud/group/cover/${group_id}`;
          fixedMsg.title = _.get(datum, 'body.msgBody.group.name');
          fixedMsg.id = _.get(datum, 'body.msgId');
          fixedMsg.vernierId = _.get(datum, 'id');
          fixedMsg.msgCode = _.get(datum, 'body.msgCode');
          fixedMsg.operator_id = _.get(datum, 'body.msgBody.operator.id');
          fixedMsg.operator_name = _.get(datum, 'body.msgBody.operator.nickname');
          if (fixedMsg.msgCode === MessageContentType.Invite_To_Group) {
            fixedMsg.be_join_role = _.get(datum, 'body.msgBody.content.be_join_role');
            fixedMsg.link_group = true;
            fixedMsg.content = `${fixedMsg.operator_name} 邀请您参加课程`;
          } else if (fixedMsg.msgCode === MessageContentType.Apply_Join_Group) {
            fixedMsg.class_id = _.get(datum, 'body.msgBody.content.class_id');
            const class_name = _.get(datum, 'body.msgBody.content.class_name');
            const student_number = _.get(datum, 'body.msgBody.content.student_number');
            const operator_role = _.get(datum, 'body.msgBody.operator.role', 1);
            fixedMsg.link_group = true;
            if (operator_role === 1) {
              fixedMsg.content = `${fixedMsg.operator_name}（一卡通号：${
              student_number ? student_number : '暂无数据'
              }）申请加入班级（${class_name}）`;
            } else {
              fixedMsg.content = `${fixedMsg.operator_name}（一卡通号：${
              student_number ? student_number : '暂无数据'
              }）申请成为本课程${getMemberRole(operator_role as number)}`;
            }
          } else if (fixedMsg.msgCode === MessageContentType.Apply_Merge_Group) {
            // 主合并课程siteId
            fixedMsg.mainSiteId = _.get(datum, 'body.msgBody.content.merge_site_id');
            // 被合并课程siteId
            fixedMsg.beMergedSiteId = _.get(
              datum,
              'body.msgBody.content.be_merge_site_id',
            );
            const school_name = _.get(datum, 'body.msgBody.operator.school_name');
            const site_name = _.get(datum, 'body.msgBody.content.be_merge_site_name');

            fixedMsg.title = '课程合并申请';
            fixedMsg.avatar = this.getCourseAvatarUrl(fixedMsg.operator_id as string);
            fixedMsg.content =
              `${school_name} - ${fixedMsg.operator_name} 申请合并您的课程《${site_name}》的课程成员，合并完成后您的课程将会被删除`;
            fixedMsg.remind =
              '提示：请谨慎审核申请信息，建议不要随意允许陌生人合并自己的课程。';
          } else if (fixedMsg.msgCode === MessageContentType.Apply_Clone_Group) {
            let cloneContents: Array<string> = [];
            const schoolShortName = _.get(
              datum,
              'body.msgBody.content.applayer.schoolShortName',
            );
            const nickname = _.get(datum, 'body.msgBody.content.applayer.nickname');
            const applyCourse = _.get(datum, 'body.msgBody.content.fromGroup.name');
            // const applayParams = _.get(datum, 'body.msgBody.content.applayParams') as Record<string, string | number>[];
            // const pickClone = _.pickBy(
            //   applayParams,
            //   (val: number, key: string) => val === 1 && key !== 'isAppend',
            // );
            // const cloneContentObj: Record<string, string> = {
            //   "is_clone_res": '备授课内容',
            //   "is_clone_setting": '课程设置',
            //   "is_clone_grade": '总评成绩设置',
            //   "is_clone_group_desc": '课程简介',
            //   "is_clone_application": '课程应用',
            // };
            // _.forEach(pickClone, (val, key) => {
            //   if (cloneContentObj[key]) {
            //     cloneContents.push(cloneContentObj[key]);
            //   }
            // });
            const cloneText = _.isEmpty(cloneContents)
              ? ''
              : _.join(cloneContents, '、');
            fixedMsg.apply_user_id = _.get(datum, 'body.msgBody.content.applayer.id');
            fixedMsg.apply_user_nickname = _.get(
              datum,
              'body.msgBody.content.applayer.nickname',
            );
            fixedMsg.applay_id = _.get(datum, 'body.msgBody.content.applayId');
            fixedMsg.title = '课程克隆申请';
            const avatar = _.get(datum, 'body.msgBody.content.applayer.avatar');
            fixedMsg.avatar = `${this.Api_Context.getApiPrefix('baseApi_out')}${avatar}`;
            const key_number = _.get(
              datum,
              'body.msgBody.content.fromGroup.key_number',
            );
            fixedMsg.content =
              `${schoolShortName} - ${nickname} 申请克隆您的课程《${applyCourse}》（课程空间编号：${key_number}）,克隆内容包含 ${cloneText}`;
            fixedMsg.remind =
              '提示：请谨慎审核申请信息，建议不要随意允许陌生人克隆自己的课程';
          } else if (fixedMsg.msgCode === MessageContentType.Apply_Be_Friend) {
            const nickname = _.get(datum, 'body.msgBody.operator.nickname');
            fixedMsg.title = `${nickname} 的好友申请`;
            fixedMsg.content = `${nickname} 想要加您为好友`;
            fixedMsg.avatar = this.getCourseAvatarUrl(fixedMsg.operator_id as string);
          }
          fixedMsg.node_id = _.get(datum, 'body.msgBody.content.node_id');
          fixedMsg.createAt = _.get(datum, 'createdAt');
          fixedMsg.status = _.get(datum, 'msgStatus[0].status', -1);

          return fixedMsg
        })
    }
  }
  getCourseAvatarUrl = (user_id: string) => {
    return `${this.Api_Context.getApiPrefix(
      'baseApi_out',
    )}cloud/file/avatar/${user_id}?random=${dayjs().format('YYYY/MM/DD/HH')}`;
  };

  @Builder
  BuildNavRightBtn() {
    AppIcon({
      iconCode: IconConstants.MORE,
      iconSize: 24,
      onClickBtn: () => {
      }
    })
  }

  build() {
    NavDestination() {
      Refresh({ refreshing: $$this.isRefreshing }) {
        Column() {
        }
        .width(this.screenWidth - 24)
      }
      .onRefreshing(() => {
        this.handleRefresh()
      })
    }
    .title(CustomNavTitle('代办事项', () => this.BuildNavRightBtn()))
    .backgroundColor("#f1f1f1")
  }
}


@Builder
export function MessageTodoBuilder() {
  MessageTodo()
}