import { PreferenceStorage, RouterConstants } from "@xy/basic";
import { School } from "../model/SchoolModel";

@Component
export struct SchoolPage {
  @Link globalPageIndex: string;
  @StorageLink('preferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage();

  handleSelect = () => {
    let schoolData: School = {
      code: 10051,
      real_code: 10051,
      name: '华中师范大学',
      logo: '',
      banner_icon: '',
      domain: 'test-ccnu',
      access_date: '',
      offering_type: '',
      is_other: false,
    };

    this.preferenceStorage.school = schoolData;
    this.globalPageIndex = RouterConstants.LOGIN_PAGE_URL
  }

  build() {
    NavDestination() {
      Row() {
        Column() {
          Text('学校')
            .fontSize(50)
            .fontWeight(FontWeight.Bold)
          Button('选择学校')
            .fontSize(50)
            .fontWeight(FontWeight.Bold)
            .buttonStyle(ButtonStyleMode.TEXTUAL)
            .onClick(this.handleSelect)
        }
        .width('100%')
      }
      .height('100%')
    }
  }
}
