import { PreferenceStorage, RouterConstants, SelectSpace } from "@xy/basic";

// @Builder
// export function IdentitySelectPageBuilder(name: string, param: Object) {
//   IdentitySelectPage()
// }


@Component
export struct IdentitySelectPage {
  @Link globalPageIndex: string;
  @StorageLink('preferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage();

  handleSelect = async () => {
    this.preferenceStorage.selectSpace = {
      type: 'teaching',
      title: '教学空间',
      role: '',
      schoolId: '',
      schoolName: '',
    } as SelectSpace

    this.globalPageIndex = RouterConstants.MAIN_PAGE_URL
  }

  build() {
    NavDestination() {
      Row() {
        Column() {
          Text('选择身份')
            .fontSize(50)
            .fontWeight(FontWeight.Bold)
          Button('确定', { stateEffect: true, type: ButtonType.Capsule })
            .width('100%')
            .height('40px')
            .onClick(this.handleSelect)
        }
        .width('100%')
      }
      .height('100%')
    }
  }
}