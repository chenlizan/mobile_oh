import { Api_Context, CCApi, ccApiGet, ccApiPost, CustomModalDialog, ObjectUtil, PreferenceStorage } from "@xy/basic";

@Component
export struct LoginRemindModal {
  @Link visible: boolean
  @Link login_info: ObjectUtil<never>
  @StorageLink('PreferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage()
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context(this.preferenceStorage?.school?.domain)
  @State title: string = '账号安全提示'
  @State unRemind: boolean = false
  onActive: () => void = () => {
  }
  onLogin: () => void = () => {
  }
  onDeal: () => void = () => {
  }

  _onLogin() {
    this.noNoticed90Days();
    this.onLogin();
  }

  _onDeal() {
    this.noNoticed90Days();
    this.onDeal();
  }

  async noNoticed90Days() {
    let onlyExpired = this.judgeOnlyExpired(this.getQuestionText())
    if (onlyExpired && this.unRemind) {
      // 不再提示
      const data = this.login_info
      const access_token = data.getValue('access_token');
      const response = await ccApiGet(this.Api_Context.getApiPrefix('ccApi') + CCApi.noNoticed90Days, {},
        { "Authorization": 'Bearer ' + access_token })
      if (response.code === 200) {
        console.log('设置成功')
      }
    }
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

  judgeOnlyExpired = (questions: Array<string>) => {
    return (
      questions.length === 1 && questions[0] === '账号的密码超过90天未更换'
    );
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
        login_info.getValue('phoneStatus') ? '' : '为了通过手机号找回密码，请及时绑定手机号。',
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
          .backgroundColor(0x40A9FF)
          .onClick(() => {
            this.onActive()
          })
      } else {
        if (this.judgeOnlyExpired(this.getQuestionText())) {
          Row() {
            Checkbox()
              .select(this.unRemind)
              .selectedColor(0x40A9FF)
              .shape(CheckBoxShape.ROUNDED_SQUARE)
              .onChange((value: boolean) => {
                this.unRemind = value
              })
            Text('不再提示')
              .margin({ left: 2 })
              .fontSize(14)
              .fontColor('#999999')
          }
        } else {
          Row()
        }

        Row() {
          Button('继续登录', { type: ButtonType.Normal, buttonStyle: ButtonStyleMode.NORMAL })
            .height(40)
            .margin({ right: 8 })
            .backgroundColor(Color.White)
            .border({ width: 1, color: '#999999' })
            .borderRadius(4)
            .fontColor('#999999')
            .onClick(() => {
              this._onLogin()
            })

          Button('去处理', { type: ButtonType.Normal })
            .height(40)
            .margin({ right: 8 })
            .borderRadius(4)
            .backgroundColor(0x40A9FF)
            .onClick(() => {
              this._onDeal()
            })
        }
      }
    }
    .width('100%')
    .margin({ bottom: 8 })
    .justifyContent(login_info.getValue('needActive') ? FlexAlign.End : FlexAlign.SpaceBetween)
  }

  build() {
    CustomModalDialog({
      visible: $visible,
      title: this.title,
      contentBuilder: () => this.BuildModalContent(this.login_info),
      footerBuilder: () => this.BuildModalFooter(this.login_info),
    })
  }
}