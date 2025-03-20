import { CustomModalDialog, ObjectUtil } from "@xy/basic";

@Component
export struct LoginRemindModal {
  @Link visible: boolean
  @Link login_info: ObjectUtil<never>
  @State title: string = '账号安全提示'
  onActive: () => void = () => {
  }
  onLogin: () => void = () => {
  }
  onDeal: () => void = () => {
  }

  getQuestionText() {
    const data = this.login_info
    let remind: Array<string> = []
    if (!data.getValue('phoneStatus')) {
      remind.push('账号未绑定手机号');
    }
    if (data.getValue('isUnSafePassword')) {
      remind.push('账号的密码安全性较低');
      if (data.getValue('over90DaysNoLogin')) {
        remind.push('账号超过90天未登录');
      }
    }
    if (data.getValue('passwordExpiredStatus')) {
      remind.push('账号的密码超过90天未更换');
    }
    return remind;
  };

  @Builder
  BuildRemindText(data: ObjectUtil<never>, phoneRemind: string, bufferCount: number, activeText: string) {
    Column() {
      if (data.getValue('isUnSafePassword') && data.getValue('isUseBuffer')) {
        if ((data.getValue('totalBufferCount') - data.getValue('useBufferCount')) > 0) {
          Text(`注意：${phoneRemind}当前密码为弱密码，以弱密码登录次数剩余${bufferCount}次。用尽后，系统将强制修改密码。为保障账号安全，请${activeText}修改本系统密码（注意：不是修改学校统一身份认证的密码）。`)
            .fontSize(13)
            .fontColor('#FF4040')
        } else {
          Text(`注意：${phoneRemind}当前密码为弱密码，以弱密码登录次数剩余0次。为保障账号安全，请${activeText}修改本系统密码（注意：不是修改学校统一身份认证的密码）。`)
            .fontSize(13)
            .fontColor('#FF4040')
        }
      } else if (data.getValue('isUnSafePassword')) {
        Text(`注意：${phoneRemind}为保障账号安全，请${activeText}修改本系统密码（注意：不是修改学校统一身份认证的密码）。`)
          .fontSize(13)
          .fontColor('#FF4040')
      } else if (!data.getValue('isUnSafePassword')) {
        if (!data.getValue('phoneStatus') && !data.getValue('passwordExpiredStatus')) {
          Text(`注意：${phoneRemind}`)
            .fontSize(13)
            .fontColor('#FF4040')
        } else if (data.getValue('passwordExpiredStatus')) {
          Text(`注意：${phoneRemind}为保障账号安全，请${activeText}修改本系统密码（注意：不是修改学校统一身份认证的密码）。`)
            .fontSize(13)
            .fontColor('#FF4040')
        }
      } else {
        Text(null)
      }
    }
  }

  @Builder
  BuildModalContent(login_info: ObjectUtil<never>) {
    Column() {
      Text('检测到当前登录账号存在以下安全问题:')
        .fontSize(14)
      Column() {
        ForEach(this.getQuestionText(), (item: string) => {
          Text(item)
            .fontSize(14)
            .fontColor('#999999')
        })
      }
      .margin({ top: 12, bottom: 12 })

      this.BuildRemindText(login_info,
        login_info.getValue('phoneStatus') ? '为了通过手机号找回密码，请及时绑定手机号。' : '',
        login_info.getValue('totalBufferCount') - login_info.getValue('useBufferCount'),
        login_info.getValue('needActive') ? '立即' : '及时')
    }
    .width('100%')
    .padding(16)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  BuildModalFooter(login_info: ObjectUtil<never>) {
    Row() {
      if (login_info.getValue('needActive')) {
        Button('修改密码', { type: ButtonType.Normal })
          .height(40)
          .margin({ right: 8 })
          .borderRadius(4)
          .onClick(() => {
            this.onActive()
          })
      } else {
        Button('继续登录', { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.NORMAL })
          .height(40)
          .margin({ right: 8 })
          .backgroundColor(Color.White)
          .border({ width: 1, color: '#999999' })
          .borderRadius(4)
          .fontColor('#999999')
          .onClick(() => {
            this.onLogin()
          })

        Button('去处理', { type: ButtonType.Normal })
          .height(40)
          .margin({ right: 8 })
          .borderRadius(4)
          .onClick(() => {
            this.onDeal()
          })
      }
    }
    .width('100%')
    .margin({ bottom: 8 })
    .justifyContent(FlexAlign.End)
  }

  build() {
    CustomModalDialog({
      dialogHeight: 300,
      visible: $visible,
      title: this.title,
      contentBuilder: () => this.BuildModalContent(this.login_info),
      footerBuilder: () => this.BuildModalFooter(this.login_info),
    })
  }
}