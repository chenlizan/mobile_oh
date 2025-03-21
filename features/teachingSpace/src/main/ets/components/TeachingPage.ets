import { CustomLocalH5 } from "@xy/basic";

@Component
export struct TeachingPage {
  build() {
    Row() {
      Column() {
        CustomLocalH5({
          url: '/note?node_id=5974622286299329679&resource_id=5974622286299329679&group_id=null&type=document&mode=edit'
        })
      }
      .width('100%')
    }
    .height('100%')
  }
}
