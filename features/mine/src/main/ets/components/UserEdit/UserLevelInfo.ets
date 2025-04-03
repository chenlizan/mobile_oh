import _ from "@wolfx/lodash";
import { CustomList, CustomListItem, CustomNavTitle, UserInfoModel } from "@xy/basic"

@Component
struct UserLevelInfo {
  @StorageLink('UserInfo') userInfo: UserInfoModel = new UserInfoModel()

  transFileSizeGByM(size: number) {
    if (size >= 1024) {
      return _.floor(size / 1024) + 'G'
    }
    return size + 'M'
  }

  @Builder
  BuildTextItem(value: string) {
    Row() {
      Text(value)
        .margin({ right: 8 })
        .fontColor('#999999')
        .fontSize(14)
    }
  }

  build() {
    NavDestination() {
      CustomList({ listPadding: { left: 16, right: 16 } }) {
        CustomListItem({
          text: "自主创建课程数量",
          operateBuilder: () => this.BuildTextItem(`${(this.userInfo.fileCapacity as Record<string, string>).selfCreateSiteCount ??
            0}个`),
        })
        CustomListItem({
          text: "单个文件上限",
          operateBuilder: () => this.BuildTextItem(this.transFileSizeGByM((this.userInfo.fileCapacity as Record<string, number>).perFileSize ??
            0)),
        })
        CustomListItem({
          text: "文件上限",
          operateBuilder: () => this.BuildTextItem(this.transFileSizeGByM((this.userInfo.fileCapacity as Record<string, number>).totalFileSize ??
            0)),
        })
        CustomListItem({
          text: "单个视频上限",
          operateBuilder: () => this.BuildTextItem(this.transFileSizeGByM((this.userInfo.fileCapacity as Record<string, number>).perVideoFileSize ??
            0)),
        })
        CustomListItem({
          text: "视频上限",
          operateBuilder: () => this.BuildTextItem(this.transFileSizeGByM((this.userInfo.fileCapacity as Record<string, number>).totalVideoFileSize ??
            0)),
        })
        CustomListItem({
          text: "我的文档资源上限",
          operateBuilder: () => this.BuildTextItem(`${(this.userInfo.fileCapacity as Record<string, string>).documentFileCount ??
            0}个`),
        })
      }
    }
    .title(CustomNavTitle('用户级别'))
    .backgroundColor("#f1f1f1")
  }
}

@Builder
export function UserLevelInfoBuilder() {
  UserLevelInfo()
}