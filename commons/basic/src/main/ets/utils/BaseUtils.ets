import _ from "@wolfx/lodash";
import { CryptoJS } from '@ohos/crypto-js'
import { pinyin } from 'pinyin-pro';
import { PARAMS } from "./EnhancedFetch";
import { ObjectUtil } from "./ObjectUtil";
import { CustomToast } from "../components/CustomToast";

interface VL {
  code: string,
  roleCode: string,
  roleLevel: number,
  roleDomainScopeName: string,
  roleDepartmentList: VL[],
  roleName: string,
  roleScopeName: string,
  school: VL,
  schoolId: string,
  schoolInfo: VL,
  schoolName: string,
  userRoleInfos: VL[]
}

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
    CustomToast.toast_fail(`${placeholder}禁止输入空格`)
    return false;
  }
  return true;
}

// 验证用户名不为空
export function checkUserName(name: string, placeholder: string = '手机号/账号'): boolean {
  if (!_.trim(name)) {
    CustomToast.toast_fail(`请输入${placeholder}`)
    return false;
  }

  return checkNoSpace(name, placeholder);
}

// 验证密码不为空
export function checkPassWord(password: string, placeholder: string = '密码'): boolean {
  if (password === null || password === '' || password === 'undefined') {
    CustomToast.toast_fail(`请输入${placeholder}`)
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
    CustomToast.toast_fail(`${placeholder}与首次输入的不一致`)
    return false;
  }
  return true;
}

// 验证手机号不为空
export function checkPhone(phone: string, placeholder: string = '手机号'): boolean {
  if (phone === null || phone === '' || phone === 'undefined') {
    CustomToast.toast_fail(`请输入${placeholder}`)
    return false;
  }
  return checkNoSpace(phone, placeholder);
}

// 验证验证码不能为空
export function checkCode(code: string) {
  if (_.isEmpty(code)) {
    CustomToast.toast_fail(`请输入手机验证码`)
    return false;
  }
  if (!/^\d{6}$/.test(code)) {
    CustomToast.toast_fail(`验证码不正确`)
    return false;
  }
  return true;
}

//密码中不能包括中文字符
export function checkNoChinese(value: string, placeholder = '密码') {
  const regPassword = /[\u4e00-\u9fa5]/;
  if (regPassword.test(value)) {
    CustomToast.toast_fail(`${placeholder}中不能包括中文字符`)
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
    CustomToast.toast_fail('密码长度8-18，由3种及以上字符类型（大写字母/小写字母/数字/特殊字符）组成')
    return false;
  }
  return true;
};

export const verifyNameIsMobile = (name: string) => {
  const mobileRegex = /^1[3,4,5,6,7,8,9]\d{9}$/;
  return mobileRegex.test(name);
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
export const getIdentityList = (userInfo: ObjectUtil<never>) => {
  const manageSpaces: PARAMS[] = [];

  _.forEach(userInfo.getValue('platformUserRoleInfos') ?? [], (info: VL) => {
    manageSpaces.push({
      'type': 'manager',
      'role': info.roleName,
      'title': '平台管理空间',
    });
  });

  _.forEach(userInfo.getValue('schoolRoleInfos'), (info: VL) => {
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

/**
 * pinyin比较函数
 */
export const compareByPinyin = (a: string, b: string) => {
  return pinyin(a, { toneType: 'none' }).localeCompare(
    pinyin(b, { toneType: 'none' }),
  );
};

/**
 * 按比较函数进行排序
 */
export const sortByPinyin = (data: Array<never>, path: string) => {
  return data.sort((a, b): number => {
    return compareByPinyin(_.get(a, path, ''), _.get(b, path, ''));
  });
};

/**
 * 双重排序，先根据loginName，再根据学校名排序
 */
export const getLoginAccounts =
  (accounts: Array<never>, school_code: number | string) => {
    const rows = sortByPinyin(
      _.sortBy(accounts, 'loginName'),
      'school.displayName',
    );
    return _.filter(rows, (item: Record<string, Record<string, string>>) => item.school.code === school_code)
  };

/**
 * 阅读密码规则
 */
export const passwordRules = (password: string) => {
  if (password.length < 6) {
    CustomToast.toast_fail('阅读密码不能小于6个字符');
    return false;
  }
  if (password.length > 20) {
    CustomToast.toast_fail('阅读密码不能超过20个字符');
    return false;
  }
  const regPassword = /^[^\s]*$/;
  if (!regPassword.test(password)) {
    CustomToast.toast_fail('禁止输入空格');
    return false;
  }
  return true;
}