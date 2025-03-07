import { School } from "./SchoolModel"

export class PreferenceStorage {
  school?: School | null
  selectSpace?: object | null
  access_token?: string
  need_select_space?: boolean
  is_agreement?: boolean
}