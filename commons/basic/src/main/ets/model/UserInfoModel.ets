export class UserInfoModel {
  id: string = ''
  userId: string = ''
  mobile: string = ''
  nickname: string = ''
  realname: string = ''
  avatar: string = ''
  schools: Array<object> = []
  fileCapacity: object | null = null
  isRealStudent: boolean = false
  isSchoolFellow: boolean = false
  hasStudent: boolean = false
  manageSpaces: object | null = null
  userFeatures: Array<object> = []
}