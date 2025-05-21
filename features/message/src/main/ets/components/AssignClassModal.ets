import _ from "@wolfx/lodash";
import { CustomModalDialog, CustomToast } from "@xy/basic";

@Component
export struct AssignClassModal {
  @Link visible: boolean
  @Link classList: Record<string, string | number>[]
  @Prop selectClass: Record<string, string | number> = {}
  @Prop title: string = '选择班级'
  @Prop name: string = ''
  @Prop data: Record<string, string | number | boolean> = {}
  @Prop remind: string = ''
  onSelect: (selectClass: Record<string, string | number> ) => void = () => {
  }

  @Builder
  BuildModalContent(classList: Record<string, string | number>[]) {
    Column() {
      if (!!_.trim(this.name)) {
        Text(this.name)
          .margin({top: 8, bottom: 8})
          .borderWidth({bottom: 1})
          .fontSize(15)
          .fontWeight(400)
      }

      List() {
        ForEach(classList, (item: Record<string, string | number>) => {
          ListItem() {
            Flex({alignItems: ItemAlign.Center}) {
              Text(item.class_name as string)
                .margin({ right: 12 })
                .fontSize(15)
                .maxLines(3)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .flexGrow(1)
              Checkbox()
                .select(this.selectClass.class_id === item.class_id)
                .selectedColor(0x40A9FF)
                .shape(CheckBoxShape.CIRCLE)
                .onChange((value: boolean) => {
                  if (value) {
                    this.selectClass = item
                  } else {
                    if (this.selectClass.class_id === item.class_id) {
                      this.selectClass = {}
                    }
                  }
                })
            }
            .width('100%')
            .margin({ bottom: 8 })
          }
        })
      }
      .width('100%')
      .padding(16)
    }
  }

  @Builder
  BuildModalFooter() {
    Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.SpaceBetween }) {
      if (!!_.trim(this.remind)) {
        Text(this.remind)
          .fontColor(Color.Red)
          .fontSize(13)
          .lineHeight(16)
          .flexGrow(1)
      } else {
        Blank()
      }

      Row() {
        Button('取消', { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.NORMAL })
          .margin({ left: 8, right: 8 })
          .borderRadius(4)
          .fontColor('#999999')
          .backgroundColor('#F5F5F5')
          .onClick(() => {
            this.visible = false
          })

        Button('确定', { type: ButtonType.Normal })
          .margin({ left: 8, right: 8 })
          .borderRadius(4)
          .fontColor(Color.White)
          .backgroundColor('#40A9FF')
          .onClick(() => {
            if (_.isEmpty(this.selectClass)) {
              CustomToast.toast_info('请选择班级');
              return;
            }
            this.onSelect(this.selectClass)
          })
      }
    }
    .margin({ top: 8, bottom: 8 })
  }

  build() {
    CustomModalDialog({
      visible: $visible,
      title: this.title,
      contentBuilder: () => this.BuildModalContent(this.classList),
      footerBuilder: () => this.BuildModalFooter(),
    })
  }
}