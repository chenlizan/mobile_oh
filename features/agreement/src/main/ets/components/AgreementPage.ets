import { PreferenceStorage, RouterConstants } from "@xy/basic";

@Component
export struct AgreementPage {
  @Link globalPageIndex: string;
  @StorageLink('preferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage();

  handleAgree = () => {
    this.preferenceStorage.is_agreement = true;

    this.globalPageIndex = RouterConstants.SCHOOL_PAGE_URL
  }

  build() {
    NavDestination() {
      Row() {
        Column() {
          Text('隐私协议')
            .fontSize(50)
            .fontWeight(FontWeight.Bold)
          Button('知道了')
            .fontSize(50)
            .fontWeight(FontWeight.Bold)
            .buttonStyle(ButtonStyleMode.TEXTUAL)
            .onClick(this.handleAgree)
        }
        .width('100%')
      }
      .height('100%')
    }
  }
}
