import { PreferenceStorage, } from "@xy/basic";
import { TeachingPage } from '@xy/teaching_space'

@Component
export struct HomePage {
  @Link globalPageIndex: string;
  @StorageLink('PreferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage();

  build() {
    Column() {
      if (this.preferenceStorage.selectSpace?.type === 'teaching') {
        TeachingPage({ globalPageIndex: this.globalPageIndex })
      }
    }
    .width('100%')
    .height('100%')
  }
}
