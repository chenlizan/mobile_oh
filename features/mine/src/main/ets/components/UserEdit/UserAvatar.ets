import { uniformTypeDescriptor } from "@kit.ArkData"
import { util } from "@kit.ArkTS"
import { display } from "@kit.ArkUI"
import { camera, cameraPicker } from '@kit.CameraKit'
import { photoAccessHelper } from "@kit.MediaLibraryKit"
import { fileIo } from "@kit.CoreFileKit"
import axios, { AxiosError, AxiosProgressEvent, AxiosResponse, FormData } from '@ohos/axios'
import _ from "@wolfx/lodash"
import {
  Api_Context,
  Avatar,
  CCApi,
  ccApiPost,
  CustomNavTitle,
  CustomToast,
  SystemApi,
  UserInfoModel,
  xyApiGet,
  xyApiPost,
  xyApiPut
} from "@xy/basic"

@Component
struct UserAvatar {
  @StorageLink('Api_Context') Api_Context: Api_Context = new Api_Context()
  @StorageLink('UserInfo') userInfo: UserInfoModel = new UserInfoModel()
  @State avatar: string = this.userInfo.avatar
  @State screenWidth: number = 0
  @State sysAvatars: object[] = []

  aboutToAppear(): void {
    this.screenWidth = px2vp(display.getDefaultDisplaySync().width)
    this.queryAvatarSetting()
  }

  async queryAvatarSetting() {
    const response = await xyApiGet(this.Api_Context.getApiPrefix('baseApi_inner') + SystemApi.avatarSetting)
    if (response.success) {
      const result = response.data
      const latestAvatar = (result as Record<string, Record<string, boolean>>)?.latest_setting_avatar ?? null
      let sysAvatars = (result as Record<string, object>)?.default_avatars ?? []
      if (!_.isEmpty(latestAvatar) && !latestAvatar?.is_system && _.isArray(sysAvatars)) {
        sysAvatars.unshift(latestAvatar)
      }
      this.sysAvatars = sysAvatars as object[]
    }
  }

  getSysAvatarUrl = (file_id: string) => {
    return `${this.Api_Context.getApiPrefix(
      'baseApi_out',
    )}cloud/file_access/${file_id}`;
  }

  async handleRecordAvatar(file_id: string) {
    if (_.includes(this.userInfo.avatar, file_id)) {
      return;
    }

    const pre_avatar_id = this.userInfo.avatar.split('/').pop()

    const response = await ccApiPost(this.Api_Context.getApiPrefix("ccApi") + CCApi.userUpdate,
      { 'avatar': '/cloud/file_access/' + file_id })
    if (response.code === 0) {
      this.avatar = this.userInfo.avatar = '/cloud/file_access/' + file_id
      CustomToast.toast_info('头像设置成功')

      const responseXy = await xyApiPut(this.Api_Context.getApiPrefix('baseApi_inner') + SystemApi.latestAvatar,
        { 'file_id': pre_avatar_id })
      if (responseXy.success) {
        this.queryAvatarSetting()
      }
    }
  }

  async handleUpload(type: string = 'camera' || 'photo') {
    let file: fileIo.File
    let pickerResult: cameraPicker.PickerResult | photoAccessHelper.PhotoSelectResult
    if (type === 'camera') {
      let pickerProfile: cameraPicker.PickerProfile = {
        cameraPosition: camera.CameraPosition.CAMERA_POSITION_BACK
      };
      pickerResult = await cameraPicker.pick(getContext(),
        [cameraPicker.PickerMediaType.PHOTO], pickerProfile)
      file = fileIo.openSync(pickerResult.resultUri)
    } else {
      let PhotoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
      PhotoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE
      PhotoSelectOptions.maxSelectNumber = 1
      PhotoSelectOptions.isPhotoTakingSupported = false
      let photoPicker = new photoAccessHelper.PhotoViewPicker()
      pickerResult = await photoPicker.select(PhotoSelectOptions)
      file = fileIo.openSync(pickerResult.photoUris[0])
    }

    const stat = fileIo.statSync(file.fd)
    const fileName = file.name
    const fileSize = stat.size
    const fileExtention = file.name.split('.').pop()
    const typeId = uniformTypeDescriptor.getUniformDataTypeByFilenameExtension(`.${fileExtention}`)
    const typeObj = uniformTypeDescriptor.getTypeDescriptor(typeId)
    const mimeTypes = typeObj.mimeTypes[0]
    const fileBuffer = new ArrayBuffer(stat.size)
    fileIo.readSync(file.fd, fileBuffer)
    fileIo.closeSync(file.fd)

    const isLimit = fileSize / 1024 / 1024 < (this.userInfo.fileCapacity as Record<string, number>).perFileSize
    if (!isLimit) {
      CustomToast.toast_fail(`上传文件大小限制为${(this.userInfo.fileCapacity as Record<string, number>).perFileSize}M`)
    } else {

      let response = await xyApiPost(this.Api_Context.getApiPrefix('baseApi_out') + SystemApi.diskFiles,
        { 'filename': fileName, 'uploadId': util.generateRandomUUID(true), 'file_size': fileSize })

      if (response.success) {
        const ossData: Record<string, Record<string, string>> =
          response.data as Record<string, Record<string, string>>

        const formData = new FormData()
        formData.append('x:id', ossData.multipart['x:id'])
        formData.append('x:user_id', ossData.multipart['x:user_id'])
        formData.append('key', ossData.multipart.key)
        formData.append('OSSAccessKeyId', ossData.multipart.OSSAccessKeyId)
        formData.append('policy', ossData.multipart.policy)
        formData.append('signature', ossData.multipart.signature)
        formData.append('callback', ossData.multipart.callback)
        formData.append('x-oss-content-type', mimeTypes)
        formData.append('file', fileBuffer)

        axios.post<string, AxiosResponse<string>, FormData>((response.data as Record<string, string>).host, formData,
          {
            headers: { 'Content-Type': 'multipart/form-data' },
            context: getContext(this),
            onUploadProgress: (progressEvent: AxiosProgressEvent): void => {
              console.info(progressEvent && progressEvent.loaded && progressEvent.total ?
                Math.ceil(progressEvent.loaded / progressEvent.total * 100) + '%' : '0%');
            },
          }).then((res: AxiosResponse) => {
          const result = res.data as Record<string, boolean | Record<string, string>>
          if (result.success) {
            this.handleRecordAvatar((result.data as Record<string, string>).id)
          }
        }).catch((err: AxiosError) => {
          CustomToast.toast_fail('上传失败')
          console.error("error:" + JSON.stringify(err));
        })
      }
    }
  }

  build() {
    NavDestination() {
      Column() {
        Column() {
          Avatar({ avatar: $avatar, avatarSize: this.screenWidth - 60 })
        }
        .flexGrow(1)
        .justifyContent(FlexAlign.Center)

        Row() {
          Button('从相册中选择', { type: ButtonType.Normal })
            .width(this.screenWidth / 2 - 30)
            .borderRadius(4)
            .backgroundColor('#40A9FF')
            .onClick(() => this.handleUpload('photo'))
          Button('拍照上传', { type: ButtonType.Normal })
            .width(this.screenWidth / 2 - 30)
            .borderRadius(4)
            .backgroundColor('#40A9FF')
            .onClick(() => this.handleUpload('camera'))
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceAround)

        Row() {
          Text('使用小雅系列头像')
            .padding(16)
            .fontColor('#999999')
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)

        List() {
          ForEach(this.sysAvatars, (item: Record<string, string>) => {
            ListItem() {
              Image(this.getSysAvatarUrl(item.file_id))
                .width(36)
                .borderRadius(18)
                .borderWidth(1)
                .borderColor(_.includes(this.userInfo.avatar, item.file_id) ? '#40A9FF' : '#F1F1F1')
                .onClick(() => this.handleRecordAvatar(item.file_id))
            }
            .height(60)
            .margin({ left: 10 })
          })
        }
        .width(this.screenWidth - 32)
        .height(60)
        .margin({ bottom: 16 })
        .listDirection(Axis.Horizontal)
        .backgroundColor(Color.White)
        .borderRadius(4)
      }
      .height('100%')
    }
    .title(CustomNavTitle('修改头像'))
    .backgroundColor("#f1f1f1")
  }
}

@Builder
export function UserAvatarBuilder() {
  UserAvatar()
}