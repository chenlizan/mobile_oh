import { Api_Context } from "../config/Context";

@Component
export struct Avatar {
  @Prop avatarSize: number = 60;
  @Link avatar: string | null
  getAvatarSource = (avatar: string) => {
    let source: string | null = null
    if (avatar) {
      if (avatar.indexOf('cloud/file_access') !== -1) {
        if (avatar.indexOf('/cloud/file_access') === 0) {
          let icon_url =
            AppStorage.get<Api_Context>('Api_Context')?.getApiPrefix('baseApi_out') + avatar.slice(1);
          source = icon_url;
        } else if (avatar.indexOf('cloud/file_access') === 0) {
          let icon_url = AppStorage.get<Api_Context>('Api_Context')?.getApiPrefix('baseApi_out') + avatar;
          source = icon_url;
        }
      } else {
        source = avatar;
      }
    }
    return source;
  }

  build() {
    Row() {
      if (this.avatar) {
        Image(this.getAvatarSource(this.avatar))
          .borderRadius(this.avatarSize / 2)
      } else {
        Image($r('app.media.default'))
          .borderRadius(this.avatarSize / 2)
      }
    }
    .width(this.avatarSize)
    .height(this.avatarSize)
    .borderRadius(this.avatarSize / 2)
    .borderWidth(1)
    .borderColor(Color.White)
  }
}