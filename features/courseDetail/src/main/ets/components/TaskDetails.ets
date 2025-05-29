import { display } from '@kit.ArkUI'
import _ from '@wolfx/lodash'
import dayjs from 'dayjs'
import { Api_Context, AppIcon, CustomNavTitle, HomeApi, IconConstants, PreferenceStorage, xyApiGet } from '@xy/basic'

@Component
struct TaskDetails {
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  @StorageLink('PreferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage()
  @State screenWidth: number = 0
  @State isRefreshing: boolean = false
  @State classList: Record<string, string>[] = []
  @State classMember: Record<string, string | number>[] = []
  @State taskDetail: Record<string, string | number | Array<Record<string, string>>> = {}
  @State subgroupSchema: Record<string, string>[] = []
  @State subgroupList: Record<string, string | Record<string, string>[]>[] = []
  @State dataSource: Record<string, string | number | null | Record<string, string | number>[]>[] = []
  @State selectClassId: string = ''
  @State searchText: string = ''
  @State filterType: number = 0
  private courseInfo = this.preferenceStorage.currentTeam ?? {}
  private param: Record<string, string | boolean | number | Record<string, boolean>> = {}

  async groupClassList(): Promise<boolean> {
    const response =
      await xyApiGet(this.Api_Context.getApiPrefix('baseApi_inner') + HomeApi.groupClassList + '/' + this.courseInfo.id)
    if (response.success) {
      this.classList = response.data as Record<string, string>[]
      return true
    } else {
      return false
    }
  }

  async queryMembers() {
    const response = await xyApiGet(this.Api_Context.getApiPrefix('baseApi_inner') + HomeApi.queryMembers, {
      'group_id': this.courseInfo.id,
      'random': new Date().getTime(),
    })
    if (response.success) {
      this.classMember = response.data as Record<string, string>[]
      return true
    } else {
      return false
    }
  }

  async querySubgroupSchema() {
    const response = await xyApiGet(this.Api_Context.getApiPrefix('baseApi_inner') + HomeApi.querySubgroupSchema, {
      'group_id': this.courseInfo.id,
    })
    if (response.success) {
      const subGroups = _.filter(response.data ?? [],
        (item: Record<string, boolean | number>) => (item?.is_joined && item?.is_student) as boolean ||
          !item?.is_student || item?.type === 3)
      this.subgroupSchema = _.orderBy(subGroups, ['created_at'], ['desc'])
      return true
    } else {
      return false
    }
  }

  async querySubgroupGroup() {
    const promises = _.map(this.subgroupSchema, async (item) => {
      const schema_id = item.id;
      const response = await xyApiGet(
        this.Api_Context.getApiPrefix('baseApi_inner') + HomeApi.querySubgroupGroup,
        {
          'subgroup_schemas_id': schema_id,
        }
      );
      if (response.success) {
        this.subgroupList.push({
          'id': schema_id,
          'data': response.data as Record<string, string>[],
        });
        return true;
      } else {
        return false;
      }
    });
    return await Promise.all(promises);
  }

  async queryTaskDetails() {
    const response = await xyApiGet(this.Api_Context.getApiPrefix('statApi') + HomeApi.queryTaskDetails, {
      'group_id': this.param.group_id,
      'task_id': this.param.task_id,
      'role': this.courseInfo?.role ?? 1,
    })
    if (response.success) {
      this.taskDetail = response.data as Record<string, string | number | Array<Record<string, string>>>
      const members = this.classMember.filter(member => {
        return member.role === 1
      })
      const students = _.map(members, s => ({
        'id': s.user_id,
        'name': s.nickname,
        'class_id': s.class_id,
      } as Record<string, string | number | null>))
      const creator = _.find(this.classMember, { user_id: this.taskDetail.creator_id }) as Record<string, string>
      this.taskDetail.creator_name = creator.nickname
      if (this.taskDetail.assign_to_type === 2) {
        if (this.taskDetail.finish_type === 1) {
          _.forEach(this.taskDetail.detail_tasks as Record<string, string | string[] | Record<string, string>[] | Record<string, Record<string, string>[]>>[],
            task => {
              const extra = task.extra as Record<string, Record<string, string>[]>
              const subgroup_members = task.subgroup_members as string[]
              const assign_to_id = task.assign_to_id
              const finish_count = Number(task.finish_count)
              const total_count = Number(task.total_count)
              const finish = finish_count >= total_count && total_count > 0
              const finish_info = extra.finish_info
              let members: Record<string, string | number | null>[] = []
              _.forEach(subgroup_members, user_id => {
                const user = _.find(students, { id: user_id }) as Record<string, string | number | null>
                if (user) {
                  const class_info = _.find(this.classList, { class_id: user.class_id }) as Record<string, string>
                  if (!_.isEmpty(finish_info)) {
                    const record = _.find(finish_info, { user_id: user_id }) as Record<string, string>
                    user.class_name = class_info?.class_name ?? ''
                    user.finish = record ? 2 : 1
                    user.finish_time = record ? record.finish_time : null
                    user.watched_duration = this.getVideoTaskWatchedDuration(this.taskDetail, user_id)
                    members.push(user)
                  } else {
                    user.class_name = class_info?.class_name ?? ''
                    user.finish = 1
                    user.finish_time = null
                    user.watched_duration = this.getVideoTaskWatchedDuration(this.taskDetail, user_id)
                    members.push(user)
                  }
                }
              })
              members = _.orderBy(members, ['finish_time'], ['desc'])
              _.filter(this.subgroupSchema, subgroup => {
                const subgroups = _.find(this.subgroupList, { id: subgroup.id })
                const data = _.orderBy(subgroups?.data as Record<string, string>[], ['group_number'])
                _.filter(data, group => {
                  if (group.id === assign_to_id) {
                    this.dataSource.push({
                      'id': task.assign_to_id,
                      'name': subgroup.title + '/' + group.group_name,
                      'finish': finish ? 2 : 1,
                      'finish_time': finish ? members[0].finish_time : null,
                      'members': members,
                    } as Record<string, Record<string, string | number>[] | string | number | null>)
                  }
                })
              })
            })
        } else if (this.taskDetail.finish_type === 2) {
          _.filter(this.subgroupSchema, subgroup => {
            const subgroups = _.find(this.subgroupList, { id: subgroup.id });
            const data = _.orderBy(subgroups?.data as Record<string, string>[], ['group_number'])
            _.filter(data, group => {
              const task =
                _.find(this.taskDetail.detail_tasks as Array<Record<string, string | Record<string, string | Record<string, string>[]>>>,
                  { assign_to_id: group.id });
              if (task) {
                const extra = task.extra as Record<string, Record<string, string>[]>
                const finish_count = Number(task.finish_count)
                const total_count = Number(task.total_count)
                const finish_info = extra.finish_info
                const finish = finish_count >= total_count && total_count > 0;
                const finish_time =
                  finish && !_.isEmpty(finish_info)
                    ? _.orderBy(finish_info, ['finish_time'], ['desc'])[0]
                    .finish_time
                    : null;
                this.dataSource.push({
                  'id': task.assign_to_id,
                  'name': subgroup.title + '/' + group.group_name,
                  'finish': finish ? 2 : 1,
                  'finish_time': finish_time,
                  'watched_duration': this.taskDetail.node_type === 9 ? task?.total_watched_time?.toString() : null,
                } as Record<string, Record<string, string | number>[] | string | number | null>);
              }
            });
          });
        }
      } else if (this.taskDetail.assign_to_type === 3) {
        const detail_task =
          (this.taskDetail.detail_tasks as Array<Record<string, string | Record<string, string | Record<string, string>[]>>>)[0]
        const extra = detail_task.extra as Record<string, Record<string, string>[]>
        const finish_info = extra.finish_info
        if (!_.isEmpty(finish_info)) {
          this.dataSource = _.map(students, s => {
            const user = _.find(finish_info, { user_id: s.id }) as Record<string, string>
            const class_info = _.find(this.classList, { class_id: s.class_id }) as Record<string, string>
            s.class_name = class_info.class_name ?? ''
            s.finish = user ? 2 : 1
            s.finish_time = user ? user.finish_time : null
            s.watched_duration = this.getVideoTaskWatchedDuration(this.taskDetail, s.id as string)
            return s
          })
        } else {
          this.dataSource = _.map(students, s => {
            const class_info = _.find(this.classList, { class_id: s.class_id }) as Record<string, string>
            s.class_name = class_info?.class_name ?? ''
            s.finish = 1
            s.finish_time = null
            s.watched_duration = this.getVideoTaskWatchedDuration(this.taskDetail, s.id as string)
            return s
          })
        }
      }
    }
  }

  getVideoTaskWatchedDuration(item: Record<string, string | number | Record<string, string>[]>, user_id: string) {
    if (item.type === 9) {
      const record = _.find(item.watched_record as Record<string, string>[], { user_id: user_id })
      return record?.watched_duration?.toString() ?? '0'
    }
    return null
  }

  getDataSourceByFilter(searchText: string, filterType: number, dataSource: Record<string, string>[]) {
    let rows = dataSource
    if (filterType !== 0) {
      rows = rows.filter(task => Number(task.finish) === filterType)
    }
    if (_.trim(searchText)) {
      rows = rows.filter(task => task.name?.indexOf(searchText) > -1)
    }
    return rows
  }

  async aboutToAppear(): Promise<void> {
    this.screenWidth = px2vp(display.getDefaultDisplaySync().width)
    this.param = JSON.parse(String(this.pageInfos.getParamByName('taskDetails')[0]))
    await Promise.all([this.groupClassList(), this.queryMembers(), this.querySubgroupSchema()])
    await this.querySubgroupGroup()
    await this.queryTaskDetails()
  }

  build() {
    NavDestination() {
      Refresh({ refreshing: $$this.isRefreshing }) {
        Flex({ direction: FlexDirection.Column }) {
          if (this.taskDetail.assign_to_type !== 2) {
            Select([{ value: '全部班级' } as SelectOption].concat(this.classList.map((item) => {
              return { 'value': item.class_name } as SelectOption
            })))
              .selected(0)
              .margin({ bottom: 12 })
              .fontColor('#999999')
              .font({ size: 15 })
              .value('全部班级')
              .width('100%')
              .backgroundColor(Color.White)
              .borderRadius(4)
              .onSelect((index: number) => {
                if (index > 0) {
                  this.selectClassId = this.classList[index-1].class_id
                } else {
                  this.selectClassId = ''
                }
              })
          }
          Column() {
            Row() {
              Text(`${this.taskDetail.node_type === 7 ? '答题' :
                ''}起止时间：${dayjs(this.taskDetail.start_time as string).format('YYYY/MM/DD HH:mm') + '-' +
              dayjs(this.taskDetail.end_time as string).format('YYYY/MM/DD HH:mm')}`)
                .fontColor('#999999')
                .fontSize(14)
            }
            .width('100%')

            Row() {
              Text(`发布者：${this.taskDetail.creator_name ?? ''}`)
                .fontColor('#999999')
                .fontSize(14)
              Text(`完成数量： ${this.dataSource.filter(task => task.finish === 2).length}/${this.dataSource.length}`)
                .fontColor('#999999')
                .fontSize(14)
            }
            .justifyContent(FlexAlign.SpaceBetween)
            .width('100%')
            .margin({ top: 10 })
          }
          .margin({ bottom: 12 })
          .padding(12)
          .backgroundColor(Color.White)
          .borderRadius(4)

          Row() {
            Column() {
              Text(String(_.filter(this.dataSource,
                i => this.selectClassId === '' || i.class_id === this.selectClassId).length))
                .margin({ bottom: 4 })
                .fontColor('#1EB38F')
                .fontSize(17)
              Text('全部')
                .fontColor('#999999')
                .fontSize(12)
            }

            Column() {
              Text(String(_.filter(this.dataSource,
                i => this.selectClassId === '' || i.class_id === this.selectClassId)
                .filter((task) => task.finish === 2)
                .length))
                .margin({ bottom: 4 })
                .fontColor('#40A9FF')
                .fontSize(17)
              Text('已完成')
                .fontColor('#999999')
                .fontSize(12)
            }

            Column() {
              Text(String(_.filter(this.dataSource,
                i => this.selectClassId === '' || i.class_id === this.selectClassId)
                .filter((task) => task.finish === 1)
                .length))
                .margin({ bottom: 4 })
                .fontColor('#FF4040')
                .fontSize(17)
              Text('未完成')
                .fontColor('#999999')
                .fontSize(12)
            }
          }
          .justifyContent(FlexAlign.SpaceAround)
          .width('100%')
          .padding(12)
          .backgroundColor(Color.White)
          .borderRadius(4)

          Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
            Search({ placeholder: '请输入要搜索的关键字' })
              .placeholderColor('#999999')
              .placeholderFont({ size: 14 })
              .width((this.screenWidth - 36) / 2)
              .borderRadius(4)
              .onChange((value: string) => {
                this.searchText = value
              })
            Select([
              { value: '全部' },
              { value: '未完成' },
              { value: '已完成' }])
              .font({ size: 14 })
              .fontColor('#999999')
              .selected(0)
              .value('全部')
              .width((this.screenWidth - 36) / 2)
              .borderRadius(4)
              .onSelect((index: number) => {
                this.filterType = index
              })
          }
          .flexShrink(0)

          List() {
            ForEach(this.getDataSourceByFilter(this.searchText, this.filterType,
              _.filter(this.dataSource,
                i => this.selectClassId === '' || i.class_id === this.selectClassId) as Record<string, string>[]),
              (item: Record<string, string | number>) => {
                ListItem() {
                  Column() {
                    Row() {
                      Text(item.class_name as string)
                        .fontColor('#40A9FF')
                        .fontSize(14)
                    }
                    .width('100%')
                    .margin({ bottom: 10 })
                    .visibility(item.class_name ? Visibility.Visible : Visibility.None)

                    Row() {
                      Text(item.name as string)
                        .fontColor('#999999')
                        .fontSize(14)
                      Row() {
                        Text(item.finish === 2 ? '已完成' : '未完成')
                          .fontColor(item.finish === 2 ? '#40A9FF' : '#FF4040')
                          .fontSize(13)
                        if (!_.isEmpty(item?.members ?? [])) {
                          AppIcon({
                            iconCode: IconConstants.RIGHT
                          })
                        }
                      }
                    }
                    .justifyContent(FlexAlign.SpaceBetween)
                    .width('100%')
                    .onClick(() => {
                      if (!_.isEmpty(item?.members ?? [])) {
                        this.pageInfos.pushPath({ name: 'taskArchiveDetails', param: JSON.stringify(item) })
                      }
                    })

                    Row() {
                      Text(`观看时长: ${parseFloat(item.watched_duration as string).toFixed(2,)}s`)
                        .fontColor('#999999')
                        .fontSize(14)
                        .visibility(item.watched_duration ? Visibility.Visible :
                          item.finish_time ? Visibility.Hidden : Visibility.None)
                      Text(dayjs(item.finish_time).format('YYYY-MM-DD HH:mm:ss'))
                        .fontColor('#999999')
                        .fontSize(14)
                        .visibility(item.finish_time ? Visibility.Visible : Visibility.None)
                    }
                    .justifyContent(FlexAlign.SpaceBetween)
                    .width('100%')
                    .margin({ top: 10 })
                    .visibility((item.finish_time && item.watched_duration) ? Visibility.Visible : Visibility.None)
                  }
                  .padding(12)
                }
              })
          }
          .divider({
            color: '#d9d9d9',
            strokeWidth: 1.1,
            startMargin: 8,
            endMargin: 8
          })
          .flexGrow(1)
          .backgroundColor(Color.White)
          .borderRadius(4)
        }
        .margin(12)
      }
      .onRefreshing(async () => {
        await Promise.all([this.groupClassList(), this.queryMembers(), this.querySubgroupSchema()])
        await this.querySubgroupGroup()
        await this.queryTaskDetails()
        setTimeout(() => {
          this.isRefreshing = false
        }, 500)
      })
    }
    .title(CustomNavTitle(`任务完成详情`))
    .backgroundColor('#f1f1f1')
  }
}

@Builder
export function TaskDetailsBuilder() {
  TaskDetails()
}