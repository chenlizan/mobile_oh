import { Api_Context } from "../config/Context";

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

export const getAvatarSource = (avatar: string) => {
  let source: Record<string, string | number> = {};
  if (avatar) {
    if (avatar.indexOf('cloud/file_access') !== -1) {
      if (avatar.indexOf('/cloud/file_access') === 0) {
        let icon_url =
          AppStorage.get<Api_Context>('Api_Context')?.getApiPrefix('baseApi_out') + avatar.slice(1);
        source = {"uri": icon_url};
      } else if (avatar.indexOf('cloud/file_access') === 0) {
        let icon_url = AppStorage.get<Api_Context>('Api_Context')?.getApiPrefix('baseApi_out') + avatar;
        source = {"uri": icon_url};
      }
    } else {
      source = {"uri": avatar};
    }
  }
  return source;
};