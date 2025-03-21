import {
  abilityAccessCtrl,
  AbilityConstant,
  PermissionRequestResult,
  Permissions,
  UIAbility,
  Want
} from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { font } from '@kit.ArkUI'
import { hilog } from '@kit.PerformanceAnalysisKit';
import { PreferenceStorage, RouterConstants, SystemNoticeStorage } from '@xy/basic';
import { BusinessError } from '@kit.BasicServicesKit';

const permissions: Array<Permissions> = ['ohos.permission.CAMERA', 'ohos.permission.APP_TRACKING_CONSENT','ohos.permission.MICROPHONE'];

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    setTimeout(() => {
      windowStage.loadContent('pages/Index', (err) => {
        if (err.code) {
          hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
          return;
        }
        PersistentStorage.persistProp('globalPageIndex', RouterConstants.AGREEMENT_PAGE_URL);
        PersistentStorage.persistProp('PreferenceStorage', new PreferenceStorage());
        PersistentStorage.persistProp('SystemNoticeStorage', new SystemNoticeStorage())
        font.registerFont({
          familyName: 'IconFont',
          familySrc: $rawfile('iconfont.ttf')
        })
        hilog.info(0x0000, 'testTag', 'Succeeded in loading the content.');
      });
    }, 500)

    let atManager = abilityAccessCtrl.createAtManager();
    atManager.requestPermissionsFromUser(this.context, permissions).then((result: PermissionRequestResult) => {
      console.info(`get Permission success, result: ${JSON.stringify(result)}`);
    }).catch((error: BusinessError) => {
      console.error(`get Permission error, error. Code: ${error.code}, message: ${error.message}`);
    })
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onBackground');
  }
}
