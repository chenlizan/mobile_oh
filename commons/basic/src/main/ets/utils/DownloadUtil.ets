import { common } from '@kit.AbilityKit'
import { fileIo, picker } from '@kit.CoreFileKit'
import { request } from '@kit.BasicServicesKit'
import { CustomToast } from '../components/CustomToast'
import { xyApiGet } from './EnhancedFetch'
import { HomeApi } from '../config/ApiConfig'
import { Api_Context } from '../config/Context'
import cryptoJs from '@ohos/crypto-js'
import { PreferenceStorage } from '../model/LocalStorageModel'
import _ from '@wolfx/lodash'
import { isJSON, isVideoFile } from './BaseUtils'

export async function DownloadUtil(url: string, filename: string) {
  try {
    const context = getContext() as common.UIAbilityContext
    const filesDir = context.filesDir
    const filePath = filesDir + '/' + filename

    if (fileIo.accessSync(filePath)) {
      fileIo.unlinkSync(filePath)
    }

    const downloadTask: request.DownloadTask = await request.downloadFile(context, {
      url: url,
      filePath: filePath
    })

    await new Promise<void>((resolve, reject) => {
      downloadTask.on('complete', () => resolve())
      downloadTask.on('fail', (err) => reject(err))
    })

    const stat = fileIo.statSync(filePath)
    const arrayBuffer = new ArrayBuffer(stat.size)

    const file_s = fileIo.openSync(filePath, fileIo.OpenMode.READ_ONLY)
    fileIo.readSync(file_s.fd, arrayBuffer)

    const documentSaveOptions = new picker.DocumentSaveOptions()
    documentSaveOptions.newFileNames = [filename]

    const documentPicker = new picker.DocumentViewPicker()
    const documentSelectResult = await documentPicker.save(documentSaveOptions)

    const uri = documentSelectResult[0]
    const file_d = fileIo.openSync(uri, fileIo.OpenMode.READ_WRITE)

    fileIo.writeSync(file_d.fd, arrayBuffer)

    CustomToast.toast_success('下载成功')
  } catch (error) {
    CustomToast.toast_success('下载失败' + error.message)
  }
}

export async function DownloadToLocal(node: Record<string, string | number>) {
  let downloadUrl = ''
  if (node.quote_id) {
    if (
      isVideoFile(node.name as string, node.mimetype as string) ||
        node?.type === 9
    ) {
      const info = await getVideoVod(node.quote_id as string) as Record<string, string>
      downloadUrl = info?.download_url ?? ''
    } else {
      const data = await queryResourceInfo(node.quote_id as string)
      downloadUrl = data?.real_url ?? ''
    }
  } else {
    downloadUrl = node.url as string
  }
  DownloadUtil(downloadUrl, node.name as string)
}

// 获取视频资源信息
export const getVideoVod = async (quote_id: string) => {
  const response =
    await xyApiGet(AppStorage.get<Api_Context>('Api_Context')?.getApiPrefix('baseApi_out') + HomeApi.video_vod +
      quote_id)
  if (response?.success) {
    return response.data
  } else {
    return null
  }
}

// 获取文件信息
export const queryResourceInfo = async (quote_id: string) => {
  const response =
    await xyApiGet(AppStorage.get<Api_Context>('Api_Context')?.getApiPrefix('baseApi_out') + HomeApi.cloudFileUrl +
      quote_id,
    )
  if (response?.success) {
    const data = (response?.data ?? {}) as Record<string, string>
    if (data?.audio_transcode_url) {
      data.real_url = data?.is_encryption
        ? decryptOffice365DES(data.audio_transcode_url)
        : data.audio_transcode_url
    } else if (data?.url) {
      data.real_url = data?.is_encryption
        ? decryptOffice365DES(data.url)
        : data.url
    } else {
      data.real_url = ''
    }
    return data
  }
  return null
}

export const getOW365Setting = () => {
  const configCenter = AppStorage.get<PreferenceStorage>('PreferenceStorage')?.configCenter
  const ow365_settings = _.find(configCenter, { key: 'ow365_settings' })?.value ?? ''
  let settings = {} as Record<string, string>
  if (_.trim(ow365_settings) && isJSON(ow365_settings)) {
    settings = JSON.parse(ow365_settings)
  }
  return settings
}

export const decryptOffice365DES = (encryptedMessage: string) => {
  try {
    const ow365_settings = getOW365Setting()
    const key = cryptoJs.enc.Utf8.parse(ow365_settings?.key) //密钥
    const iv = cryptoJs.enc.Utf8.parse(ow365_settings?.vector) //向量
    // 先将替换的特殊字符还原
    const correctedMessage = encryptedMessage
      .replace(/_/g, '+')/**/
      .replace(/\*/g, '/')
      .replace(/-/g, '=')
    const decrypted = cryptoJs.DES.decrypt(cryptoJs.enc.Base64.parse(correctedMessage).toString(),
      key,
      {
        iv: iv,
        mode: cryptoJs.mode.CBC,
        padding: cryptoJs.pad.Pkcs7,
      },
    )
    return decrypted.toString(cryptoJs.enc.Utf8)
  } catch (e) {
    console.error(e)
  }
  return ''
}