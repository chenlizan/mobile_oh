import _ from "@wolfx/lodash";
import { CryptoJS } from '@ohos/crypto-js'
import { promptAction } from "@kit.ArkUI";
import { PARAMS } from "./EnhancedFetch";
import { ObjectUtil, ObjectOption } from "./ObjectUtil";

export const isJSON = (str: string): boolean => {
  try {
    const obj: object = JSON.parse(str);
    return !!(typeof obj === 'object' && obj);
  } catch (e) {
    return false;
  }
};

export const getApiHostDomain = (url: string): string => {
  if (url) {
    const baseArr = url.split('//');
    const baseUrl = baseArr[1];
    const host = baseUrl.split('/')[0];
    return `${host.split('.')[0]}`;
  }
  return '';
};

// 验证是否含有空格
export function checkNoSpace(value: string, placeholder: string = '密码') {
  const regPassword = /^[^\s]*$/;
  if (!regPassword.test(value)) {
    promptAction.showToast({ alignment: Alignment.Center, message: `${placeholder}禁止输入空格` });
    return false;
  }
  return true;
}

// 验证用户名不为空
export function checkUserName(name: string, placeholder: string = '手机号/账号'): boolean {
  if (!_.trim(name)) {
    promptAction.showToast({ alignment: Alignment.Center, message: `请输入${placeholder}` });
    return false;
  }

  return checkNoSpace(name, placeholder);
}

// 验证密码不为空
export function checkPassWord(password: string, placeholder: string = '密码'): boolean {
  if (password === null || password === '' || password === 'undefined') {
    promptAction.showToast({ alignment: Alignment.Center, message: `请输入${placeholder}` });
    return false;
  }
  return checkNoSpace(password, placeholder);
}

// 验证密码是否一致
export function checkPassWordSame(password1: string, password2: string, placeholder: string = '密码') {
  if (
    !checkPassWord(password1, placeholder) ||
      !checkPassWord(password2, placeholder)
  ) {
    return false;
  }
  if (password1 !== password2) {
    promptAction.showToast({ alignment: Alignment.Center, message: `${placeholder}与首次输入的不一致` });
    return false;
  }
  return true;
}

//密码中不能包括中文字符
export function checkNoChinese(value: string, placeholder = '密码') {
  const regPassword = /[\u4e00-\u9fa5]/;
  if (regPassword.test(value)) {
    promptAction.showToast({ alignment: Alignment.Center, message: `${placeholder}中不能包括中文字符` });
    return false;
  }
  return true;
}

// 密码校验
export const verifyPassWord = (password: string) => {
  if (!checkNoSpace(password)) {
    return false;
  }
  if (!checkNoChinese(password, '密码')) {
    return false;
  }
  const regPassword =
    /^(?![A-Za-z]+$)(?![A-Z0-9]+$)(?![A-Z\W_]+$)(?![a-z0-9]+$)(?![a-z\W_]+$)(?![0-9\W_]+$)[A-Za-z0-9\W_]{8,18}$/;
  if (!regPassword.test(password)) {
    promptAction.showToast({
      alignment: Alignment.Center,
      message: '密码长度8-18，由3种及以上字符类型（大写字母/小写字母/数字/特殊字符）组成'
    });
    return false;
  }
  return true;
};

const BASE_IV = CryptoJS.enc.Utf8.parse('12345678')

/**
 * 加密
 * @param {Any} message 需要加密的数据
 * @param {String} key 加密的秘钥
 * @returns 加密后的数据
 */

export const encryptDes = (message: string, key: string): string | undefined => {
  try {
    const keyHex = CryptoJS.enc.Utf8.parse(key);
    const option: CryptoJS.CipherOption = {
      iv: BASE_IV,
      mode: CryptoJS.mode.CBC,
      padding: CryptoJS.pad.Pkcs7,
    };
    const encrypted = CryptoJS.DES.encrypt(message, keyHex, option);
    return encrypted.ciphertext.toString(CryptoJS.enc.Base64);
  } catch (e) {
    console.error(e);
    return undefined
  }
};

// 获取身份列表
export const getIdentityList = (userInfo: object) => {
  const manageSpaces: PARAMS[] = [];
  const _userInfo = new ObjectUtil(userInfo as ObjectOption<never>)

  interface VL {
    roleCode: string,
    roleLevel: number,
    roleDomainScopeName: string,
    roleDepartmentList: VL[],
    roleName: string,
    roleScopeName: string,
    schoolId: string,
    schoolInfo: VL,
    schoolName: string,
    userRoleInfos: VL[]
  }

  _.forEach(_userInfo.getValue('platformUserRoleInfos') ?? [], (info: VL) => {
    manageSpaces.push({
      'type': 'manager',
      'role': info.roleName,
      'title': '平台管理空间',
    });
  });

  _.forEach(_userInfo.getValue('schoolRoleInfos'), (info: VL) => {
    const _schoolId = info?.schoolId
    const _schoolName = info?.schoolInfo?.schoolName

    const roleDepartmentList: VL[] = info?.roleDepartmentList ?? [];
    if (!_.isEmpty(roleDepartmentList)) {
      if (roleDepartmentList.some(v => v.roleCode === 'JS007')) {
        manageSpaces.push({
          'type': 'supervision',
          'role': '督导',
          'schoolId': _schoolId ?? '',
          'schoolName': `${_schoolName || 'xxx学校'}`,
          'title': '督导空间',
        });
      }

      if (roleDepartmentList.some(v => v.roleCode === 'JS008')) {
        manageSpaces.push({
          'type': 'review',
          'role': '评审',
          'schoolId': _schoolId ?? '',
          'schoolName': `${_schoolName || 'xxx学校'}`,
          'title': '评审空间',
        });
      }
    }

    const userRoleInfos = _.filter(info?.userRoleInfos ?? [], (v: VL) => v.roleLevel !== -1 && v.roleLevel !== 0);
    _.map(userRoleInfos, (item: VL) => {
      let roleSpace = '';
      let title = '管理空间';
      if (item?.roleDomainScopeName) {
        roleSpace = item?.roleDomainScopeName;
        if (item?.roleScopeName) {
          roleSpace = `${item.roleDomainScopeName} | ${item.roleScopeName}`;
        }
      }
      if (item.roleCode === 'XXGLY001') {
        title = '学校管理空间';
      } else if (item.roleCode === 'JWGLY001') {
        title = '教务管理空间';
      } else if (item.roleCode === 'YXGLY001') {
        title = '院系管理空间';
      }
      manageSpaces.push({
        'type': 'manager',
        'role': item?.roleName ?? '',
        'schoolId': _schoolId ?? '',
        'schoolName': `${_schoolName || 'xxx学校'}`,
        'title': title,
        'roleSpace': roleSpace,
      });
    });
  });
  return manageSpaces;
};