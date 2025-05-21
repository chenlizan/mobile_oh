import _ from "@wolfx/lodash"
import {
  Api_Context,
  AppIcon,
  CCApi,
  ccApiGet,
  ccApiPost,
  CustomAlertDialog,
  AlertDialogParam,
  CustomDatePickerDialog,
  CustomList,
  CustomListItem,
  CustomNavTitle,
  CustomToast,
  HomeApi,
  IconConstants,
  translateRichText,
  UserInfoModel,
  xyApiPost
} from "@xy/basic"
import dayjs from "dayjs"

@Component
struct CreateCourse {
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @StorageLink('UserInfo') userInfo: UserInfoModel = new UserInfoModel()
  @State textAreaBorderColor: ResourceColor = '#d9d9d9'
  @State schoolList: Record<string, string>[] = []
  @State courseDomainList: Record<string, string>[] = []
  @State courseTermList: Record<string, string>[] = []
  @State siteName: string = ''
  @State courseDesc: string = ''
  @State schoolId: string = ''
  @State domainCode: string = ''
  @State termCode: string = ''
  @State startTime: Date = dayjs().toDate()
  @State startTimeVisible: boolean = false
  @State startTimeTitle: string = '开始时间'
  @State endTime: Date = dayjs().add(10, 'month').toDate()
  @State endTimeVisible: boolean = false
  @State endTimeTitle: string = '结束时间'
  @State joinType: number = 1
  @State identityFlag: number = 0
  @State publicType: number = 3
  @State lock: boolean = false
  private param: Record<string, string> = {}

  async queryUserSchoolInfo() {
    const response = await ccApiGet(this.Api_Context.getApiPrefix('ccApi') + CCApi.queryUserSchoolInfo,
      { 'userId': this.userInfo.userId })
    if (response.code === 200) {
      this.schoolList = response.result as Record<string, string>[] ?? []
      this.schoolList.push({ 'schoolName': '无', 'schoolId': '' })
    }
    this.schoolId = this.schoolList[0].schoolId
  }

  async queryDomain(schoolId: string) {
    const domainList: Record<string, string>[] = []
    const response = await ccApiPost(this.Api_Context.getApiPrefix('ccApi') + CCApi.getDomainList, { 'status': 1 },
      { 'schoolId': schoolId })
    if (response.code === 200) {
      _.forEach(response.result, (item: Record<string, string>) => {
        domainList.push({ 'title': item.domainName, 'value': item.domainCode })
      })
      domainList.push({
        'title': '无'
      })
    }
    this.courseDomainList = domainList
    this.domainCode = domainList[0].value
  }

  async queryTerm(schoolId: string) {
    const termList: Record<string, string>[] = []
    const response = await ccApiPost(this.Api_Context.getApiPrefix('ccApi') + CCApi.getTermList, { 'isVisual': 1 },
      { 'schoolId': schoolId })
    if (response.code === 200) {
      _.forEach(_.orderBy(response.result, ['termSort'], ['desc']), (item: Record<string, string>) => {
        termList.push({ 'title': item.termName, 'value': item.termCode })
      })
      termList.push({
        'title': '无'
      })
    }
    this.courseTermList = termList
    this.termCode = this.courseTermList[0].value
  }

  async aboutToAppear(): Promise<void> {
    this.param = JSON.parse(String(this.pageInfos.getParamByName('createCourse')[0]))
    await this.queryUserSchoolInfo()
    if (!_.isEmpty(this.schoolList)) {
      const schoolId = this.schoolList[0].schoolId
      this.queryDomain(schoolId)
      this.queryTerm(schoolId)
    }
  }

  @Builder
  BuildSchoolItem() {
    Select(this.schoolList.map((item) => {
      return { 'value': item.schoolName } as SelectOption
    }))
      .selected(0)
      .value(this.schoolList.length > 0 ? this.schoolList[0].schoolName : '')
      .onSelect((index: number) => {
        this.schoolId = this.schoolList[index].schoolId
      })
  }

  @Builder
  BuildDomainItem() {
    Select(this.courseDomainList.map((item) => {
      return { 'value': item.title } as SelectOption
    }))
      .selected(0)
      .value(this.courseDomainList.length > 0 ? this.courseDomainList[0].title : '')
      .onSelect((index: number) => {
        this.domainCode = this.courseDomainList[index].value
      })
  }

  @Builder
  BuildTermItem() {
    Select(this.courseTermList.map((item) => {
      return { 'value': item.title } as SelectOption
    }))
      .selected(0)
      .value(this.courseTermList.length > 0 ? this.courseTermList[0].title : '')
      .onSelect((index: number) => {
        this.termCode = this.courseTermList[index].value
      })
  }

  @Builder
  BuildStartTimeItem() {
    Row() {
      Text(this.startTime ? dayjs(this.startTime).format('YYYY-MM-DD') : '')
        .margin({ right: 8 })
        .fontColor('#999999')
        .fontSize(14)
      AppIcon({ iconCode: IconConstants.RIGHT })
    }
  }

  @Builder
  BuildEndTimeItem() {
    Row() {
      Text(this.endTime ? dayjs(this.endTime).format('YYYY-MM-DD') : '')
        .margin({ right: 8 })
        .fontColor('#999999')
        .fontSize(14)
      AppIcon({ iconCode: IconConstants.RIGHT })
    }
  }

  @Builder
  BuilderJoinTypeItem() {
    Column() {
      Select([{ value: '验证加入' }, { value: '自由加入' }, { value: '禁止加入' }])
        .selected(0)
        .value('验证加入')
        .onSelect((index: number) => {
          this.joinType = index + 1
        })
      Text((() => {
        switch ((this.joinType + 1).toString()) {
          case '1':
            return '*用户需经过验证后加入课程';
          case '2':
            return '*用户可以自由加入课程';
          case '3':
            return '*任何人禁止加入课程';
          default:
            return '';
        }
      })())
        .margin({ top: 8 })
        .fontColor('#999999')
        .fontSize(12)
        .textAlign(TextAlign.End)
    }
    .alignItems(HorizontalAlign.End)
  }

  @Builder
  BuilderIdentityFlagItem() {
    Column() {
      Select([{ value: '所有用户' }, { value: '仅教师' }])
        .selected(0)
        .value('所有用户')
        .onSelect((index: number) => {
          this.identityFlag = index
        })
      Text((() => {
        switch (this.identityFlag.toString()) {
          case '0':
            return '*所有人都可以加入课程';
          case '1':
            return '*仅限校内教师加入课程';
          default:
            return '';
        }
      })())
        .margin({ top: 8 })
        .fontColor('#999999')
        .fontSize(12)
        .textAlign(TextAlign.End)
    }
    .alignItems(HorizontalAlign.End)
  }

  @Builder
  BuilderPublicTypeItem() {
    Column() {
      Select([{ value: '私有' }, { value: '课内' }, { value: '校内' }, { value: '全网' }])
        .selected(2)
        .value('校内')
        .onSelect((index: number) => {
          this.publicType = index + 1
        })
      Text((() => {
        switch ((this.publicType + 1).toString()) {
          case '1':
            return '*私有课程仅教师可以查看';
          case '2':
            return '*课程内的成员可以查看课程';
          case '3':
            return '*校内用户可以查看课程';
          case '4':
            return '*课程全网可见';
          default:
            return '';
        }
      })())
        .margin({ top: 8 })
        .fontColor('#999999')
        .fontSize(12)
        .textAlign(TextAlign.End)
    }
    .alignItems(HorizontalAlign.End)
  }

  @Builder
  BuilderLockItem() {
    Column() {
      Toggle({
        isOn: this.lock,
        type: ToggleType.Switch
      })
        .onChange((isOn) => {
          this.lock = isOn
        })
      Text('*课程锁定后，用户无法加入课程；\n教师无法删除课程；学生无法修改群名片')
        .fontColor('#999999')
        .fontSize(12)
        .textAlign(TextAlign.End)
    }
    .alignItems(HorizontalAlign.End)
  }

  build() {
    NavDestination() {
      Flex({ direction: FlexDirection.Column }) {
        Scroll() {
          CustomList() {
            Column() {
              Text() {
                Span('*').fontColor(Color.Red)
                Span('课程名称(必填)')
              }
              .padding(12)

              TextArea({ placeholder: '请输入课程名称' })
                .height(75)
                .margin({ left: 16, right: 16 })
                .backgroundColor(Color.White)
                .borderColor(this.textAreaBorderColor)
                .borderRadius(4)
                .borderWidth(1)
                .placeholderColor('#999999')
                .maxLength(255)
                .onFocus(() => {
                  this.textAreaBorderColor = '#40A9FF'
                })
                .onBlur(() => {
                  this.textAreaBorderColor = '#d9d9d9'
                })
                .onChange((value: string) => {
                  this.siteName = value
                })
              Text('*测试课程使用后，请及时删除，否则会影响画像等数据，管理员将定期清理课程名称随意的课程')
                .padding(12)
                .fontColor('#999999')
                .fontSize(13)
            }
            .alignItems(HorizontalAlign.Start)
            .backgroundColor(Color.White)

            CustomListItem({
              text: "课程简介",
              onClickBtn: () => this.pageInfos.pushPath({
                name: 'courseDescription', param: this.courseDesc, onPop: (popInfo: PopInfo) => {
                  this.courseDesc = popInfo.result as string
                }
              })
            })
            CustomListItem({
              text: "开课学校",
              operateBuilder: () => this.BuildSchoolItem(),
              onClickBtn: () => {
              }
            })
            CustomListItem({
              text: "课程学段",
              operateBuilder: () => this.BuildDomainItem(),
              onClickBtn: () => {
              }
            })
            CustomListItem({
              text: "课程学期",
              operateBuilder: () => this.BuildTermItem(),
              onClickBtn: () => {
              }
            })
            CustomListItem({
              text: "开始时间",
              required: true,
              operateBuilder: () => this.BuildStartTimeItem(),
              onClickBtn: () => this.startTimeVisible = true
            })
            CustomListItem({
              text: "结束时间",
              required: true,
              operateBuilder: () => this.BuildEndTimeItem(),
              onClickBtn: () => this.endTimeVisible = true
            })
            CustomListItem({
              text: "加入方式(必填)",
              required: true,
              operateBuilder: () => this.BuilderJoinTypeItem(),
              onClickBtn: () => {
              }
            })
            CustomListItem({
              text: "身份限制(必填)",
              required: true,
              operateBuilder: () => this.BuilderIdentityFlagItem(),
              onClickBtn: () => {
              }
            })
            CustomListItem({
              text: "公开范围(必填)",
              required: true,
              operateBuilder: () => this.BuilderPublicTypeItem(),
              onClickBtn: () => {
              }
            })
            CustomListItem({
              text: "锁定状态",
              operateBuilder: () => this.BuilderLockItem(),
              onClickBtn: () => {
              }
            })
          }
        }
        .flexGrow(1)

        Button('确定', { type: ButtonType.Normal })
          .flexShrink(0)
          .width('100%')
          .margin({ top: 12 })
          .borderRadius(0)
          .backgroundColor('#40A9FF')
          .enabled(!!_.trim(this.siteName))
          .onClick(async () => {
            if (!_.trim(this.siteName)) {
              CustomToast.toast_info('课程内容为空，无法创建课程')
              return
            }

            const desc = translateRichText(this.courseDesc)
            if (desc.length > 500) {
              CustomToast.toast_info('课程介绍不能超过500字')
              return
            }
            const response = await xyApiPost(this.Api_Context.getApiPrefix('baseApi_inner') + HomeApi.addGroup, {
              'siteName': this.siteName,
              'download': 2,
              'description': this.courseDesc,
              'lock': this.lock ? 2 : 1,
              'joinType': this.joinType,
              'publicType': this.publicType,
              'schoolId': this.schoolId,
              'termCode': this.termCode,
              'domainCode': this.domainCode,
              'reourceTree': 2,
              'statistics': 2,
              'identityFlag': this.identityFlag,
              'courseProperty': '1',
              'endTime': this.endTime.toISOString(),
              'startTime': this.startTime.toISOString(),
              'time_flag': this.param.timeFlag,
              'realname': this.userInfo.realname,
            },
            )
            if (response.success) {
              const group = response.data as Record<string, string | number>
              group.role = 3
              CustomAlertDialog({
                'title': '提示',
                'message': `课程《${group.name}》（课程号：${group.key}）已经创建成功，教师、助教可任意修改目录结构并选择目录上传课件进行备课、授课、布置作业、扫码添加成员等。是否进入课程？`,
                onCloseBtn: () => {
                  this.pageInfos.pop({ refresh: true })
                },
                onClickBtn: () => {
                  this.pageInfos.replacePath({ name: 'courseDetailPage', param: group })
                }
              } as AlertDialogParam)
            }
          })

        CustomDatePickerDialog({
          visible: $startTimeVisible,
          title: $startTimeTitle,
          onOkBtn: (value: Date) => {
            this.startTime = value
          }
        })

        CustomDatePickerDialog({
          visible: $endTimeVisible,
          title: $endTimeTitle,
          onOkBtn: (value: Date) => {
            this.endTime = value
          }
        })
      }
    }
    .title(CustomNavTitle('创建课程'))
    .backgroundColor("#f1f1f1")
  }
}

@Builder
export function CreateCourseBuilder() {
  CreateCourse()
}




