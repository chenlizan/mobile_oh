import { ComponentContent, display, window } from "@kit.ArkUI"
import _ from "@wolfx/lodash"
import dayjs from "dayjs"
import {
  Api_Context,
  AppIcon,
  CCApi,
  ccApiGet,
  ccApiPost,
  CustomAlertDialog,
  CustomNavTitle,
  CustomToast,
  getCourseInfo,
  HomeApi,
  IconConstants,
  PreferenceStorage,
  UserInfoModel,
  xyApiGet,
  xyApiPost
} from "@xy/basic"

class MenuParam {
  creator: string = ''
  group_id: string = ''
  course_property: string = ''
  end_time: string = ''
  filterIndex: number = 0
  lock: number = 0
  role: number = 0
  name: string = ''
  origin_type: string = ''
  public_type: string = ''
  hide: () => void = () => {
  }
  refresh: () => void = () => {
  }
}

@Builder
function BuildHeaderMenu(params: MenuParam) {
  Column() {
    Text('创建课程')
      .fontColor('#40A9FF')
      .padding({
        left: 24,
        right: 24,
        top: 12,
        bottom: 12
      })
      .onClick(() => {
        const pageInfos = AppStorage.get<NavPathStack>('pageInfos')
        pageInfos?.pushPath({
          name: 'createCourse', param: JSON.stringify({ 'timeFlag': params.filterIndex + 1 }), onPop: () => {
            params.refresh()
          }
        })
        params.hide()
      })
    Divider()
    Text('加入课程')
      .fontColor('#40A9FF')
      .padding({
        left: 24,
        right: 24,
        top: 12,
        bottom: 12
      })
      .onClick(() => {
        const pageInfos = AppStorage.get<NavPathStack>('pageInfos')
        const userInfo = AppStorage.get<UserInfoModel>('UserInfo')
        if (userInfo?.isSchoolFellow) {
          CustomToast.toast_fail('校友可以直接访问课程进行学习，不必加入课程')
          return
        }
        pageInfos?.pushPath({
          name: 'joinCourse', onPop: () => {
            params.refresh()
          }
        })
        params.hide()
      })
    Divider()
    Text('取消')
      .fontColor('#999999')
      .padding({
        left: 24,
        right: 24,
        top: 12,
        bottom: 12
      })
      .onClick(() => {
        params.hide()
      })
  }
  .margin(48)
  .backgroundColor(Color.White)
  .borderRadius(8)
}

@Builder
function BuildLongPressMenu(params: MenuParam) {
  Column() {
    Text('查看课程')
      .fontColor('#40A9FF')
      .padding({
        left: 24,
        right: 24,
        top: 12,
        bottom: 12
      })
      .onClick(() => enterCourse(params))
    Divider()
    Text(params.role === 3 && params.origin_type === '2' ? '删除课程' : '退出课程')
      .fontColor('#40A9FF')
      .padding({
        left: 24,
        right: 24,
        top: 12,
        bottom: 12
      })
      .onClick(async () => {
        if (dayjs().isAfter(dayjs(params.end_time))) {
          CustomToast.toast_fail('课程已经结课，不允许操作')
          return
        }
        if (params.lock === 2) {
          CustomToast.toast_fail('本课程已锁定，暂不支持退出课程')
          return
        }
        if (params.role === 2 && params.origin_type === '0' || params.origin_type === '1') {
          CustomToast.toast_fail('该课程为教务中心开课，不允许删除')
          return
        }
        if (params.role === 3 && params.course_property === '2') {
          CustomToast.toast_fail('不可以删除mooc课程')
          return
        }
        const is_creator = params.role === 3 && params.origin_type === '2'
        CustomAlertDialog({
          'title': '提示',
          'message': is_creator ? `删除课程后不可恢复，确定要删除课程《${params.name}》吗？` :
            `是否退出课程《${params.name}》`,
          onClickBtn: async () => {
            const Api_Context = AppStorage.get<Api_Context>('Api_Context')
            if (is_creator) {
              const response = await xyApiPost(Api_Context?.getApiPrefix('baseApi_inner') + HomeApi.deleteGroup,
                { 'group_id': params.group_id })
              if (response.success) {
                CustomToast.toast_success('课程删除成功')
                params.refresh()
                params.hide()
              }
            } else {
              const response = await xyApiPost(Api_Context?.getApiPrefix('baseApi_inner') + HomeApi.quitGroup,
                { 'group_id': params.group_id })
              if (response.success) {
                CustomToast.toast_success('退出成功')
                params.refresh()
                params.hide()
              }
            }
          }
        })
      })
    Divider()
    Text('取消')
      .fontColor('#999999')
      .padding({
        left: 24,
        right: 24,
        top: 12,
        bottom: 12
      })
      .onClick(() => {
        params.hide()
      })
  }
  .margin(48)
  .backgroundColor(Color.White)
  .borderRadius(8)
}

const enterCourse = async (params: MenuParam) => {
  const pageInfos = AppStorage.get<NavPathStack>('pageInfos')
  const userInfo = AppStorage.get<UserInfoModel>('UserInfo')
  const Api_Context = AppStorage.get<Api_Context>('Api_Context')
  if (params.role === 1 && dayjs(params.end_time).isBefore(dayjs())) {
    const can_watch_module = await (async (): Promise<string[]> => {
      const response = await xyApiGet(Api_Context?.getApiPrefix('baseApi_inner') + HomeApi.groupFiledSetting,
        { 'group_id': params.group_id },)
      if (response?.success) {
        const data = response.data as Record<string, Record<string, Array<string>>>
        if (data.end_setting) {
          return data.end_setting.can_watch_module ?? []
        }
      }
      return []
    })()
    if (_.isEmpty(can_watch_module)) {
      CustomToast.toast_fail('本课程已结课，教师已设置为不可访问')
      return
    }
  }
  if (params.public_type === '1' && userInfo?.id !== params.creator) {
    CustomToast.toast_fail('该课程未公开，无法访问')
    return
  }
  if (params.hide) {
    params.hide()
  }
  pageInfos?.pushPath({ name: 'courseDetailPage' })
}

@Component
struct CourseList {
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @StorageLink('UserInfo') userInfo: UserInfoModel = new UserInfoModel()
  @StorageLink('PreferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage()
  @State screenWidth: number = 0
  @State screenHeight: number = 0
  @State isRefreshing: boolean = false
  @State siteCountNum: Record<string, number> = {}
  @State teach: number = 0
  @State showFilter: boolean = true
  @State @Watch('onChange') currentIndex: number = 0
  @State @Watch('onChange') filterIndex: number = 0
  @State @Watch('onChange') schoolIndex: number = 0
  @State @Watch('onChange') domainIndex: number = 0
  @State @Watch('onChange') termIndex: number = 0
  @State schoolName: string = ''
  @State domainName: string = ''
  @State termName: string = ''
  @State courseTeachList: Record<string, string>[] = []
  @State courseStuList: Record<string, string>[] = []
  @State courseCollectList: Record<string, string>[] = []
  @State courseVisitList: Record<string, string>[] = []
  @State courseDomainList: Record<string, string>[] = []
  @State courseTermList: Record<string, string>[] = []
  @State siteCerts: Record<string, Record<string, string>[]> = {}
  @State collectPageNum: number = 1
  @State visitPageNum: number = 1

  async getSiteCountNum() {
    const response = await ccApiGet(this.Api_Context.getApiPrefix("ccApi_common") + CCApi.getSiteCountNum)
    if (response.code === 0) {
      this.siteCountNum = response.result as Record<string, number>
      this.teach = (this.siteCountNum?.t1 ?? 0) + (this.siteCountNum?.t2 ?? 0) + (this.siteCountNum?.t3 ?? 0)
    }
  }

  async queryTeacherGroups() {
    const response =
      await xyApiGet(this.Api_Context.getApiPrefix('baseApi_inner') + HomeApi.queryTeacherGroups,
        { 'time_flag': this.filterIndex + 1 })
    if (response.success) {
      this.courseTeachList = _.orderBy(response.data, ['start_time'], ['desc'])
      this.querySiteCertificate()
    }
  }

  async queryStudentGroups() {
    const response =
      await xyApiGet(this.Api_Context.getApiPrefix('baseApi_inner') + HomeApi.queryStudentGroups,
        { 'time_flag': this.filterIndex + 1 })
    if (response.success) {
      this.courseStuList = _.orderBy(response.data, ['start_time'], ['desc'])
      this.querySiteCertificate()
    }
  }

  async queryGroupCollects() {
    const response = await xyApiGet(this.Api_Context.getApiPrefix('baseApi_inner') + HomeApi.queryGroupCollects,
      { 'page_num': this.collectPageNum, 'page_size': 10 })
    if (response.success) {
      this.courseCollectList =
        this.courseCollectList.concat((response.data as Record<string, Record<string, string>[]>).groups ?? [])
      this.querySiteCertificate()
      this.collectPageNum += 1
    }
  }

  async queryGroupVisits() {
    const response = await xyApiGet(this.Api_Context.getApiPrefix('baseApi_inner') + HomeApi.groupVisits,
      { 'page_num': this.visitPageNum, 'page_size': 10 })
    if (response.success) {
      this.courseVisitList =
        this.courseVisitList.concat((response.data as Record<string, Record<string, string>[]>).groupInfos ?? [])
      this.querySiteCertificate()
      this.visitPageNum += 1
    }
  }

  async queryDomain() {
    const domainList: Record<string, string>[] = []
    const result = _.find(this.currentIndex === 0 ? this.courseTeachList : this.courseStuList,
      i => i.school_name === this.schoolName)
    if (result) {
      const response = await ccApiPost(this.Api_Context.getApiPrefix('ccApi') + CCApi.getDomainList, { 'status': 1 },
        { 'schoolId': result.school_id })
      if (response.code === 200) {
        domainList.push({
          'title': '不限学段'
        })
        _.forEach(response.result, (item: Record<string, string>) => {
          domainList.push({ 'title': item.domainName })
        })
      }
    }
    this.courseDomainList = domainList
  }

  async queryTerm() {
    const termList: Record<string, string>[] = [{
      'title': '不限学期'
    }]
    const result = _.find(this.currentIndex === 0 ? this.courseTeachList : this.courseStuList,
      i => i.school_name === this.schoolName)
    if (result) {
      const response = await ccApiPost(this.Api_Context.getApiPrefix('ccApi') + CCApi.getTermList, { 'isVisual': 1 },
        { 'schoolId': result.school_id })
      if (response.code === 200) {
        _.forEach(_.orderBy(response.result, ['termSort'], ['desc']), (item: Record<string, string>) => {
          termList.push({ 'title': item.termName })
        })
      }
    }
    this.courseTermList = termList
  }

  async querySiteCertificate() {
    const response = await ccApiPost(this.Api_Context.getApiPrefix('ccApi') + CCApi.getSiteCertificate, _.map((() => {
      switch (this.currentIndex) {
        case 0:
          return this.courseTeachList
        case 1:
          return this.courseStuList
        case 2:
          return this.courseCollectList
        case 3:
          return this.courseVisitList
        default:
          return []
      }
    })(), item => item.site_id))
    if (response.code === 200) {
      this.siteCerts = response.result as Record<string, Record<string, string>[]>
    }
  }

  onChange(changedPropertyName: string) {
    switch (changedPropertyName) {
      case 'currentIndex':
        this.filterIndex = 0
        this.schoolIndex = 0
        this.domainIndex = 0
        this.termIndex = 0
        this.courseDomainList = []
        this.courseTermList = []
        break
      case 'filterIndex':
        this.schoolName = ''
        this.domainName = ''
        this.termName = ''
        this.schoolIndex = 0
        this.domainIndex = 0
        this.termIndex = 0
        this.courseDomainList = []
        this.courseTermList = []
        break
      case 'schoolIndex':
        this.domainName = ''
        this.termName = ''
        this.domainIndex = 0
        this.termIndex = 0
        break
    }

    if (changedPropertyName === 'currentIndex' || changedPropertyName === 'filterIndex') {
      switch (this.currentIndex) {
        case 0:
          this.queryTeacherGroups()
          break
        case 1:
          this.queryStudentGroups()
          break
        case 2:
          this.queryGroupCollects()
          break
        case 3:
          this.queryGroupVisits()
          break
      }
    }

    if (changedPropertyName === 'schoolIndex') {
      this.queryDomain()
      if (this.currentIndex === 1 && this.filterIndex === 2) {
        this.queryTerm()
      }
    }
  }

  aboutToAppear(): void {
    this.screenWidth = px2vp(display.getDefaultDisplaySync().width)
    this.screenHeight = px2vp(display.getDefaultDisplaySync().height)
    this.getSiteCountNum()
    this.onChange('currentIndex')
  }

  @Builder
  BuildNavRightBtn() {
    AppIcon({
      iconCode: IconConstants.SEARCH,
      iconSize: 16,
      iconMargin: { right: 8 },
      onClickBtn: () => {
        this.pageInfos.pushPath({ name: 'searchCourse' })
      }
    })
    AppIcon({
      iconCode: IconConstants.ADD,
      iconSize: 16,
      onClickBtn: async () => {
        const windowClass = await window.getLastWindow(getContext())
        const uiContext = windowClass.getUIContext()
        const params = new MenuParam()
        params.hide = () => {
          if (promptAction && customDialog) {
            promptAction.closeCustomDialog(customDialog)
            customDialog.dispose()
          }
        }
        params.refresh = () => {
          this.onChange('filterIndex')
        }
        params.filterIndex = this.filterIndex
        const customDialog = new ComponentContent(uiContext, wrapBuilder(BuildHeaderMenu), params)
        const promptAction = uiContext.getPromptAction()
        promptAction.openCustomDialog(customDialog)
      }
    })
  }

  @Builder
  BuildTabBar(index: number, name: string) {
    Column() {
      Text(name)
        .fontColor(this.currentIndex === index ? '#40A9FF' : Color.Black)
        .fontSize(16)
        .fontWeight(this.currentIndex === index ? 500 : 400)
        .lineHeight(22)
        .margin({ top: 10, bottom: 10 })
      Divider()
        .width('30%')
        .strokeWidth(2)
        .color('#40A9FF')
        .opacity(this.currentIndex === index ? 1 : 0)
    }.width('100%')
  }

  async build() {
    NavDestination() {
      Refresh({ refreshing: $$this.isRefreshing }) {
        Flex({ direction: FlexDirection.Column }) {
          Tabs() {
            ForEach((() => {
              const data: Record<string, string | number>[] = []
              const isStudent = this.userInfo.isRealStudent || this.userInfo.isSchoolFellow
              if (isStudent) {
                data.push({ 'name': '我学的课' })
                if (this.teach > 0) {
                  data.push({ 'name': '我教的课' })
                }
              } else {
                if (this.teach > 0) {
                  data.push({ 'name': '我教的课' })
                }
                data.push({ 'name': '我学的课' })
              }
              data.push({ 'name': '收藏的课' })
              data.push({ 'name': '访问的课' })
              return data
            })(), (item: Record<string, string | number>, index: number) => {
              TabContent().height(0).tabBar(this.BuildTabBar(index, item.name as string))
            })
          }
          .flexShrink(0)
          .height(56)
          .onChange((index: number) => {
            this.currentIndex = index
          })

          Flex({ alignItems: ItemAlign.Center }) {
            List() {
              ForEach((() => {
                const begin = this.siteCountNum[this.currentIndex === 1 ? 's1' : 't1'] ?? 0
                const wait = this.siteCountNum[this.currentIndex === 1 ? 's2' : 't2'] ?? 0
                const end = this.siteCountNum[this.currentIndex === 1 ? 's3' : 't3'] ?? 0
                return [`正在进行(${begin})`, `即将开课(${wait})`, `已结课(${end})`]
              })(), (item: string, index: number) => {
                ListItem() {
                  Text(item)
                    .padding(6)
                    .fontColor(this.filterIndex === index ? '#FCBB34' : '#999999')
                    .fontSize(14)
                    .onClick(() => this.filterIndex = index)
                }
              })
            }
            .width('100%')
            .height(32)
            .alignListItem(ListItemAlign.Center)
            .listDirection(Axis.Horizontal)
            .flexGrow(1)

            AppIcon({
              iconCode: IconConstants.FILTER,
              iconSize: 16,
              iconColor: this.showFilter ? '#40A9FF' : '#999999',
              onClickBtn: () => {
                this.showFilter = !this.showFilter
              }
            })
              .flexBasis(20)
          }
          .flexShrink(0)
          .height(32)
          .margin({
            left: 12,
            right: 12,
          })
          .visibility(this.currentIndex < 2 ? Visibility.Visible : Visibility.None)

          List() {
            ForEach((() => {
              const schoolList: Record<string, string>[] = []
              if (this.currentIndex > 1) {
                return schoolList
              }
              const schoolKeys = _.keys(
                _.groupBy(
                  _.filter(
                    this.currentIndex === 0 ? this.courseTeachList : this.courseStuList,
                    course => !!_.trim(course.school_name),
                  ),
                  'school_name',
                ),
              )
              if (schoolKeys.length > 0) {
                schoolList.push({
                  'title': '所有课程'
                })
                _.forEach(schoolKeys, (item) => {
                  schoolList.push({ 'title': item })
                })
              }
              return schoolList
            })(), (item: Record<string, string>, index: number) => {
              ListItem() {
                Text(item.title)
                  .padding(6)
                  .borderColor(this.schoolIndex === index ? '#40A9FF' : "#f1f1f1")
                  .borderRadius(4)
                  .borderWidth(1)
                  .backgroundColor(this.schoolIndex === index ? '#BEE2FF' : "#f1f1f1")
                  .fontColor(this.schoolIndex === index ? '#40A9FF' : "#999999")
                  .fontSize(14)
                  .textAlign(TextAlign.Center)
                  .onClick(() => {
                    this.schoolName = item.title
                    this.schoolIndex = index
                  })
              }
            })
          }
          .flexShrink(0)
          .width(this.screenWidth - 24)
          .height(32)
          .alignListItem(ListItemAlign.Center)
          .scrollBar(BarState.Off)
          .listDirection(Axis.Horizontal)
          .margin({
            left: 12,
            right: 12,
            bottom: 4
          })
          .visibility(!this.showFilter || this.currentIndex > 1 ||
            (_.isEmpty(this.courseTeachList) && _.isEmpty(this.courseStuList)) ?
          Visibility.None :
          Visibility.Visible)

          List() {
            ForEach(this.courseDomainList, (item: Record<string, string>, index: number) => {
              ListItem() {
                Text(item.title)
                  .padding(6)
                  .borderColor(this.domainIndex === index ? '#40A9FF' : "#f1f1f1")
                  .borderRadius(4)
                  .borderWidth(1)
                  .backgroundColor(this.domainIndex === index ? '#BEE2FF' : "#f1f1f1")
                  .fontColor(this.domainIndex === index ? '#40A9FF' : "#999999")
                  .fontSize(14)
                  .textAlign(TextAlign.Center)
                  .onClick(() => {
                    this.domainName = item.title
                    this.domainIndex = index
                  })
              }
            })
          }
          .flexShrink(0)
          .width(this.screenWidth - 24)
          .height(32)
          .alignListItem(ListItemAlign.Center)
          .scrollBar(BarState.Off)
          .listDirection(Axis.Horizontal)
          .margin({
            left: 12,
            right: 12,
            bottom: 4
          })
          .visibility(!this.showFilter || _.isEmpty(this.courseDomainList) ? Visibility.None : Visibility.Visible)

          List() {
            ForEach(this.courseTermList, (item: Record<string, string>, index: number) => {
              ListItem() {
                Text(item.title)
                  .padding(6)
                  .borderColor(this.termIndex === index ? '#40A9FF' : "#f1f1f1")
                  .borderRadius(4)
                  .borderWidth(1)
                  .backgroundColor(this.termIndex === index ? '#BEE2FF' : "#f1f1f1")
                  .fontColor(this.termIndex === index ? '#40A9FF' : "#999999")
                  .fontSize(14)
                  .textAlign(TextAlign.Center)
                  .onClick(() => {
                    this.termName = item.title
                    this.termIndex = index
                  })
              }
            })
          }
          .flexShrink(0)
          .width(this.screenWidth - 24)
          .height(32)
          .alignListItem(ListItemAlign.Center)
          .scrollBar(BarState.Off)
          .listDirection(Axis.Horizontal)
          .margin({
            left: 12,
            right: 12,
            bottom: 4
          })
          .visibility(!this.showFilter || _.isEmpty(this.courseTermList) ? Visibility.None : Visibility.Visible)

          if (((this.siteCountNum[this.currentIndex === 1 ? 's1' : 't1'] ?? 0) +
            (this.siteCountNum[this.currentIndex === 1 ? 's2' : 't2'] ?? 0) +
            (this.siteCountNum[this.currentIndex === 1 ? 's3' : 't3'] ?? 0)) === 0) {
            Column() {
              AppIcon({
                iconCode: IconConstants.NOTHING,
                iconSize: 60,
                iconColor: '#999999'
              })
              Text('暂无课程')
                .margin({ top: 8 })
              Text(`你可以通过点击${(this.currentIndex === 1 || this.userInfo.isSchoolFellow) ?
                '' : '“创建课程”按钮自主创建课程， 或者点击'}“加入课程”按钮加入课程的学习。`)
                .margin({ left: 28, right: 28, top: 8 })
                .fontColor('#999999')
                .fontSize(13)

              Row() {
                if (this.currentIndex === 1 || this.userInfo.isSchoolFellow || true) {
                  Button('创建课程', { type: ButtonType.Normal })
                    .fontColor(Color.White)
                    .backgroundColor('#1EB38F')
                    .borderRadius(4)
                }
                Button('加入课程', { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.NORMAL })
                  .margin({ left: 25 })
                  .fontColor('#999999')
                  .backgroundColor('#F5F5F5')
                  .borderColor('#999999')
                  .borderRadius(4)
                  .borderWidth(1)
              }
              .margin({ top: 60 })
            }
            .flexGrow(1)
            .justifyContent(FlexAlign.Center)
            .width(this.screenWidth)
          } else if (_.isEmpty(this.courseTeachList) && this.currentIndex === 0 ||
            _.isEmpty(this.courseStuList) && this.currentIndex === 1 ||
            _.isEmpty(this.courseCollectList) && this.currentIndex === 2 ||
            _.isEmpty(this.courseVisitList) && this.currentIndex === 3) {
            Column() {
              Text('暂无数据')
                .fontColor('#999999')
            }
            .flexGrow(1)
            .justifyContent(FlexAlign.Center)
            .width(this.screenWidth)
          } else {
            List() {
              ForEach((() => {
                let rows: Record<string, string>[] = []
                switch (this.currentIndex) {
                  case 0:
                    rows = this.courseTeachList
                    break
                  case 1:
                    rows = this.courseStuList
                    break
                  case 2:
                    rows = this.courseCollectList
                    break
                  case 3:
                    rows = this.courseVisitList
                    break
                  default:
                    rows = []
                }
                if (this.schoolIndex !== 0) {
                  rows = _.filter(rows, g => g.school_name === this.schoolName)
                }

                if (this.domainIndex !== 0) {
                  rows = _.filter(rows, g => g.domain_name === this.domainName)
                }

                if (this.termIndex !== 0) {
                  rows = _.filter(rows, g => g.term_name === this.termName)
                }

                return rows

              })(), (item: Record<string, string>) => {
                ListItem() {
                  Column() {
                    Row() {
                      Text(item.name)
                      Text('MOOC')
                        .padding({
                          left: 8,
                          right: 8,
                          top: 4,
                          bottom: 4
                        })
                        .backgroundColor('#EBEDF0')
                        .borderRadius(2)
                        .fontColor('#999999')
                        .fontSize(14)
                        .visibility(item.course_property === '2' ? Visibility.Visible : Visibility.None)
                    }
                    .justifyContent(FlexAlign.SpaceBetween)
                    .width(this.screenWidth - 40)
                    .margin({
                      left: 8,
                      right: 8,
                      top: 8,
                      bottom: 0
                    })

                    Row() {
                      Stack() {
                        Image(item.cover_img || $r('app.media.class_default_bg'))
                          .width(160)
                          .height(90)
                          .margin(8)
                          .borderRadius(4)
                        Column() {
                          Flex({ direction: FlexDirection.RowReverse, justifyContent: FlexAlign.End }) {
                            ForEach((() => {
                              return _.isEmpty(this.siteCerts) ? [] : (this.siteCerts[item.site_id] ?? [])
                            })(), (item: Record<string, string>, index: number) => {
                              Text(item.siteCertificateLevelName)
                                .margin({ left: (this.siteCerts[item.siteId] ?? []).length - index === 1 ? 0 : -8 })
                                .padding({
                                  left: (this.siteCerts[item.siteId] ?? []).length - index === 1 ? 8 : 16,
                                  right: 8,
                                  top: 4,
                                  bottom: 4
                                })
                                .borderRadius({ topLeft: 4, bottomRight: 10 })
                                .backgroundColor('#FCBB34')
                                .fontColor(Color.White)
                                .fontSize(12)
                                .shadow(ShadowStyle.OUTER_DEFAULT_SM)
                            })
                          }

                          Text(item.custom_info)
                            .padding({ top: 3, bottom: 3 })
                            .fontColor('#B9B9B9')
                            .fontSize(11)
                            .backgroundColor('rgba(0, 0, 0, 0.65)')
                          Text(getCourseInfo(item))
                            .width(160)
                            .padding({ top: 3, bottom: 3 })
                            .textAlign(TextAlign.Center)
                            .fontColor('#B9B9B9')
                            .fontSize(11)
                            .backgroundColor('rgba(0, 0, 0, 0.65)')
                            .borderRadius({ bottomLeft: 4, bottomRight: 4 })
                        }
                        .justifyContent(FlexAlign.SpaceBetween)
                        .alignItems(HorizontalAlign.Start)
                        .width(160)
                        .height(90)
                      }

                      Column() {
                        Text(`学院: ${item.department_name}`)
                          .fontColor('#999999')
                          .fontSize(13)
                          .width(this.screenWidth - 208)
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.MARQUEE })
                        Text(item.teacher_names)
                          .fontColor('#999999')
                          .fontSize(13)
                          .width(this.screenWidth - 208)
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.MARQUEE })
                        Flex({ justifyContent: FlexAlign.SpaceBetween }) {
                          Text(`访问量:${'' + item.visit_number}次`)
                            .fontColor('#999999')
                            .fontSize(13)
                          Row() {
                            AppIcon({
                              iconCode: IconConstants.USER,
                              iconSize: 13,
                              iconColor: '#999999',
                              iconMargin: { bottom: 2 }
                            })
                            Text(`${item.member_count}人`)
                              .fontColor('#999999')
                              .fontSize(13)
                          }
                        }
                      }
                      .justifyContent(FlexAlign.SpaceBetween)
                      .alignItems(HorizontalAlign.Start)
                      .width(this.screenWidth - 208)
                      .height(90)
                    }
                    .width(this.screenWidth - 40)
                  }
                  .width('auto')
                  .margin({ left: 12, right: 12, bottom: 8 })
                  .alignItems(HorizontalAlign.Start)
                  .backgroundColor(Color.White)
                  .borderRadius(4)
                  .gesture(LongPressGesture().onAction(async () => {
                    const windowClass = await window.getLastWindow(getContext())
                    const uiContext = windowClass.getUIContext()
                    const params = new MenuParam()
                    params.creator = item.creator
                    params.course_property = item.course_property
                    params.end_time = item.end_time
                    params.lock = Number(item.lock)
                    params.role = Number(item.role)
                    params.origin_type = item.origin_type
                    params.name = item.name
                    params.group_id = item.id
                    params.public_type = item.public_type
                    params.hide = () => {
                      if (promptAction && customDialog) {
                        promptAction.closeCustomDialog(customDialog)
                        customDialog.dispose()
                      }
                    }
                    params.refresh = () => {
                      this.onChange('filterIndex')
                    }
                    const customDialog = new ComponentContent(uiContext, wrapBuilder(BuildLongPressMenu), params)
                    const promptAction = uiContext.getPromptAction()
                    promptAction.openCustomDialog(customDialog)
                    this.preferenceStorage.currentTeam = item
                  }))
                  .onClick(() => {
                    const params = new MenuParam()
                    params.creator = item.creator
                    params.course_property = item.course_property
                    params.end_time = item.end_time
                    params.lock = Number(item.lock)
                    params.role = Number(item.role)
                    params.origin_type = item.origin_type
                    params.name = item.name
                    params.group_id = item.id
                    params.public_type = item.public_type
                    params.refresh = () => {
                      this.onChange('filterIndex')
                    }
                    enterCourse(params)
                    this.preferenceStorage.currentTeam = item
                  })
                }
              })
            }
            .flexGrow(1)
            .onReachEnd(() => {
              if (this.currentIndex === 2) {
                this.queryGroupCollects()
              } else if (this.currentIndex === 3) {
                this.queryGroupVisits()
              }
            })
          }
        }
      }
      .onRefreshing(() => {
        this.onChange('filterIndex')
        setTimeout(() => {
          this.isRefreshing = false
        }, 500)
      })
    }
    .title(CustomNavTitle('课程', () => this.BuildNavRightBtn()))
    .backgroundColor("#f1f1f1")
  }
}

@Builder
export function CourseListBuilder() {
  CourseList()
}