import { CustomList, CustomListItem, CustomNavTitle } from "@xy/basic";
import { common } from "@kit.AbilityKit";
import { updateManager } from "@kit.StoreKit";

@Component
export struct About {
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack();

  @Builder
  operateIcon() {
    Toggle({ type: ToggleType.Switch, isOn: false })
      .onChange((isOn: boolean) => {
        console.log(String(isOn))
      })
  }

  build() {
    NavDestination() {
      Row() {
        Text('小雅版本 2.2.2204')
      }
      .margin({ top: 160, bottom: 16 })

      CustomList() {
        CustomListItem({
          text: "检查版本更新",
          onClickBtn: async () => {
            updateManager.showUpdateDialog(getContext() as common.UIAbilityContext)
          }
        })
        // CustomListItem({
        //   text: "清除缓存"
        // })
        // CustomListItem({
        //   text: "系统消息通知",
        //   operateBuilder: this.operateIcon
        // })
        CustomListItem({
          text: '小雅用户服务协议',
          itemBorder: {},
          itemMargin: { top: 16 },
          onClickBtn: () => {
            this.pageInfos.pushPath({
              name: "agreement",
              param: JSON.stringify({
                title: '小雅用户服务协议',
                url: 'https://www.ai-augmented.com/user-agreement.html'
              })
            })
          }
        })
        CustomListItem({
          text: "小雅智能助手隐私政策",
          onClickBtn: () => {
            this.pageInfos.pushPath({
              name: "agreement",
              param: JSON.stringify({
                title: '小雅智能助手隐私政策',
                url: 'https://www.ai-augmented.com/privacy-agreement.html'
              })
            })
          }
        })
      }
    }
    .title(CustomNavTitle('关于小雅'))
    .backgroundColor("#f1f1f1")
  }
}


@Builder
export function AboutBuilder(name: string) {
  About()
}