import { AppIcon, CustomList, CustomListItem, CustomNavTitle, IconConstants } from "@xy/basic"

@Component
struct UserSchool {
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack();
  @State school: Record<string, string> = {}

  aboutToAppear(): void {
    this.school = JSON.parse(String(this.pageInfos.getParamByName('userSchool')[0]))
  }

  @Builder
  BuildLeftIcon(code: IconConstants) {
    AppIcon({
      iconCode: code,
      iconColor: '#FCBB34',
      iconSize: 16,
      iconMargin: { right: 8 }
    })
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
          text: '学校',
          iconBuilder: () => this.BuildLeftIcon(IconConstants.SCHOOL),
          operateBuilder: () => this.BuildTextItem(this.school.schoolName)
        })
        CustomListItem({
          text: '院系',
          iconBuilder: () => this.BuildLeftIcon(IconConstants.MAJOR),
          operateBuilder: () => this.BuildTextItem(this.school.departmentName)
        })
        CustomListItem({
          text: '一卡通号',
          iconBuilder: () => this.BuildLeftIcon(IconConstants.PASS),
          operateBuilder: () => this.BuildTextItem(this.school.loginName)
        })
      }
    }
    .title(CustomNavTitle('所在学校'))
    .backgroundColor("#f1f1f1")
  }
}

@Builder
export function UserSchoolBuilder() {
  UserSchool()
}