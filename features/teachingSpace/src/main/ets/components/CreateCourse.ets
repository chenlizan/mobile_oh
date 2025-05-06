import { CustomList, CustomListItem, CustomNavTitle } from "@xy/basic"

@Component
struct CreateCourse {
  @State textAreaBorderColor: ResourceColor = '#d9d9d9d9'

  build() {
    NavDestination() {
      Flex({ direction: FlexDirection.Column }) {
        Scroll() {
          CustomList() {
            Column() {
              Text() {
                Span('*').fontColor(Color.Red)
                Span('课程名称(必填)')
              }
              .padding(12)

              TextArea({ placeholder: '请输入课程名称' })
                .height(75)
                .margin({ left: 16, right: 16 })
                .backgroundColor(Color.White)
                .borderColor(this.textAreaBorderColor)
                .borderRadius(4)
                .borderWidth(1)
                .placeholderColor('#d9d9d9d9')
                .onFocus(() => {
                  this.textAreaBorderColor = '#40A9FF'
                })
                .onBlur(() => {
                  this.textAreaBorderColor = '#d9d9d9d9'
                })

              Text('*测试课程使用后，请及时删除，否则会影响画像等数据，管理员将定期清理课程名称随意的课程')
                .padding(12)
                .fontColor('#999999')
                .fontSize(12)
            }
            .alignItems(HorizontalAlign.Start)
            .backgroundColor(Color.White)

            CustomListItem({
              text: "课程简介",

              onClickBtn: () => {
              }
            })
            CustomListItem({
              text: "开课学校",

              onClickBtn: () => {
              }
            })
            CustomListItem({
              text: "课程学段",

              onClickBtn: () => {
              }
            })
            CustomListItem({
              text: "课程学期",

              onClickBtn: () => {
              }
            })
            CustomListItem({
              text: "开始时间",

              onClickBtn: () => {
              }
            })
            CustomListItem({
              text: "结束时间",

              onClickBtn: () => {
              }
            })
            CustomListItem({
              text: "加入方式(必填)",

              onClickBtn: () => {
              }
            })
            CustomListItem({
              text: "身份限制(必填)",

              onClickBtn: () => {
              }
            })
            CustomListItem({
              text: "公开范围(必填)",

              onClickBtn: () => {
              }
            })
            CustomListItem({
              text: "锁定状态",

              onClickBtn: () => {
              }
            })
          }
        }
        .flexGrow(1)

        Button('确定', { type: ButtonType.Normal })
          .flexShrink(0)
          .width('100%')
          .margin({top:12})
          .borderRadius(0)
          .backgroundColor('#40A9FF')
      }
    }
    .title(CustomNavTitle('创建课程'))
    .backgroundColor("#f1f1f1")
  }
}

@Builder
export function CreateCourseBuilder() {
  CreateCourse()
}
