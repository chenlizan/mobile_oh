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