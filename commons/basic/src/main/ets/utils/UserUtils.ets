export const getMemberRole = (role: number) => {
  switch (role) {
    case 1:
      return '学生';
    case 2:
      return '助教';
    case 3:
      return '主讲教师';
    case 4:
      return '教师';
    case 5:
      return '督导';
    case 6:
      return '平台管理员';
    case 7:
      return '访客';
    case 8:
      return '评审员';
    default:
      return '';
  }
};