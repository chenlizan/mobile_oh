import _ from '@wolfx/lodash'
import { uniformTypeDescriptor } from '@kit.ArkData'
import { display } from '@kit.ArkUI'
import { fileIo, picker } from '@kit.CoreFileKit'
import axios, { AxiosError, AxiosProgressEvent, AxiosResponse, FormData } from '@ohos/axios'
import { Api_Context, AppIcon, CCApi, ccApiPost,
  CustomNavTitle,
  CustomToast, IconConstants, PreferenceStorage, } from '@xy/basic'

@Component
struct UserReflect {
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @StorageLink('PreferenceStorage') preferenceStorage: PreferenceStorage = new PreferenceStorage();
  @StorageLink('pageInfos') pageInfos: NavPathStack = new NavPathStack();
  @State screenWidth: number = 0
  @State title: string = ''
  @State content: string = ''
  @State phone: string = ''
  @State attachmentId: string = ''

  aboutToAppear(): void {
    this.screenWidth = px2vp(display.getDefaultDisplaySync().width)
  }

  async handleUpload() {
    if (this.attachmentId !== '') {
      this.attachmentId = ''
      return
    }

    const documentSelectOptions = new picker.DocumentSelectOptions();
    const documentViewPicker = new picker.DocumentViewPicker();
    const documentSelectResult = await documentViewPicker.select(documentSelectOptions)

    if (documentSelectResult.length >= 1) {
      const uri = documentSelectResult[0];
      const file = fileIo.openSync(uri)
      const stat = fileIo.statSync(file.fd)
      const fileName = file.name
      const fileExtention = file.name.split('.').pop()
      const typeId = uniformTypeDescriptor.getUniformDataTypeByFilenameExtension(`.${fileExtention}`)
      const typeObj = uniformTypeDescriptor.getTypeDescriptor(typeId)
      const mimeTypes = typeObj.mimeTypes[0]
      const fileBuffer = new ArrayBuffer(stat.size)
      fileIo.readSync(file.fd, fileBuffer)
      fileIo.closeSync(file.fd)

      const isLt200M = stat.size / 1024 / 1024 < 200
      if (!isLt200M) {
        CustomToast.toast_fail('可上传一个任意格式的附件，最大支持200M')
        return;
      }

      if (mimeTypes.indexOf('video/') !== -1) {
        CustomToast.toast_info('暂不支持视频上传')
        return
      }

      CustomToast.toast_loading('正在上传文件...')

      let response =
        await ccApiPost(this.Api_Context.getApiPrefix('ccApi') + CCApi.generateSignUpload, { 'suffix': fileExtention })
      if (response.code !== 200) {
        CustomToast.hide()
        CustomToast.toast_fail('上传失败')
        return;
      }
      const ossData: Record<string, string> = response.result as Record<string, string>

      response = await ccApiPost(this.Api_Context.getApiPrefix('ccApi') + CCApi.oss, {
        'bizType': '1',
        'fileFormat': fileExtention,
        'fileSize': stat.size,
        'path': fileName,
        'filename': fileName,
        'ismedia': 0,
        'mimetype': mimeTypes,
        'storePosition': 'ali-oss',
        'ossBucketName': ossData.bucketName,
        'ossEndpoint': ossData.host,
        'ossUrl': `${ossData.dir}/${ossData.fileName}`,
      })
      if (response.code !== 200) {
        CustomToast.hide()
        CustomToast.toast_fail('上传失败')
        return;
      }

      const formData = new FormData()
      formData.append('key', `${ossData.dir}/${ossData.fileName}`)
      formData.append('OSSAccessKeyId', ossData.accessid)
      formData.append('policy', ossData.policy)
      formData.append('signature', ossData.signature)
      formData.append('success_action_status', '200')
      formData.append('file', fileBuffer)

      axios.post<string, AxiosResponse<string>, FormData>(ossData.host, formData, {
        headers: { 'Content-Type': 'multipart/form-data' },
        context: getContext(this),
        onUploadProgress: (progressEvent: AxiosProgressEvent): void => {
          console.info(progressEvent && progressEvent.loaded && progressEvent.total ?
            Math.ceil(progressEvent.loaded / progressEvent.total * 100) + '%' : '0%');
        },
      }).then((res: AxiosResponse<string>) => {
        CustomToast.hide()
        CustomToast.toast_success('上传成功!')
        this.attachmentId = response.result as string
        console.info("result" + JSON.stringify(res.data));
      }).catch((err: AxiosError) => {
        CustomToast.hide()
        CustomToast.toast_fail('上传失败')
        console.error("error:" + JSON.stringify(err));
      })
    }
  }

  async handleSubmitReflect() {
    if (!_.trim(this.title)) {
      CustomToast.toast_fail('标题不能为空');
      return;
    }
    if (!_.trim(this.content)) {
      CustomToast.toast_fail('问题说明不能为空');
      return;
    }

    const response = await ccApiPost(this.Api_Context.getApiPrefix('ccApi') + CCApi.sysFeedback,
      {
        'title': this.title,
        'content': this.content,
        'phone': this.phone,
        'attachmentId': this.attachmentId
      },
      {
        'schoolId': this.preferenceStorage.school?.id,
      }
    )
    if (response.code === 200) {
      CustomToast.toast_success('反馈成功!')
      this.pageInfos.pop()
    }
  }

  build() {
    NavDestination() {
      Column() {
        Row() {
          Text("*")
            .fontColor(Color.Red)
          Text('标题')
        }
        .margin(12)

        Row() {
          TextArea({ text: this.title, placeholder: '请输入标题' })
            .width(this.screenWidth - 24)
            .height(50)
            .margin(12)
            .backgroundColor(Color.White)
            .borderRadius(4)
            .borderWidth(1)
            .borderColor('#d9d9d9')
            .onChange((value: string) => {
              this.title = value
            })
        }
        .backgroundColor(Color.White)

        Row() {
          Text("*")
            .fontColor(Color.Red)
          Text('问题说明')
        }
        .margin(12)

        Row() {
          TextArea({ text: this.content, placeholder: '请输入详细的问题描述，最多500字' })
            .width(this.screenWidth - 24)
            .height(80)
            .margin(12)
            .backgroundColor(Color.White)
            .borderRadius(4)
            .borderWidth(1)
            .borderColor('#d9d9d9')
            .maxLength(500)
            .showCounter(true)
            .onChange((value: string) => {
              this.content = value
            })
        }
        .backgroundColor(Color.White)

        Row() {
          Text('联系方式')
        }
        .margin(12)

        Row() {
          TextArea({ text: this.phone, placeholder: '请留下您的联系方式' })
            .width(this.screenWidth - 24)
            .margin(12)
            .backgroundColor(Color.White)
            .borderRadius(4)
            .borderWidth(1)
            .borderColor('#d9d9d9')
            .onChange((value: string) => {
              this.phone = value
            })
        }
        .backgroundColor(Color.White)

        Row() {
          Text('上传附件')
        }
        .margin(12)

        Row() {
          Column() {
            if (this.attachmentId === '') {
              AppIcon({ iconCode: IconConstants.ADD, iconColor: '#999999', iconSize: 24 })
              Text('上传附件')
                .margin({ top: 8 })
                .fontColor('#999999')
                .fontSize(14)
            } else {
              AppIcon({ iconCode: IconConstants.FOLDER, iconColor: '#40A9FF', iconSize: 24 })
              AppIcon({
                iconCode: IconConstants.CLOSE,
                iconColor: '#FF4040',
                iconSize: 16,
                iconMargin: { top: 8 }
              })
            }
          }
          .width(100)
          .height(100)
          .justifyContent(FlexAlign.Center)
          .margin({ left: 12 })
          .borderColor('#999999')
          .borderWidth(1)
          .borderStyle(BorderStyle.Dashed)
          .onClick(() => this.handleUpload())
        }
        .width('100%')
        .height(140)
        .backgroundColor(Color.White)

      }
      .alignItems(HorizontalAlign.Start)
      .flexGrow(1)

      Column() {
        Button('提交', { type: ButtonType.Normal })
          .margin(16)
          .width(this.screenWidth - 32)
          .height(40)
          .backgroundColor('#40A9FF')
          .borderRadius(4)
          .onClick(() => this.handleSubmitReflect())
      }
      .justifyContent(FlexAlign.End)

    }
    .title(CustomNavTitle('反馈&建议'))
    .backgroundColor("#f1f1f1")
  }
}

@Builder
export function UserReflectBuilder() {
  UserReflect()
}

function toast_fail(arg0: undefined) {
  throw new Error('Function not implemented.')
}
