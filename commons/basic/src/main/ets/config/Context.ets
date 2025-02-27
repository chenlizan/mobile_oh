interface BaseApi {
  baseApi_IM: string;
  baseApi: string;
  ccApi: string;
  ccApi_datacenter: string;
  ccApi_common: string;
  base_homepage: string;
  baseApi_inner: string;
  baseApi_out: string;
  statApi: string;
  base_mobilepage: string;
  managerApi: string;
  lrsApi: string;
  chatApi: string;
  hostApi: string;
  refererApi: string;
}

export class Api_Context {
  /**
   * 是否 测试环境。
   */
  private isTest: boolean = false;
  private api: BaseApi = {
    baseApi_IM: "",
    baseApi: "",
    ccApi: "",
    ccApi_datacenter: "",
    ccApi_common: "",
    base_homepage: "",
    baseApi_inner: "",
    baseApi_out: "",
    statApi: "",
    base_mobilepage: "",
    managerApi: "",
    lrsApi: "",
    chatApi: "",
    hostApi: "",
    refererApi: ""
  }
  private domain: string = ''

  constructor(domain?: string) {
    if (typeof domain === 'string') {
      this.api = this.getBaseApi(this.isTest ? 'tst' : domain) as BaseApi;
      this.domain = domain
    }
  }

  getApiPrefix(key: string) {
    return Reflect.get(this.api, key) as string;
  }

  getOpenApi() {
    return this.isTest
      ? this.isStaging()
        ? 'https://stg-openai.ai-augmented.com/api/v1/chat/completions'
        : 'https://tst-openai.ai-augmented.com/api/v1/chat/completions'
      : 'https://openai.ai-augmented.com/api/v1/chat/completions';
  }

  getAIGlobalConfig() {
    return this.isTest
      ? this.isStaging()
        ? 'https://stg-config.ai-augmented.com/api/v1/config/global'
        : 'https://tst-config.ai-augmented.com/api/v1/config/global'
      : 'https://config.ai-augmented.com/api/v1/config/global';
  }

  getFaqDomain() {
    return this.isTest
      ? this.isStaging()
        ? 'https://stg-faq.ai-augmented.com'
        : 'https://tst-faq.ai-augmented.com'
      : 'https://faq.ai-augmented.com';
  }

  isStaging() {
    return this.domain.indexOf('stg-') > 1
  }

  getUserAgreement() {
    return 'https://www.ai-augmented.com/user-agreement.html';
  }

  getPrivacyPolicy() {
    return 'https://www.ai-augmented.com/privacy-agreement.html';
  }

  getOfficeApi() {
    return 'https://vip.ow365.cn/';
  }

  getIpWhitelist() {
    return 'https://config.ai-augmented.com/api/v1/config/isIpWhitelist';
  }

  getApkDownloadApi() {
    return 'https://www.ai-augmented.com/pages/app-download.html';
  }

  getApplicationConfig() {
    return 'https://catalog.ai-augmented.com/api/application/searchApplicationConfig';
  }

  getApplicationToken() {
    return 'Basic eHlhdXRoX3NlcnZlcjoxeDhkTXNaMDJ6ZzBjN3BLMk9YN0NZVlM=';
  }

  getBaseApi(domain: string): BaseApi {
    return {
      baseApi_IM: `https://${domain}.ai-augmented.com/api/jx-message/`,
      baseApi: `https://${domain}.ai-augmented.com/api/jx-auth/`,
      ccApi: `https://${domain}.ai-augmented.com/api/jw-starcmooc/`,
      ccApi_datacenter: `https://${domain}.ai-augmented.com/api/jw-datacenter/`,
      ccApi_common: `https://${domain}.ai-augmented.com/api/jw-starcmooc/`,
      base_homepage: `https://${domain}.ai-augmented.com/app/jx-web/`,
      baseApi_inner: `https://${domain}.ai-augmented.com/api/jx-iresource/`,
      baseApi_out: `https://${domain}.ai-augmented.com/api/jx-oresource/`,
      statApi: `https://${domain}.ai-augmented.com/api/jx-stat/`,
      base_mobilepage: `https://${domain}.ai-augmented.com/app/jx-mobile/`,
      managerApi: `https://${domain}.ai-augmented.com/api/jw-starcmooc/`,
      lrsApi: `https://${domain}.ai-augmented.com/api/jx-lrs/`,
      chatApi: `https://${domain}.ai-augmented.com/app/jx-chat/`,
      hostApi: `https://${domain}.ai-augmented.com`,
      refererApi: `https://m.${domain}.ai-augmented.com`,
    };
  }
}