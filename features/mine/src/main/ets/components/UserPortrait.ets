import { TextModifier } from "@kit.ArkUI"
import _ from "@wolfx/lodash"
import dayjs from "dayjs"
import { Api_Context, ccApiGet, HomeApi, MineApi, UserInfoModel, xyApiGet } from "@xy/basic"

interface PORTRAIT {
  title?: string
  desc?: string
  used?: number
  usedPercent?: number
  total?: number
  isDisk?: boolean
  subTitle?: string
  count?: number
  courseConfig?: number
}

@Component
struct UserPortrait {
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @StorageLink('UserInfo') userInfo: UserInfoModel = new UserInfoModel()
  @State isRefreshing: boolean = false
  @State resources: Array<never> = []
  @State resourceTotal: number = 0
  @State portrait: PORTRAIT[] = []

  aboutToAppear(): void {
    this.getStaticsData()
  }

  async getStaticsData() {
    this.portrait.length = 0
    let response = await xyApiGet(this.Api_Context.getApiPrefix('statApi') + MineApi.groupResourcePersonal)
    if (response.success) {
      this.resources = response.data as Array<never>
      this.resourceTotal = _.sumBy(response.data as Array<never>, 'count')
    }

    response = await xyApiGet(this.Api_Context.getApiPrefix('statApi') + MineApi.groupResourcePersonalFilesize)
    if (response.success) {
      const resourceSpace: Record<string, string> = response.data as Record<string, string>
      const allSpace = _.floor(
        ((this.userInfo.fileCapacity as Record<string, string>)?.totalFileSize as never ?? 0) / 1024,
        2,
      )
      const allMedia = _.floor(
        ((this.userInfo.fileCapacity as Record<string, string>)?.totalVideoFileSize as never ?? 0) / 1024,
        2,
      )
      const useSpace =
        Math.round((resourceSpace.ossfilesize as never ?? 0) / 1024 / 1024 / 1024) * 100 /
          100.0
      const useSpacePercent = _.floor((useSpace * 100) / allSpace, 2)
      const useMedia =
        Math.round(((resourceSpace.mediafilesize as never ?? 0) / 1024 / 1024 / 1024) *
          100) / 100.0
      const useMediaPercent = _.floor((useMedia * 100) / allMedia, 2)
      this.portrait.push({
        title: '文件上传',
        desc: '文件存储容量',
        used: useSpace,
        usedPercent: useSpacePercent,
        total: allSpace,
        isDisk: true,
      })
      this.portrait.push({
        title: '视频上传',
        desc: '视频存储容量',
        used: useMedia,
        usedPercent: useMediaPercent,
        total: allMedia,
        isDisk: true,
      })
    }

    response = await xyApiGet(this.Api_Context.getApiPrefix('statApi') + MineApi.groupPersonal)
    if (response.success) {
      const groupSpace: Record<string, string> = response.data as Record<string, string>
      let createdStartCount = 0
      _.map(groupSpace.created, (course: Record<string, string>) => {
        if (
          dayjs().isBefore(dayjs(course.end_time)) &&
          dayjs().isAfter(dayjs(course.start_time))
        ) {
          createdStartCount = createdStartCount + 1
        }
      })
      let joinedStartCount = 0
      _.map(groupSpace.joined, (course: Record<string, string>) => {
        if (
          dayjs().isBefore(dayjs(course.end_time)) &&
          dayjs().isAfter(dayjs(course.start_time))
        ) {
          joinedStartCount = joinedStartCount + 1
        }
      })
      this.portrait.push({
        title: '创建课程空间总数',
        total: groupSpace.created.length,
        subTitle: '进行中',
        count: createdStartCount,
        desc: `可开课数量限制为${(this.userInfo.fileCapacity as Record<string, string>)?.selfCreateSiteCount ?? 0}`,
      })
      this.portrait.push({
        title: '参与课程',
        total: groupSpace.joined.length,
        subTitle: '进行中',
        count: joinedStartCount,
        desc: '可参与课程不限',
      })
    }

    if (!this.userInfo.isRealStudent && !this.userInfo.isSchoolFellow) {

      response = await xyApiGet(this.Api_Context.getApiPrefix('baseApi_inner') + HomeApi.groupConfig)
      let courseConfig: Record<string, string | Record<string, number>> = {}
      if (response.success) {
        courseConfig = response.data as Record<string, string | Record<string, number>>
      }

      response =
        await xyApiGet(this.Api_Context.getApiPrefix('statApi') + MineApi.kgPersonal, { 'userId': this.userInfo.id })
      if (response.success) {
        const kgSpace: Record<string, string | number> = response.data as Record<string, string | number>
        if (kgSpace.isKgAvailable) {
          this.portrait.push({
            title: '创建图谱总数',
            total: (kgSpace.kgCount ?? 0) as number,
            subTitle: '图谱节点数',
            count: (kgSpace.verticesCount ?? 0) as number,
            desc: `可创建图谱数量限制为${(this.userInfo.fileCapacity as Record<string, string>)?.tpCount ?? 0}`,
          })
        }
      }

      response =
        await xyApiGet(this.Api_Context.getApiPrefix('statApi') + MineApi.evaluationPersonal)
      if (response.success) {
        const evaluationSpace: Record<string, number> = response.data as Record<string, number>
        this.portrait.push({
          title: '创建评价量规总数',
          total: (evaluationSpace.evaluationScaleSettingCount ?? 0) as number,
          subTitle: '评价条目数',
          count: (evaluationSpace.evaluationScaleItemsCount ?? 0) as number,
          desc: `可创建评价量规数量限制为${(courseConfig.evaluation_scale as Record<string, number>)?.setting_max_count ??
            0}`,
        })
      }

      response =
        await xyApiGet(this.Api_Context.getApiPrefix('statApi') + MineApi.qbPersonal)
      if (response.success) {
        const qbSpace: Record<string, number> = response.data as Record<string, number>
        this.portrait.push({
          title: '创建题库总数',
          total: qbSpace.questionBankCount ?? 0,
          subTitle: '题库内题目总数',
          count: qbSpace.questionsInBankCount ?? 0,
          desc: `可创建题库数量限制为${(courseConfig.evaluation_scale as Record<string, number>)?.max_store_count ??
            0}`,
        })
      }

      const responseCC = await ccApiGet(this.Api_Context.getApiPrefix('ccApi') + MineApi.thirdToolPersonal,
        { 'userId': this.userInfo.id })
      if (responseCC.code === 200) {
        const thirdToolSpace: Record<string, number> = responseCC.result as Record<string, number>
        this.portrait.push({
          title: '应用总数',
          total: thirdToolSpace.totalCount ?? 0,
          subTitle: '个人添加应用数量',
          count: thirdToolSpace.insertCount ?? 0,
          desc: `可创建应用数量限制为${thirdToolSpace.insertMaxCount ?? 0}`,
        })
      }

    }

    response = await xyApiGet(this.Api_Context.getApiPrefix('statApi') + MineApi.sharedPersonal)
    if (response.success) {
      const sharedSpace: Record<string, number> = response.data as Record<string, number>
      this.portrait.push({
        title: '已分享个数',
        total: sharedSpace.sharedResourceCount ?? 0,
        subTitle: '分享中',
        count: sharedSpace.sharingResourceCount ?? 0,
        desc: '可分享个数不限',
      })
    }

    response = await xyApiGet(this.Api_Context.getApiPrefix('statApi') + MineApi.collectionPersonal)
    if (response.success) {
      const collectionSpace: Record<string, number> = response.data as Record<string, number>
      this.portrait.push({
        title: '已收藏资源数',
        total: collectionSpace.collectionCount ?? 0,
        subTitle: '已过期',
        count: collectionSpace.collectionExpiredCount ?? 0,
        desc: '可收藏资源数量不限',
      })
    }
  }

  getResourceColorByType(type: string) {
    switch (type) {
      case 'PDF':
        return '#FF8B8B'
      case 'PPT':
        return '#FFDA8D'
      case 'Word':
        return '#1EB38F'
      case 'Excel':
        return '#FF7777'
      case '视频':
        return '#61BFAD'
      case '音频':
        return '#FF931E'
      case '图片':
        return '#FF4040'
      case '笔记':
        return '#6BE1E4'
      case '思维导图':
        return '#C9B7FC'
      case '讨论':
        return '#0ABCD6'
      case '作业/测练':
        return '#40A9FF'
      case '教学设计':
        return '#167C80'
      case '其他':
        return '#FCBB34'
      default:
        return '#FCBB34'
    }
  }

  @Builder
  BuildCourseItem(portrait: PORTRAIT) {
    Column() {
      Text(portrait.title)
        .fontSize(12)
      Row() {
        Text(String(portrait.total))
          .fontColor('#fcbb34')
        Column() {
          Text(portrait.subTitle)
            .fontSize(10)
            .fontColor('#d8999999')
            .margin({ left: 2, bottom: 2 })
          Text(String(portrait.count))
            .fontSize(13)
            .fontColor('#fcbb34')
        }
      }
      .width('100%')
      .padding({ top: 6, bottom: 6 })
      .justifyContent(FlexAlign.SpaceBetween)

      Divider()

      Text(`${portrait.desc}`)
        .padding({ top: 6 })
        .fontSize(10)
        .fontColor('#d8999999')
    }
    .padding(8)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(Color.White)
    .borderRadius(4)
  }

  @Builder
  BuildDiskItem(portrait: PORTRAIT) {
    Column() {
      Text(portrait.title)
        .fontSize(12)
      Row() {
        Text(String(portrait.used))
          .fontColor('#fcbb34')
          .textAlign(TextAlign.End)
        Text('G')
          .fontSize(10)
          .fontColor('#d8999999')
          .margin({ left: 2, bottom: 2 })
      }
      .padding({ top: 6, bottom: 6 })
      .alignItems(VerticalAlign.Bottom)

      Progress({ value: portrait.usedPercent, total: 100, type: ProgressType.Linear })
        .style({ strokeWidth: 8 })

      Text(`已使用${portrait.usedPercent}%${portrait.desc}${portrait.total ?? 0}G`)
        .padding({ top: 6 })
        .fontSize(10)
        .fontColor('#d8999999')
    }
    .padding(8)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(Color.White)
    .borderRadius(4)
  }

  build() {
    NavDestination() {
      Refresh({ refreshing: $$this.isRefreshing }) {
        Column() {
          Grid() {
            ForEach(this.portrait, (portrait: PORTRAIT) => {
              GridItem() {
                if (portrait.isDisk) {
                  this.BuildDiskItem(portrait)
                } else {
                  this.BuildCourseItem(portrait)
                }
              }
            })
          }
          .height(480)
          .columnsTemplate('1fr 1fr')
          .columnsGap(8)
          .rowsGap(8)

          Row() {
            Row() {
              Text('我的资源')
                .fontSize(16)
              Text('最大资源总量2000个')
                .fontSize(14)
                .fontColor('#d8999999')
                .padding({ left: 4 })
            }

            Row() {
              Text('资源总数')
                .padding({ right: 4 })
                .fontSize(14)
                .fontColor('#d8999999')
              Text(`${this.resourceTotal}`)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
            }
          }
          .width('100%')
          .padding({
            top: 6,
            bottom: 8,
            left: 8,
            right: 8
          })
          .justifyContent(FlexAlign.SpaceBetween)

          List({ space: 10 }) {
            ForEach(this.resources, (resource: Record<string, string>) => {
              if (String(resource.count) !== '0') {
                ListItem() {
                  Column() {
                    Text(resource.resource_type)
                      .fontSize(14)
                      .fontColor(Color.White)
                      .fontWeight(FontWeight.Bold)
                    Text(String(resource.count))
                      .fontSize(30)
                      .fontColor(Color.White)
                      .fontWeight(FontWeight.Bold)
                    Text(this.resourceTotal ? `${_.floor((parseInt(resource.count) * 100) / this.resourceTotal, 1)}%` :
                      '0')
                      .fontSize(14)
                      .fontColor(Color.White)
                  }
                  .justifyContent(FlexAlign.SpaceEvenly)
                  .width(85)
                  .height(110)
                  .borderRadius(4)
                  .backgroundColor(this.getResourceColorByType(resource.resource_type))
                }
              }
            })
          }
          .listDirection(Axis.Horizontal)
        }
        .width('100%')
        .height('100%')
        .padding(16)
        .backgroundColor('#f1f1f1')
      }
      .onRefreshing(() => {
        this.getStaticsData()
        setTimeout(() => {
          this.isRefreshing = false
        }, 500)
      })
    }
    .title('个人数据看板', {
      mainTitleModifier: new TextModifier().fontColor('#404040').fontSize(16).fontWeight(FontWeight.Normal)
    })
    .backgroundColor("#f1f1f1")
  }
}

@Builder
export function UserPortraitBuilder() {
  UserPortrait()
}