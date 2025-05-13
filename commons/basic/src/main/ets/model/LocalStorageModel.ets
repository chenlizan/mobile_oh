import { School } from "./SchoolModel"
import { SelectSpace } from "./SelectSpaceModel"

export class PreferenceStorage {
  school?: School | null
  selectSpace?: SelectSpace | null
  access_token?: string
  refresh_token?: string
  refresh_token_state?: string
  access_group_token?: string //访客督导评审的独有token
  need_select_space?: boolean
  is_agreement?: boolean
  des_encrypt_key?: Array<string>
  saveUsername?: string
  savePassword?: string
  node_key?: string
  currentTeam?: Record<string, string | number | boolean>
  configCenter?: Record<string, string>[]
}