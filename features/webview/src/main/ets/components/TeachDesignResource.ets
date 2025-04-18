import _ from '@wolfx/lodash'
import { CustomLocalH5 } from '@xy/basic'

@Component
struct TeachDesignResource {
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  private param: Record<string, string | number | boolean | Record<string, string>> = {}

  aboutToAppear(): void {
    this.param = JSON.parse(String(this.pageInfos.getParamByName('teachDesignResource')[0]))
  }

  getUrlPath() {
    const item = this.param.item as Record<string, string>
    let path = `#/paper_mobile/teach_design/${item.quote_id}`
    return path
  }

  build() {
    NavDestination() {
      CustomLocalH5({
        url: this.getUrlPath()
      })
    }
    .hideTitleBar(true)
  }
}

@Builder
export function TeachDesignResourceBuilder() {
  TeachDesignResource()
}