import { sendablePreferences, preferences } from '@kit.ArkData'
import { hilog } from '@kit.PerformanceAnalysisKit'

const TAG: string = 'PreferenceUtil'

const LOCAL_DB = 'local_db'

class PreferenceUtil {

  private _preference?: sendablePreferences.Preferences | undefined;

  getPreferenceFile(context: Context, fileName: string) {
    this._preference = sendablePreferences.getPreferencesSync(context, { name: fileName })
    return this
  }

  getConfigPreference(context: Context): PreferenceUtil {
    return this.getPreferenceFile(context, LOCAL_DB)
  }

  saveModel<T>(key: string, value: T) {
    this._preference?.putSync(key, JSON.stringify(value))
    this._preference?.flush()
  }

  deleteKey(key: string) {
    this._preference?.deleteSync(key)
    this._preference?.flush()
  }

  clearPreference() {
    this._preference?.clearSync()
    this._preference?.flush()
  }

  getModel<T>(name: string): T | null {
    let value: string | undefined;
    try {
      value = this._preference?.getSync(name, '') as string || undefined;

      if (!value) {
        return null;
      }
      return JSON.parse(value) as T;
    } catch (e) {
      hilog.error(0x000, TAG, 'Failed to read value, cause:' + e);
      return null
    }
  }

}

export const preferenceUtil = new PreferenceUtil()
