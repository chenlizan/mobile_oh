import { School } from "./SchoolModel"
import { SelectSpace } from "./SelectSpaceModel"

export class PreferenceStorage {
  school?: School | null
  selectSpace?: SelectSpace | null
  access_token?: string
  refresh_token?: string
  refresh_token_state?: string
  need_select_space?: boolean
  is_agreement?: boolean
  des_encrypt_key?: Array<string>
  saveUsername?: string
  savePassword?: string
}