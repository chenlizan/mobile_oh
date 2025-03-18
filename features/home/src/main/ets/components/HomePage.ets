import { RouterConstants, CustomToast, IconConstants, } from "@xy/basic";

@Component
export struct HomePage {
  @Link globalPageIndex: string;

  build() {
    Column() {
      Button('空间选择')
        .onClick(() => {
          this.globalPageIndex = RouterConstants.IDENTITY_PAGE_URL
        })
    }
    .width('100%')
    .height('100%')
  }
}
