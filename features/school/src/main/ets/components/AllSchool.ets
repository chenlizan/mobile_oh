import _ from "@wolfx/lodash";
import {
  Api_Context,
  CustomNavTitle,
  getApiHostDomain,
  isJSON,
  ObjectOption,
  ObjectUtil,
  PreferenceStorage,
  School,
  xyApiPost
} from "@xy/basic";

@Component
export struct AllSchool {
  @State schoolList: Array<School> = []
  @State isRefreshing: boolean = false
  @State searchValue: string = ''
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @StorageLink('PreferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage()

  aboutToAppear(): void {
    this.handleSchoolList()
  }

  handleSelect(schoolData: School) {
    this.preferenceStorage.school = schoolData;
    this.pageInfos.pop(schoolData)
  }

  onGetSchools() {
    return _.filter(this.schoolList, school => {
      if (_.trim(this.searchValue)) {
        return school.name.indexOf(this.searchValue) !== -1;
      }
      return true;
    });
  };

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
        ForEach(this.onGetSchools(), (item: School, index: number) => {
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
        Search({ placeholder: '请输入要搜索的关键字' })
          .placeholderColor('#999999')
          .borderWidth(1.5)
          .borderColor({
            top: Color.White,
            bottom: '#f1f1f1',
            left: Color.White,
            right: Color.White
          })
          .borderRadius(0)
          .backgroundColor(Color.White)
          .onChange((value) => {
            this.searchValue = value
          })
        this.BuildSchoolList()
      }
      .margin({ left: 16, right: 16 })
      .borderRadius({ topLeft: 4, topRight: 4 })
      .backgroundColor(Color.White)
    }
    .title(CustomNavTitle('全部开课院校'))
    .backgroundColor("#f1f1f1")
  }
}

@Builder
export function AllSchoolBuilder(name: string) {
  AllSchool()
}