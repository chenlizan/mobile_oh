import { CustomNavTitle } from "@xy/basic"

@Component
struct JoinCourse {
  build() {
    NavDestination() {

    }
    .title(CustomNavTitle('加入课程'))
    .backgroundColor("#f1f1f1")
  }
}

@Builder
export function JoinCourseBuilder() {
  JoinCourse()
}
