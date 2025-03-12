import { School } from "./SchoolModel"

export class PreferenceStorage {
  school?: School | null
  selectSpace?: object | null
  access_token?: string
  refreshToken?: string
  refresh_token_state?: string
  need_select_space?: boolean
  is_agreement?: boolean
  des_encrypt_key?: Array<string>
}