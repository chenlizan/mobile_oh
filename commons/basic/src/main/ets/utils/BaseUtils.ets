import _ from "@wolfx/lodash"
import dayjs from "dayjs"
import duration, { DurationUnitType } from 'dayjs/plugin/duration'
import { CryptoJS } from '@ohos/crypto-js'
import { pinyin } from 'pinyin-pro'
import { PARAMS } from "./EnhancedFetch"
import { ObjectUtil } from "./ObjectUtil"
import { CustomToast } from "../components/CustomToast"
import { IconConstants } from "../constants/IconConstants"

dayjs.extend(duration)

export const isJSON = (str: string): boolean => {
  try {
    const obj: object = JSON.parse(str)
    return !!(typeof obj === 'object' && obj)
  } catch (e) {
    return false
  }
}

export const translateRichText = (text: string) => {
  let desc = ''
  if (_.trim(text) && isJSON(text)) {
    const blocks = (JSON.parse(text) as Record<string, string>).blocks
    if (!_.isEmpty(blocks)) {
      _.map(blocks, (block: Record<string, string>) => {
        const text = block.text ? block.text : ''
        desc = desc + text + '\n'
      })
    } else {
      desc = ''
    }
  } else {
    desc = text
  }
  return _.trim(desc) ? desc : ''
}

export const getApiHostDomain = (url: string): string => {
  if (url) {
    const baseArr = url.split('//')
    const baseUrl = baseArr[1]
    const host = baseUrl.split('/')[0]
    return `${host.split('.')[0]}`
  }
  return ''
}

// 验证是否含有空格
export function checkNoSpace(value: string, placeholder: string = '密码') {
  const regPassword = /^[^\s]*$/
  if (!regPassword.test(value)) {
    CustomToast.toast_fail(`${placeholder}禁止输入空格`)
    return false
  }
  return true
}

// 验证用户名不为空
export function checkUserName(name: string, placeholder: string = '手机号/账号'): boolean {
  if (!_.trim(name)) {
    CustomToast.toast_fail(`请输入${placeholder}`)
    return false
  }

  return checkNoSpace(name, placeholder)
}

// 验证密码不为空
export function checkPassWord(password: string, placeholder: string = '密码'): boolean {
  if (password === null || password === '' || password === 'undefined') {
    CustomToast.toast_fail(`请输入${placeholder}`)
    return false
  }
  return checkNoSpace(password, placeholder)
}

// 验证密码是否一致
export function checkPassWordSame(password1: string, password2: string, placeholder: string = '密码') {
  if (
    !checkPassWord(password1, placeholder) ||
      !checkPassWord(password2, placeholder)
  ) {
    return false
  }
  if (password1 !== password2) {
    CustomToast.toast_fail(`${placeholder}与首次输入的不一致`)
    return false
  }
  return true
}

// 验证手机号不为空
export function checkPhone(phone: string, placeholder: string = '手机号'): boolean {
  if (phone === null || phone === '' || phone === 'undefined') {
    CustomToast.toast_fail(`请输入${placeholder}`)
    return false
  }
  return checkNoSpace(phone, placeholder)
}

// 验证验证码不能为空
export function checkCode(code: string) {
  if (_.isEmpty(code)) {
    CustomToast.toast_fail(`请输入手机验证码`)
    return false
  }
  if (!/^\d{6}$/.test(code)) {
    CustomToast.toast_fail(`验证码不正确`)
    return false
  }
  return true
}

// 密码中不能包括中文字符
export function checkNoChinese(value: string, placeholder = '密码') {
  const regPassword = /[\u4e00-\u9fa5]/
  if (regPassword.test(value)) {
    CustomToast.toast_fail(`${placeholder}中不能包括中文字符`)
    return false
  }
  return true
}

// 密码校验
export const verifyPassWord = (password: string) => {
  if (!checkNoSpace(password)) {
    return false
  }
  if (!checkNoChinese(password, '密码')) {
    return false
  }
  const regPassword =
    /^(?![A-Za-z]+$)(?![A-Z0-9]+$)(?![A-Z\W_]+$)(?![a-z0-9]+$)(?![a-z\W_]+$)(?![0-9\W_]+$)[A-Za-z0-9\W_]{8,18}$/
  if (!regPassword.test(password)) {
    CustomToast.toast_fail('密码长度8-18，由3种及以上字符类型（大写字母/小写字母/数字/特殊字符）组成')
    return false
  }
  return true
}

export const verifyNameIsMobile = (name: string) => {
  const mobileRegex = /^1[3,4,5,6,7,8,9]\d{9}$/
  return mobileRegex.test(name)
}

const BASE_IV = CryptoJS.enc.Utf8.parse('12345678')

/**
 * 加密
 * @param {Any} message 需要加密的数据
 * @param {String} key 加密的秘钥
 * @returns 加密后的数据
 */

export const encryptDes = (message: string, key: string): string | undefined => {
  try {
    const keyHex = CryptoJS.enc.Utf8.parse(key)
    const option: CryptoJS.CipherOption = {
      iv: BASE_IV,
      mode: CryptoJS.mode.CBC,
      padding: CryptoJS.pad.Pkcs7,
    }
    const encrypted = CryptoJS.DES.encrypt(message, keyHex, option)
    return encrypted.ciphertext.toString(CryptoJS.enc.Base64)
  } catch (e) {
    console.error(e)
    return undefined
  }
}

// 获取身份列表
export const getIdentityList = (userInfo: ObjectUtil<never>) => {
  const manageSpaces: PARAMS[] = []

  _.forEach(userInfo.getValue('platformUserRoleInfos') ?? [], (info: Record<string, string>) => {
    manageSpaces.push({
      'type': 'manager',
      'role': info.roleName,
      'title': '平台管理空间',
    })
  })

  _.forEach(userInfo.getValue('schoolRoleInfos'), (info: Record<string, Record<string, string>>) => {
    const _schoolId = info?.schoolId
    const _schoolName = info?.schoolInfo?.schoolName

    const roleDepartmentList: Record<string, string>[] =
      _.isArray(info?.roleDepartmentList) ? info?.roleDepartmentList : []
    if (!_.isEmpty(roleDepartmentList)) {
      if (roleDepartmentList.some(v => v.roleCode === 'JS007')) {
        manageSpaces.push({
          'type': 'supervision',
          'role': '督导',
          'schoolId': _schoolId ?? '',
          'schoolName': `${_schoolName || 'xxx学校'}`,
          'title': '督导空间',
        })
      }

      if (roleDepartmentList.some(v => v.roleCode === 'JS008')) {
        manageSpaces.push({
          'type': 'review',
          'role': '评审',
          'schoolId': _schoolId ?? '',
          'schoolName': `${_schoolName || 'xxx学校'}`,
          'title': '评审空间',
        })
      }
    }

    let userRoleInfos: Record<string, number>[] = _.isArray(info?.userRoleInfos) ? info.userRoleInfos : []
    userRoleInfos = _.filter(userRoleInfos, (v) => v.roleLevel !== -1 && v.roleLevel !== 0)
    _.map(userRoleInfos, (item: Record<string, string>) => {
      let roleSpace = ''
      let title = '管理空间'
      if (item?.roleDomainScopeName) {
        roleSpace = item?.roleDomainScopeName
        if (item?.roleScopeName) {
          roleSpace = `${item.roleDomainScopeName} | ${item.roleScopeName}`
        }
      }
      if (item.roleCode === 'XXGLY001') {
        title = '学校管理空间'
      } else if (item.roleCode === 'JWGLY001') {
        title = '教务管理空间'
      } else if (item.roleCode === 'YXGLY001') {
        title = '院系管理空间'
      }
      manageSpaces.push({
        'type': 'manager',
        'role': item?.roleName ?? '',
        'schoolId': _schoolId ?? '',
        'schoolName': `${_schoolName || 'xxx学校'}`,
        'title': title,
        'roleSpace': roleSpace,
      })
    })
  })
  return manageSpaces
}

/**
 * pinyin比较函数
 */
export const compareByPinyin = (a: string, b: string) => {
  return pinyin(a, { toneType: 'none' }).localeCompare(
    pinyin(b, { toneType: 'none' }),
  )
}

/**
 * 按比较函数进行排序
 */
export const sortByPinyin = (data: Array<never>, path: string) => {
  return data.sort((a, b): number => {
    return compareByPinyin(_.get(a, path, ''), _.get(b, path, ''))
  })
}

/**
 * 双重排序，先根据loginName，再根据学校名排序
 */
export const getLoginAccounts =
  (accounts: Array<never>, school_code: number | string) => {
    const rows = sortByPinyin(
      _.sortBy(accounts, 'loginName'),
      'school.displayName',
    )
    return _.filter(rows, (item: Record<string, Record<string, string>>) => item.school.code === school_code)
  }

/**
 * 阅读密码规则
 */
export const passwordRules = (password: string) => {
  if (password.length < 6) {
    CustomToast.toast_fail('阅读密码不能小于6个字符')
    return false
  }
  if (password.length > 20) {
    CustomToast.toast_fail('阅读密码不能超过20个字符')
    return false
  }
  const regPassword = /^[^\s]*$/
  if (!regPassword.test(password)) {
    CustomToast.toast_fail('禁止输入空格')
    return false
  }
  return true
}

/**
 * 获取任务资源类型
 */
export const getTypeByTaskType = (type: number) => {
  switch (type) {
    case 1:
      return '自主观看'
    case 2:
      return '作业'
    case 3:
      return '练习'
    case 4:
      return '测验'
    case 5:
      return '问卷'
    case 6:
      return '讨论'
    default:
      return ''
  }
}

/**
 * 获取任务分配方式
 */
export const getTypeByAssignToType = (type: number, finish_type: number) => {
  switch (type) {
    case 1:
      return '个人'
    case 2:
      return finish_type === 1 ? '小组独立' : '小组合作'
    case 3:
      return '全体'
    default:
      return ''
  }
}

/**
 * 特殊角色 评审员、督导、管理员
 */

export const judgeRoleIsSpecial = (role: number) => {
  return role === 5 || role === 8 || role === 6
}

/**
 * 判断角色 是预览身份
 */
export const judgeRoleIsPreviewWeight = (role: number) => {
  return role === 5 || role === 8 || role === 7
}

/**
 * 判断课程是否结课
 */
export const judgeGroupIsEnd = (group: Record<string, string>, need_toast = true) => {
  if (!_.isEmpty(group)) {
    const end_time = group.end_time
    if (dayjs().isAfter(dayjs(end_time))) {
      need_toast && CustomToast.toast_info('课程已经结课，不允许操作')
      return true
    }
  }
  return false
}

/**
 * 判断角色 是否可以操作课程
 */
export const judgeRoleHasCourseOperationWeight = (role: number) => {
  return (
    role !== 1 && !judgeRoleIsPreviewWeight(role) && !judgeRoleIsSpecial(role)
  )
}

/**
 * 行为记录埋点信息
 */
export const getLrsTraceElement = (data: Record<string, string | null> = {
  'element_id': '',
  'element_name': '',
  'element_type': '',
  'view_name': '',
  'result': null,
}) => {
  let element: Record<string, string | Record<string, string>> = {}
  if (data.element_id) {
    element.element_id = data.element_id
  }
  if (data.element_name) {
    element.element_name = data.element_name
  }
  if (data.element_type) {
    element.element_type = data.element_type
  }
  if (data.view_name) {
    element.view_name = data.view_name
  }
  if (!_.isEmpty(element)) {
    if (data.result !== null) {
      element.extra = { 'result': data.result }
    }
  }
  return element
}

/**
 * 是否资源评审课程
 */
export const judgeCourseIsSP = (group: Record<string, number>) => {
  return group?.spType == 1 || group?.sp_type == 1
}

export function getTimeState(task: Record<string, string | number>, lang = 'en') {
  const momentNow = dayjs()
  const momentStart = dayjs(task.start_time)
  const momentEnd = dayjs(task.end_time)
  if (momentNow.isBefore(momentStart)) {
    return lang === 'cn' ? '未开始' : 'future'
  } else if (momentNow.isAfter(momentEnd)) {
    if (task.mark_mode === 3 || task.mark_mode === 4) {
      const mark_end_moment = dayjs(task.mark_end_time)
      if (momentNow.isBefore(mark_end_moment)) {
        return lang === 'cn' ? task.mark_mode === 3 ? '自评中' : '互评中' : 'checking'
      }
    }
    return lang === 'cn' ? '已截止' : 'end'
  } else {
    if (task._taskTypeText === '自主观看' || task._taskTypeText === '讨论') {
      return lang === 'cn' ? '进行中' : 'going'
    }
    return lang === 'cn' ? '答题中' : 'going'
  }
}

/**
 * 获取文件后缀名
 */
export const getExtension = (filename: string = '') => {
  return filename.split('.').pop()?.toLowerCase()
}

const videoFileMimetype = new Set(['video/mp4'])

const videoFileExtensions = new Set([
  '3gp',
  'asf',
  'avi',
  'flv',
  'f4v',
  'm2t',
  'm3u8',
  'm4v',
  'mj2',
  'mjpeg',
  'mkv',
  'mov',
  'mp4',
  'mpe',
  'mpg',
  'mpeg',
  'mts',
  'qt',
  'rm',
  'rmvb',
  'swf',
  'ts',
  'vob',
  'wmv',
])

/**
 * 判断文件是否为视频文件
 */
export function isVideoFile(filename: string, mimetype: string) {
  const ext = getExtension(filename)
  return videoFileMimetype.has(mimetype) || videoFileExtensions.has(ext || '')
}

const codeFileExtensions = new Set([
  'py',
  'c',
  'cpp',
  'cs',
  'css',
  'go',
  'html',
  'js',
  'sql',
  'tex',
  'ts',
  'java',
  'md',
  'xml',
  'json',
])

/**
 * 判断文件是否为代码文件
 */
function isCodeFile(filename: string) {
  const ext = getExtension(filename)
  return codeFileExtensions.has(ext || '')
}

const imageFileMimetype = new Set([
  'image/bmp',
  'image/gif',
  'image/jpg',
  'image/jpeg',
  'image/png',
])

const imageFileExtensions = new Set(['jpg', 'jpeg', 'bmp', 'gif', 'png'])

/**
 * 判断文件是否为图片文件
 */
export function isImageFile(filename: string, mimetype: string) {
  const ext = getExtension(filename)
  return (
    imageFileMimetype.has(mimetype) ||
    imageFileExtensions.has(ext || '') ||
    String(mimetype).startsWith('image')
  )
}

const zipFileMimetype = new Set([
  'application/x-zip-compressed',
  'application/zip',
])

const zipFileExtensions = new Set(['zip', 'rar', '7z'])

function isZipFile(filename: string, mimetype: string) {
  const ext = getExtension(filename)
  return zipFileMimetype.has(mimetype) || zipFileExtensions.has(ext || '')
}

const jsonFileExtensions = new Set(['json'])

const jsonFileMimetype = new Set(['application/json'])

function isJsonFile(filename: string, mimetype: string) {
  const ext = getExtension(filename)
  return jsonFileMimetype.has(mimetype) || jsonFileExtensions.has(ext || '')
}

const txtFileExtensions = new Set(['txt'])

const txtFileMimetype = new Set(['text/plain'])

export function isTxtFile(filename: string, mimetype: string) {
  const ext = getExtension(filename)
  return txtFileMimetype.has(mimetype) || txtFileExtensions.has(ext || '')
}

const pdfFileExtensions = new Set(['pdf'])

const pdfFileMimetype = new Set(['application/pdf'])

export function isPdfFile(filename: string, mimetype: string) {
  const ext = getExtension(filename)
  return pdfFileMimetype.has(mimetype) || pdfFileExtensions.has(ext || '')
}

const docFileExtensions = new Set(['doc', 'docx'])

const docFileMimetype = new Set([
  'application/msword',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'application/vnd.ms-works',
])

export function isDocFile(filename: string, mimetype: string) {
  const ext = getExtension(filename)
  return docFileMimetype.has(mimetype) || docFileExtensions.has(ext || '')
}

const pptFileExtensions = new Set(['ppt', 'pptx'])

const pptFileMimetype = new Set([
  'application/vnd.ms-powerpoint',
  'application/vnd.openxmlformats-officedocument.presentationml.presentation',
])

export function isPptFile(filename: string, mimetype: string) {
  const ext = getExtension(filename)
  return pptFileMimetype.has(mimetype) || pptFileExtensions.has(ext || '')
}

const xlsFileExtensions = new Set(['xls', 'xlsx'])

const xlsFileMimetype = new Set([
  'application/vnd.ms-excel',
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
])

export function isXlsFile(filename: string, mimetype: string) {
  const ext = getExtension(filename)
  return xlsFileMimetype.has(mimetype) || xlsFileExtensions.has(ext || '')
}

export function getDefaultExtensionFromMimeType(mimetype: string) {
  if (docFileMimetype.has(mimetype)) {
    return '.docx'
  }
  if (pptFileMimetype.has(mimetype)) {
    return '.pptx'
  }
  if (xlsFileMimetype.has(mimetype)) {
    return '.xlsx'
  }
  if (pdfFileMimetype.has(mimetype)) {
    return '.pdf'
  }
  return null
}

function isOffice(filename: string, mimetype: string) {
  return (
    isDocFile(filename, mimetype) ||
    isPptFile(filename, mimetype) ||
    isXlsFile(filename, mimetype)
  )
}

function needUseOffice365(name: string, mimetype: string) {
  return (
    isZipFile(name, mimetype) ||
    isJsonFile(name, mimetype) ||
    isTxtFile(name, mimetype)
  )
}

function needUseNewOffice(name: string, mimetype: string) {
  return isOffice(name, mimetype) || isPdfFile(name, mimetype)
}

/**
 * 判断文件是否为图片文件
 */
export function isOfficeFile(filename: string, mimetype: string) {
  return (
    needUseOffice365(filename, mimetype) || needUseNewOffice(filename, mimetype)
  )
}

const audioFileExtensions = new Set([
  'm4a',
  'aac',
  'mp3',
  'ogg',
  'wav',
  'amr',
])

const audioFileMimetype = new Set(['audio/x-m4a'])

export function isAudioFile(filename: string, mimetype: string) {
  const ext = getExtension(filename)
  return (
    audioFileMimetype.has(mimetype) || audioFileExtensions.has(ext || '')
  )
}

/**
 * 导航到资源详情
 */
export const navigateToResourceDetails =
  (item: Record<string, string | number>, loginRole: number, isSub: boolean = false) => {
    const pageInfos = AppStorage.get<NavPathStack>('pageInfos')
    const showFinish = loginRole === 1 && item.published === 1 && item.task_type === 1
    switch (item.type) {
      case 2:
        // 笔记
        pageInfos?.pushPath({
          name: 'noteResource',
          param: JSON.stringify({
            item,
            loginRole,
            isCourse: true,
            isSub,
            showFinish
          })
        })
        break
      case 3:
        // 导图
        pageInfos?.pushPath({
          name: 'mindMapResource',
          param: JSON.stringify({
            item,
            loginRole,
            isCourse: true,
            isSub,
            showFinish
          })
        })
        break
      case 6:
        if (isAudioFile(item.name as string, item.mimetype as string)) {
          pageInfos?.pushPath({
            name: 'audioResource',
            param: JSON.stringify({
              isCourse: true,
              item,
              loginRole,
              isSub,
              showFinish
            })
          })
        } else if (isCodeFile(item.name as string)) {
          pageInfos?.pushPath({
            name: 'codeResource',
            param: JSON.stringify({
              isCourse: true,
              item,
              loginRole,
              isSub,
              showFinish
            })
          })
        } else if (isImageFile(item.name as string, item.mimetype as string)) {
          pageInfos?.pushPath({
            name: 'imageResource',
            param: JSON.stringify({
              isCourse: true,
              item,
              loginRole,
              isSub,
              showFinish
            })
          })
        } else if (isOfficeFile(item.name as string, item.mimetype as string)) {
          pageInfos?.pushPath({
            name: 'officeResource',
            param: JSON.stringify({
              isCourse: true,
              item,
              loginRole,
              isSub,
              showFinish
            })
          })
        } else if (isVideoFile(item.name as string, item.mimetype as string)) {
          pageInfos?.pushPath({
            name: 'videoResource',
            param: JSON.stringify({
              isCourse: true,
              item,
              loginRole,
              isSub,
              showFinish
            })
          })
        } else {
          CustomToast.toast_fail('移动客户端暂不支持打开此类型文件')
        }
        break
      case 7:
        // 问答
        pageInfos?.pushPath({ name: 'questionResource', param: JSON.stringify({ item, loginRole, isSub }) })
        break
      case 8:
        // 讨论
        pageInfos?.pushPath({ name: 'discussResource', param: JSON.stringify({ item, loginRole, isSub }) })
        break
      case 9:
        // 视频
        pageInfos?.pushPath({
          name: 'videoResource',
          param: JSON.stringify({
            isCourse: true,
            item,
            loginRole,
            isSub,
            showFinish
          })
        })
        break
      case 10:
        // 音频
        pageInfos?.pushPath({
          name: 'audioResource',
          param: JSON.stringify({
            isCourse: true,
            item,
            loginRole,
            isSub,
            showFinish
          })
        })
        break
      case 11:
        // 教学设计
        pageInfos?.pushPath({ name: 'teachDesignResource', param: JSON.stringify({ item, loginRole, isSub }) })
        break
      default:
        break
    }
  }

/**
 * 根据文件类型获取图标
 */
export const getIconByFileType = (type: number, filename: string, mimetype: string) => {
  if (type === 1) {
    return {
      'iconCode': IconConstants.FOLDER,
      'iconColor': '#666666',
      'iconSize': 18
    } as Record<string, string | number>
  } else if (type === 2) {
    return {
      'iconCode': IconConstants.NOTE,
      'iconColor': '#CCC597',
      'iconSize': 20
    } as Record<string, string | number>
  } else if (type === 3) {
    return {
      'iconCode': IconConstants.MIND,
      'iconColor': '#C59A77',
      'iconSize': 20
    } as Record<string, string | number>
  } else if (type === 6) {
    if (isVideoFile(filename, mimetype)) {
      return {
        'iconCode': IconConstants.VIDEO,
        'iconColor': '#84CBDC',
        'iconSize': 20
      } as Record<string, string | number>
    } else if (isAudioFile(filename, mimetype)) {
      return {
        'iconCode': IconConstants.AUDIO,
        'iconColor': '#F19292',
        'iconSize': 20
      } as Record<string, string | number>
    } else if (isImageFile(filename, mimetype)) {
      return {
        'iconCode': IconConstants.IMAGE,
        'iconColor': '#E4B34D',
        'iconSize': 20
      } as Record<string, string | number>
    } else if (isTxtFile(filename, mimetype)) {
      return {
        'iconCode': IconConstants.TXT,
        'iconColor': '#9B97BA',
        'iconSize': 20
      } as Record<string, string | number>
    } else if (isPdfFile(filename, mimetype)) {
      return {
        'iconCode': IconConstants.PDF,
        'iconColor': '#C54442',
        'iconSize': 20
      } as Record<string, string | number>
    } else if (isDocFile(filename, mimetype)) {
      return {
        'iconCode': IconConstants.DOC,
        'iconColor': '#7392AF',
        'iconSize': 20
      } as Record<string, string | number>
    } else if (isXlsFile(filename, mimetype)) {
      return {
        'iconCode': IconConstants.XLSX,
        'iconColor': '#86A77C',
        'iconSize': 20
      } as Record<string, string | number>
    } else if (isPptFile(filename, mimetype)) {
      return {
        'iconCode': IconConstants.PPT,
        'iconColor': '#C56464',
        'iconSize': 20
      } as Record<string, string | number>
    }
  } else if (type === 7) {
    return {
      'iconCode': IconConstants.QUESTION,
      'iconColor': '#A4D9CC',
      'iconSize': 20
    } as Record<string, string | number>
  } else if (type === 8) {
    return {
      'iconCode': IconConstants.DISCUSS,
      'iconColor': '#99B6E2',
      'iconSize': 20
    } as Record<string, string | number>
  } else if (type === 9) {
    return {
      'iconCode': IconConstants.VIDEO,
      'iconColor': '#84CBDC',
      'iconSize': 20
    } as Record<string, string | number>
  } else if (type === 10) {
    return {
      'iconCode': IconConstants.AUDIO,
      'iconColor': '#F19292',
      'iconSize': 20
    } as Record<string, string | number>
  } else if (type === 11) {
    return {
      'iconCode': IconConstants.TEACH_DESIGN,
      'iconColor': '#E4826D',
      'iconSize': 20
    } as Record<string, string | number>
  }
  return {
    'iconCode': IconConstants.OTHER_FILE,
    'iconColor': '#B1B1B1',
    'iconSize': 20
  } as Record<string, string | number>
}

export const getCourseInfo = (item: Record<string, string>) => {
  const content: string[] = []
  if (item.term_name) {
    content.push(String(item.term_name))
  }
  if (item.public_type) {
    content.push((() => {
      switch (String(item.public_type)) {
        case '1':
          return `私有`
        case '2':
          return `课内`
        case '3':
          return `校内`
        case '4':
          return `全网`
        default:
          return ''
      }
    })())
  }
  if (item.origin_type === '2') {
    content.push('自主开课')
  } else {
    content.push('教务开课')
  }
  return content.join(' | ')
}

export const getAllSubResources =
  (item: Record<string, string | number>, resources: Array<object>, nodes: Record<string, number>[]) => {
    const resource = _.filter(resources, { parent_id: item.id }) as Record<string, number> []
    if (resource) {
      _.filter(resource, res => {
        if (res.type === 1) {
          getAllSubResources(res, resources, nodes)
        } else {
          nodes.push(res)
        }
      })
    }
  }

export const getFolderDownloadStatus = (item: Record<string, string | number>, resources: Array<object>) => {
  let subRes: Record<string, number>[] = []
  getAllSubResources(item, resources, subRes)
  if (_.isEmpty(subRes)) {
    return 0
  }
  subRes = _.filter(subRes, res => res.type === 6 || res.type === 9)
  const _download = _.filter(subRes, res => res.download === 2)
  if (_.isEmpty(_download)) {
    return 1
  }
  // 0文件夹为空 1文件夹不可下载 2文件夹部分可下载 3文件夹可下载
  return _download.length === subRes.length ? 3 : 2
}

export const getFolderPublicStatus = (item: Record<string, string | number>, resources: Array<object>) => {
  let subRes: Record<string, number>[] = []
  getAllSubResources(item, resources, subRes)
  if (_.isEmpty(subRes)) {
    return 0
  }
  subRes = _.filter(subRes, res => res.type !== 7)

  const _public = _.filter(subRes, res => res.public === 2)
  if (_.isEmpty(_public)) {
    return 1
  }
  // 0文件夹为空 1文件夹不可见 2文件夹部分可见 3文件夹可见
  return _public.length === subRes.length ? 3 : 2
}

export const getFolderDownloadStatusText =
  (type: number, item: Record<string, string | number>, resources: Array<object>, loginRole: number) => {
    if (type === 1) {
      if (loginRole !== 1) {
        const status = getFolderDownloadStatus(item, resources)
        if (status === 2) {
          return '部分可下载'
        }
        if (status === 3) {
          return '可下载'
        }
      }
    } else if (type === 6 || type === 9) {
      if (item.download === 2) {
        return '可下载'
      }
    }
    return ''
  }

export const getFolderPublicStatusText =
  (type: number, item: Record<string, string | number>, resources: Array<object>, loginRole: number) => {
    if (type === 1) {
      if (loginRole !== 1) {
        const status = getFolderPublicStatus(item, resources)
        if (status === 2) {
          return '部分可见'
        }
        if (status === 3) {
          return '可见'
        }
      }
    } else if (type !== 7) {
      if (item.public === 2) {
        return '可见'
      }
    }

    return ''
  }

export const getResourceStatus = (item: Record<string, string | number>, resources: Array<object>) => {
  // status 0:灰色勾勾 1:绿色勾勾 2:空心圆圈
  // 老师
  // 灰色勾勾：资源：未讲授；文件夹：文件夹中的资源未全部讲授；
  // 绿色勾勾：资源：已讲授；文件夹：文件夹中的资源未全部讲授
  // 空心圆圈：文件夹中无资源

  let status = 0
  let isPublished = false

  let subRes = []
  if (item.type === 1) {
    getAllSubResources(item, resources, subRes)
  }
  if (item._formatKey !== 'student') {
    // 老师
    if (item.type === 1) {
      if (subRes.length === 0) {
        status = 2
      } else {
        status =
          subRes.length ===
          _.filter(subRes, (res: Record<string, number>) => res.finish_teaching === 1).length ? 1 : 0
      }
      isPublished =
        subRes.length === _.filter(subRes, (res: Record<string, number>) => res.published === 1).length &&
          subRes.length !== 0
    } else {
      status = item.finish_teaching === 1 ? 1 : 0
    }
  }
  return { 'status': status, 'isPublished': isPublished } as Record<string, number | boolean>
}

export const regularFilename = (orgName: string, currentFiles: Record<string, string>[]) => {
  const filenames = _.values(currentFiles).map(f => f.name)
  const parts = orgName.split('.')
  let filename = orgName
  let index = 1
  while (filenames.indexOf(filename) >= 0) {
    if (parts.length > 1) {
      filename = `${_.dropRight(parts).join('.')}(${index}).${_.last(parts)}`
    } else if (parts.length === 1) {
      filename = `${_.last(parts)}(${index})`
    } else {
      return orgName
    }

    index += 1
  }
  return filename
}

export const verifyNameIsSpecial = (name: string) => {
  const nameRegex = /[\\|:|*|?|"|<|>||]/
  return nameRegex.test(name)
}

export const transTimeHm = (time: number, unit: DurationUnitType = 'seconds', mT = '分') => {
  if (unit === 'seconds' ? time >= 60 : time > 0) {
    const date = dayjs.duration(time, unit)
    let txt = ''
    if (date.asHours() >= 1) {
      txt += _.floor(date.asHours(), 0) + '小时'
    }
    txt += date.minutes() + mT
    return txt
  }
  return `0${mT}`
}

export const getResourcePath = (parent_id: string, courseResources: Record<string, string | number | boolean> [],
  courseSubResources: Record<string, string | number | boolean> []): string => {
  const sub = _.find(courseSubResources, { attribute: parent_id })
  if (sub && sub.parent_id) {
    return getResourcePath(String(sub.parent_id), courseResources, courseSubResources) + '/' + sub.name
  } else {
    const res = _.find(courseResources, { id: parent_id });
    if (res) {
      return `/${res.name}`
    }
  }
  return '/'
}