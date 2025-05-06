import { fileIo, picker } from '@kit.CoreFileKit'
import { uniformTypeDescriptor } from '@kit.ArkData'
import axios, { AxiosError, AxiosProgressEvent, AxiosResponse, FormData } from '@ohos/axios'
import { CustomToast } from '../components/CustomToast'
import { ccApiPost } from './EnhancedFetch'
import { CCApi } from '../config/ApiConfig'
import { Api_Context } from '../config/Context'

export async function UploadUtil(cb: (attachmentId: string) => void) {
  const documentSelectOptions = new picker.DocumentSelectOptions()
  const documentViewPicker = new picker.DocumentViewPicker()
  const documentSelectResult = await documentViewPicker.select(documentSelectOptions)

  if (documentSelectResult.length >= 1) {
    const uri = documentSelectResult[0]
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
      return
    }

    if (mimeTypes.indexOf('video/') !== -1) {
      CustomToast.toast_info('暂不支持视频上传')
      return
    }

    CustomToast.toast_loading('正在上传文件...')

    let response =
      await ccApiPost(AppStorage.get<Api_Context>('Api_Context')?.getApiPrefix('ccApi') + CCApi.generateSignUpload,
        { 'suffix': fileExtention })
    if (response.code !== 200) {
      CustomToast.hide()
      CustomToast.toast_fail('上传失败')
      return
    }
    const ossData: Record<string, string> = response.result as Record<string, string>

    response = await ccApiPost(AppStorage.get<Api_Context>('Api_Context')?.getApiPrefix('ccApi') + CCApi.oss, {
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
      return
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
      context: getContext(),
      onUploadProgress: (progressEvent: AxiosProgressEvent): void => {
        console.info(progressEvent && progressEvent.loaded && progressEvent.total ?
          Math.ceil(progressEvent.loaded / progressEvent.total * 100) + '%' : '0%')
      },
    }).then((res: AxiosResponse<string>) => {
      CustomToast.hide()
      CustomToast.toast_success('上传成功!')
      if (cb) {
        cb(response.result as string)
      }
      console.info("result" + JSON.stringify(res.data))
    }).catch((err: AxiosError) => {
      CustomToast.hide()
      CustomToast.toast_fail('上传失败')
      console.error("error:" + JSON.stringify(err))
    })
  }
}