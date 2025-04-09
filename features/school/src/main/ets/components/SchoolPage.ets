import _ from "@wolfx/lodash";
import {
  Api_Context,
  CCApi,
  ccApiPost,
  getApiHostDomain,
  isJSON,
  ObjectOption,
  ObjectUtil,
  PreferenceStorage,
  RouterConstants,
  School,
  xyApiPost
} from "@xy/basic";

@Component
export struct SchoolPage {
  @Link globalPageIndex: string;
  @State schoolList: Array<School> = []
  @State isRefreshing: boolean = false
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @StorageLink('PreferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage()
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  private maxSchool = Api_Context.isTest ? 1 : 8;

  aboutToAppear(): void {
    this.handleSchoolList()
  }

  handleSelect(schoolData: School) {
    this.preferenceStorage.school = schoolData;
    this.Api_Context = new Api_Context(schoolData.domain)
    this.getDesEncryptKey(['1', '2', '5', '6'])
  }

  async getDesEncryptKey(params: Array<string>) {
    const response = await ccApiPost(this.Api_Context.getApiPrefix('ccApi') + CCApi.queryDesEncryptKey, params)
    if (response.code === 200) {
      this.preferenceStorage.des_encrypt_key = response.result as Array<string>
      this.globalPageIndex = RouterConstants.LOGIN_PAGE_URL
    } else {
      this.getDesEncryptKey(['1', '2', '5', '6'])
    }
  }

  async handleSchoolList(cb?: () => void) {
    const response = await xyApiPost(Api_Context.getApplicationConfig(),
      { 'appName': Api_Context.isTest ? 'tst_app_portal' : 'prd_app_portal' },
      {
        'Content-Type': 'application/json; charset=utf-8',
        'Authorization': Api_Context.getApplicationToken()
      },)
    if (response.code === 200) {
      let schoolList: Array<School> = [];
      if (!_.isEmpty(response.data)) {
        _.map(response.data, (item: never) => {
          const _item = new ObjectUtil(item as ObjectOption<never>)
          const _value = _item.getValue('value')
          if (_.isString(_value) && _.trim(_value)) {
            if (isJSON(_value)) {
              const detail = new ObjectUtil(JSON.parse(_value) as ObjectOption<string>);
              const _code = detail.getValue('code').match(/\d+/g)
              schoolList.push({
                code: _code ? _code[0] : '',
                real_code: detail.getValue('code'),
                name: detail.getValue('name_cn'),
                logo: detail.getValue('school_badge'),
                banner_name: detail.getValue('banner_name'),
                banner_icon: detail.getValue('banner_icon'),
                domain: getApiHostDomain(detail.getValue('portal')),
                access_date: detail.getValue('access_date'),
                offering_type: detail.getValue('offering_type'),
                is_other: false,
              })
            }
          }
        })
      }
      if (!_.isEmpty(schoolList)) {
        // school 排序
        schoolList = _.orderBy(
          schoolList,
          ['offering_type', 'access_date'],
          ['asc', 'asc'],
        );
      }
      this.schoolList = schoolList
      if (cb) {
        setTimeout(() => {
          cb()
        }, 500)
      }
    }
  }

  @Builder
  BuildSchoolList() {
    Refresh({ refreshing: $$this.isRefreshing }) {
      Grid() {
        ForEach(this.schoolList, (item: School, index: number) => {
          if (index < this.maxSchool) {
            GridItem() {
              Column() {
                Image(item.logo)
                  .width(56)
                  .height(56)
                  .margin({ top: 8, bottom: 8 })
                Text(item.name)
                  .fontColor('#999999')
                  .fontSize(12)
              }
              .onClick(() => {
                this.handleSelect(item) //登陆选择学校
              })
            }
          }
        })
      }
      .columnsTemplate('1fr 1fr')
    }.onRefreshing(() => {
      this.handleSchoolList(() => {
        this.isRefreshing = false;
      })
    })
  }

  build() {
    NavDestination() {
      Column() {
        Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center }) {
          Row() {
            Text('请选择学校')
              .fontColor('#999999')
          }.margin({
            bottom: 20
          })

          this.BuildSchoolList()
          Row() {
            if (this.schoolList.length > 8) {
              Text('查看更多开课院校 >')
                .fontColor('#40A9FF')
                .fontSize(12)
                .onClick(() => {
                  this.pageInfos.pushPath({
                    name: 'allSchool', onPop: (popInfo: PopInfo) => {
                      this.handleSelect(popInfo.result as School)
                    }
                  })
                })
            }
            Text('其他用户登录 >')
              .fontColor('#40A9FF')
              .fontSize(12)
              .visibility(Visibility.Hidden)
          }
          .width('100%')
          .padding({ left: 32, right: 32, bottom: 16 })
          .justifyContent(FlexAlign.SpaceBetween)
        }
        .height('60%')
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.End)
      .backgroundImage($r('app.media.school_bg'))
      .backgroundImageSize({ width: '100%', height: '100%' })
    }
  }
}
