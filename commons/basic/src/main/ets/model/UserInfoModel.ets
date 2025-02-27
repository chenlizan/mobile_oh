export class UserInfoModel {
  private _id: string = ''

  public set id(value: string) {
    this._id = value
  }

  public get id(): string {
    return this._id
  }

  private _userId: string = ''

  public set userId(value: string) {
    this._userId = value
  }

  public get userId(): string {
    return this._userId
  }

  private _mobile: string = ''

  public set mobile(value: string) {
    this._mobile = value
  }

  public get mobile(): string {
    return this._mobile
  }

  private _nickname: string = ''

  public set nickname(value: string) {
    this._nickname = value
  }

  public get nickname(): string {
    return this._nickname
  }

  private _realname: string = ''

  public set realname(value: string) {
    this._realname = value
  }

  public get realname(): string {
    return this._realname
  }

  private _avatar: string = ''

  public set avatar(value: string) {
    this._avatar = value
  }

  public get avatar(): string {
    return this._avatar
  }

  private _schools: string = ''

  public set schools(value: string) {
    this._schools = value
  }

  public get schools(): string {
    return this._schools
  }

  private _fileCapacity: object | null = null

  public set fileCapacity(value: object | null) {
    this._fileCapacity = value
  }

  public get fileCapacity(): object | null {
    return this._fileCapacity
  }

  private _isRealStudent: boolean = false

  public set isRealStudent(value: boolean) {
    this._isRealStudent = value
  }

  public get isRealStudent(): boolean {
    return this._isRealStudent
  }

  private _isSchoolFellow: boolean = false

  public set isSchoolFellow(value: boolean) {
    this._isSchoolFellow = value
  }

  public get isSchoolFellow(): boolean {
    return this._isSchoolFellow
  }

  private _hasStudent: boolean = false

  public set hasStudent(value: boolean) {
    this._hasStudent = value
  }

  public get hasStudent(): boolean {
    return this._hasStudent
  }

  private _manageSpaces: object | null = null

  public set manageSpaces(value: object | null) {
    this._manageSpaces = value
  }

  public get manageSpaces(): object | null {
    return this._manageSpaces
  }

  private _userFeatures: Array<object> = []

  public set userFeatures(value: Array<object>) {
    this._userFeatures = value
  }

  public get userFeatures(): Array<object> {
    return this._userFeatures
  }
}