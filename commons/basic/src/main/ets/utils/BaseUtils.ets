import _ from "@wolfx/lodash"
import dayjs from "dayjs"
import { CryptoJS } from '@ohos/crypto-js'
import { pinyin } from 'pinyin-pro'
import { PARAMS } from "./EnhancedFetch"
import { ObjectUtil } from "./ObjectUtil"
import { CustomToast } from "../components/CustomToast"

export const isJSON = (str: string): boolean => {
  try {
    const obj: object = JSON.parse(str)
    return !!(typeof obj === 'object' && obj)
  } catch (e) {
    return false
  }
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
 * 获取文件后缀名
 */
export const getExtension = (filename: string = '') => {
  return filename.split('.').pop()?.toLowerCase()
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
  let element: Record<string, string | Record<string, string>> = {};
  if (data.element_id) {
    element.element_id = data.element_id;
  }
  if (data.element_name) {
    element.element_name = data.element_name;
  }
  if (data.element_type) {
    element.element_type = data.element_type;
  }
  if (data.view_name) {
    element.view_name = data.view_name;
  }
  if (!_.isEmpty(element)) {
    if (data.result !== null) {
      element.extra = { 'result': data.result };
    }
  }
  return element;
};

/**
 * 是否资源评审课程
 */
export const judgeCourseIsSP = (group: Record<string, number>) => {
  return group?.spType == 1 || group?.sp_type == 1;
};

const videoFileMimetype = new Set(['video/mp4']);

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
  const ext = getExtension(filename);
  return videoFileMimetype.has(mimetype) || videoFileExtensions.has(ext || '');
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
            isSub,
            showFinish
          })
        })
        break
      case 6:
        // 网盘资源
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
        break
      case 10:
        // 音频
        break
      case 11:
        // 教学设计
        pageInfos?.pushPath({ name: 'teachDesignResource', param: JSON.stringify({ item, loginRole, isSub }) })
        break
      default:
        break
    }
  }