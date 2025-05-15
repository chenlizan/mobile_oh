import { CustomNavTitle } from '@xy/basic'

@Component
struct TaskDetails {
  build() {
    NavDestination() {
      Text('未施工')
    }
    .title(CustomNavTitle('任务完成详情'))
    .backgroundColor('#f1f1f1')
  }
}

@Builder
export function TaskDetailsBuilder() {
  TaskDetails()
}