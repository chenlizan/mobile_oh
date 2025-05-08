import { webview } from "@kit.ArkWeb"
import { CustomLocalH5, Toolkits } from "./CustomLocalH5"
import { CustomNavTitle } from "@xy/basic"

class Description extends Toolkits {
  static richText: string = ''

  onRichChange(dataSource: string) {
    Description.richText = dataSource
  }
}

@Component
struct CourseDescription {
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @State controller: webview.WebviewController = new webview.WebviewController()
  private param: string = ''
  private toolkits = new Description()

  aboutToAppear(): void {
    this.param = String(this.pageInfos.getParamByName('courseDescription')[0])
  }

  getUrlPath() {
    return '#/groupDescription?mode=edit'
  }

  injectedExtraJavaScript = () => {
    const courseDesc = this.param
    return `window.course_desc=${courseDesc};`
  }

  build() {
    NavDestination() {
      Flex({ direction: FlexDirection.Column }) {
        CustomLocalH5({
          url: this.getUrlPath(),
          methodList: ['onRichChange'],
          extraJavaScript: this.injectedExtraJavaScript(),
          controller: this.controller,
          toolkits: this.toolkits,
        })
      }
    }
    .title(CustomNavTitle('课程简介'))
    .backgroundColor("#f1f1f1")
    .onBackPressed(() => {
      this.pageInfos.pop(Description.richText)
      return true;
    })
  }
}

@Builder
export function CourseDescriptionBuilder() {
  CourseDescription()
}
