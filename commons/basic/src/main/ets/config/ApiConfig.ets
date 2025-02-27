interface InterfaceIMApi {
  querySign: string;
  queryToken: string;
  getChatC2CHistoryMsg: string;
  importAccount: string;
}

export const IMApi: InterfaceIMApi = {
  querySign: 'message/tim/usersig',
  queryToken: 'im/account/token',
  getChatC2CHistoryMsg: 'im/single_chat/history',
  importAccount: 'im/account/import',
};

interface InterfaceMessageApi {
  updateMsgStatus: string;
  queryTodoNotices: string;
  queryCourseNotices: string;
  queryCourseTaskNotices: string;
  queryCourseAnnoNotices: string;
  queryCourseSubgroupNotices: string;
  queryCourseDiscussNotices: string;
  queryCourseAreaNotices: string;
  queryPersonalNotices: string;
  querySystemNotices: string;
  delMessage: string;
  delSelectedMsg: string;
  msgUnReadCount: string;
  msgUnReadTipCount: string;
  msgSetting: string;
  verifyCloneSite: string;
  verifyFriend: string;
  mergeSiteVerify: string;
  msgGuideRecord: string;
  remoteControlAction: string;
  getChatContactGroup: string;
  getChatContactFriend: string;
  getChatContactGroupMember: string;
}

export const MessageApi: InterfaceMessageApi = {
  updateMsgStatus: 'message/im/updateStatus',
  queryTodoNotices: 'message/im/todo',
  queryCourseNotices: 'message/im/group',
  queryCourseTaskNotices: 'message/im/task_notice',
  queryCourseAnnoNotices: 'message/im/announcement',
  queryCourseSubgroupNotices: 'message/im/subgroup',
  queryCourseDiscussNotices: 'message/im/discussion',
  queryCourseAreaNotices: 'message/im/qa',
  queryPersonalNotices: 'message/im/personal',
  querySystemNotices: 'message/im/system',
  delMessage: 'message/im/user/',
  delSelectedMsg: 'message/im/selected/empty',
  msgUnReadCount: 'message/im/un_read_count',
  msgUnReadTipCount: 'message/im/tip/un_read_count',
  msgSetting: 'message/im/setting',
  verifyCloneSite: 'group/verifyCloneSite',
  verifyFriend: 'friend/verify',
  mergeSiteVerify: 'site/mergeSiteVerify',
  msgGuideRecord: 'auth/user/guide/record',
  remoteControlAction: 'message/im/remote_control/action',
  getChatContactGroup: 'chat/contact/group',
  getChatContactFriend: 'chat/contact/friend',
  getChatContactGroupMember: 'chat/contact/group/member',
};

interface InterfaceCCApi {
  unifiedCheckInfraLogin: string;
  refreshToken: string;
  logout: string;
  getSchoolList: string;
  getDomainList: string;
  getTermList: string;
  findBackPassword: string;
  queryDesEncryptKey: string;
  freeRegister: string;
  verifyPhoneCode: string;
  modifyPassword: string;
  gainSchoolId: string;
  getUserInfo: string;
  userCheckRealnameByAT: string;
  appActivationByAT: string;
  queryUserInfoUnionAccountsByAT: string;
  userUpdate: string;
  changePassword: string;
  queryUserSchoolInfo: string;
  deleteUserSchool: string;
  applyUserSchool: string;
  queryUserApplyIngSchool: string;
  queryRoleStuAndTeaList: string;
  getDepartmentList: string;
  getDepartmentTree: string;
  updateUserSchool: string;
  currentUserBindPhone: string;
  scanLoginCodeConfirm: string;
  scanLoginSendIndCode: string;
  queryInfraUserInfo: string;
  infraChangeMobile: string;
  infraPreChangeMobile: string;
  infraSendMobileCode: string;
  infraDismissMobile: string;
  updatePasswordByCode: string;
  queryUserInfoUnionAccounts: string;
  queryUserInfoUnionAccountsByPhone: string;
  sysFeedback: string;
  generateSignUpload: string;
  oss: string;
  groupCollect: string;
  syncSiteMemberData: string;
  querySiteDynamicMenuList: string;
  queryOneUserDynamicMenuList: string;
  querySiteStuStatusList: string;
  blindStuStatus: string;
  checkImportUnifiedAuth: string;
  refreshVideoRecord: string;
  queryVideoRecordList: string;
  getVideoRecordUrlById: string;
  getGroupMemberInfo: string;
  getVideoConfig: string;
  getSiteCertificate: string;

  // 发现
  getDiscoverLikeList: string;
  getDiscoverList: string;
  getDiscoverPage: string;
  checkSiteEnshrineSite: string;
  getSiteCountNum: string;
  getCoursePropertyList: string;
  getBeforeCurrentTerm: string;
  getSiteCourseThemeList: string;

  // 督导
  getSupervisorSiteLive: string;
  getSupervisorStatistics: string;
  getCurrentTerm: string;
  getSupervisorIdeaPage: string;
  getSiteGeneralData: string;
  getResourceSiteGeneralData: string;
  getSupervisorActivityBySiteId: string;
  getSupervisorTemplateBySiteId: string;
  supervisorResult: string;
  ossSeeSignUrl: string;
  getSupervisorSiteCount: string;

  // 优质课程评审
  getCourseAssessBatchInfoListBySiteId: string;
  getCourseAssessBatchSiteApplyBatchInfo: string;
  getCourseAssessActivityDetail: string;
  reviewCommitRecord: string;
  getCourseAssessStatisticsData: string;
  getCourseAssessBatchInfoListByUserId: string;
  getCourseAssessPageSite: string;
  getCourseAssessPageSiteCount: string;
  getCourseAssessList: string;
  getCourseAssessBatchList: string;
  getCourseAssessLevelList: string;
  getCourseAssessResult: string;
  applyCourseAssess: string;

  // 学生评教
  getEvaluationActiveList: string;
  saveEvaluationResult: string;
  submitEvaluationResult: string;
  getEvaluationResult: string;
  getBeEvaluationActiveList: string;

  // common
  getSpecialTemplateRecordPage: string;
  deleteSpecialTemplateRecord: string;
  querySpecialTemplateRecordDetail: string;
}

export const CCApi: InterfaceCCApi = {
  unifiedCheckInfraLogin: 'user/unifiedCheckInfraLogin', // 登录
  refreshToken: 'user/refreshToken', // 刷新 token
  logout: 'user/outLoginCurrent', // 注销
  getSchoolList: 'base/school/list',
  getDomainList: 'base/domain/list',
  getTermList: 'base/term/list',
  findBackPassword: 'user/findBackPassword',
  queryDesEncryptKey: 'user/keyStr',
  freeRegister: 'user/freeRegister',
  verifyPhoneCode: 'user/verifyPhoneCode',
  modifyPassword: 'user/modifyPasswordNoOld',
  gainSchoolId: 'base/school/gainSchoolId', // 获取部署配置
  getUserInfo: 'user/currentUserInfo', // 获取用户信息
  userCheckRealnameByAT: 'user/userCheckRealnameByAT', // 根据认证token验证真实姓名
  appActivationByAT: 'user/appActivationByAT', // 根据认证token激活账号，即修改密码
  queryUserInfoUnionAccountsByAT: 'user/queryUserInfoUnionAccountsByAT', // 根据认证token查询关联账号
  userUpdate: 'user/update', // 更新用户信息 头像-昵称
  changePassword: 'user/change/password', // 修改密码
  queryUserSchoolInfo: 'userSchool/queryUserSchoolInfo', // 查询用户绑定学校信息
  deleteUserSchool: 'userSchool/deleteUserSchool', // 删除用户绑定学校信息
  applyUserSchool: 'userSchool/applyUserSchool', // 用户申请加入学校
  queryUserApplyIngSchool: 'userSchool/queryUserApplyIngSchool', // 查询用户已申请等待处理学校记录
  queryRoleStuAndTeaList: 'user/roleStuAndTeaList', // 获取学生教师身份列表
  getDepartmentList: 'base/department/list', // 查询部门列表
  getDepartmentTree: 'base/department/tree', // 获取部门树形结构数据
  updateUserSchool: 'userSchool/updateUserSchool', // 用户编辑绑定学校的登录名和部门信息
  currentUserBindPhone: 'user/currentUserBindPhone', // 初次绑定手机号
  scanLoginCodeConfirm: 'user/scanLoginCodeConfirm', // 扫码成功确认
  scanLoginSendIndCode: 'user/scanLoginSendIndCode', // 扫码登录发送识别码
  queryInfraUserInfo: 'user/queryInfraUserInfo', // 教学个人中心根据authId查询手机号、绑定qq、绑定微信
  infraChangeMobile: 'user/infraChangeMobile', // 更换手机
  infraPreChangeMobile: 'user/infraPreChangeMobile', // 更换手机预检查信息
  infraSendMobileCode: 'user/infraSendMobileCode', // 获取修改手机的验证码
  infraDismissMobile: 'user/infraDismissMobile', // 解绑手机号
  updatePasswordByCode: 'user/updatePasswordByCode', // 找回密码
  queryUserInfoUnionAccounts: 'user/queryUserInfoUnionAccounts', // 查询当前账号的用户关联账号信息
  queryUserInfoUnionAccountsByPhone: 'user/queryUserInfoUnionAccountsByPhone', // 通过手机号查询关联账户信息
  sysFeedback: 'sysFeedback/', // 用户反馈
  generateSignUpload: 'oss/generateSignUpload',
  oss: 'oss/',
  groupCollect: 'xySite/enshrine', // 收藏
  syncSiteMemberData: 'xySite/bc/sendSiteMemberData', // 补偿发送卡夫卡成员数据
  querySiteDynamicMenuList: 'siteDynamicMenu/queryOneSiteDynamicMenuList', // 课程设置管理
  queryOneUserDynamicMenuList: 'siteDynamicMenu/queryOneUserDynamicMenuList', // 用户设置管理
  querySiteStuStatusList: 'siteDynamicMenu/siteStuStatusList', // 查询课程内教师设置学生可以使用功能列表
  blindStuStatus: 'siteDynamicMenu/blindStuStatus', // 教师配置课程内学生端功能是否学生可见
  checkImportUnifiedAuth: 'user/checkImportUnifiedAuth', // 统一身份认证验证
  refreshVideoRecord: 'videoRecord/refreshList', // 前台刷新录播视频数据
  queryVideoRecordList: 'videoRecord/queryVideoList', // 翻页查询录播数据
  getVideoRecordUrlById: 'videoRecord/forPreSeeUrlByResourceId', // 根据id获取预览地址
  getGroupMemberInfo: 'xySite/member/oneAny', // 查询某个课程成员数据
  getVideoConfig: 'videoRecord/getVideoConfig', // 获取实例下所有学校录播设置
  getSiteCertificate: 'siteCertificate/listForMore', // 获取多个课程空间认证结果

  // 发现
  getDiscoverLikeList: 'site/hkPage', // 好课推荐
  getDiscoverList: 'site/courseCenterPage', // 发现课程
  getDiscoverPage: 'site/page', // 课程筛选
  checkSiteEnshrineSite: 'xySite/checkSiteEnshrineSite', // 收藏判断
  getSiteCountNum: 'xySite/mySiteCountNum',
  getCoursePropertyList: 'dic/coursePropertyList', // 课程属性
  getBeforeCurrentTerm: 'base/term/beforeCurrentTerm', // 之前学期
  getSiteCourseThemeList: 'siteCourseTheme/list', // 课程专题

  // 督导
  getSupervisorSiteLive: 'supervisor/awyVideo/getSupervisorSiteLive', // 根据条件查询督导直播以及未在直播课程列表
  getSupervisorStatistics: 'supervisor/statistics/course/num', // 查询督导员督导课堂总数，已督导课堂总数，未督导课堂总数
  getCurrentTerm: 'base/term/getCurrentTerm', // 当前学期
  getSupervisorIdeaPage: 'supervisor/course/supervisorResult/page', // 分页查询督导课程结果列表
  getSiteGeneralData: 'siteUseConstruct/site/generalData', // 课程空间建设情况
  getResourceSiteGeneralData: 'resource/site/generalData', // 课程资源情况
  getSupervisorActivityBySiteId:
  'supervisor/course/getSupervisorActivityBySiteId', // 根据课程空间查询参与的督导活动
  getSupervisorTemplateBySiteId:
  'supervisor/course/getSupervisorTemplateBySiteId', // 获取课程空间的督导模板
  supervisorResult: 'supervisor/course/supervisorResult', // 添加、编辑督导课程结果
  ossSeeSignUrl: 'oss/seeSignUrl', // 浏览
  getSupervisorSiteCount: 'supervisor/awyVideo/getSupervisorSiteCount', // 督导课程数量

  // 优质课程评审
  getCourseAssessBatchInfoListBySiteId:
  'courseAssessActivityManage/assessSpace/batchInfoListBySiteId', // 根据siteID获取参与的正在进行的或者历史的批次信息列表
  getCourseAssessBatchSiteApplyBatchInfo:
  'courseAssessActivityManage/assessSpace/siteApplyBatchInfo', //获取批次详情
  getCourseAssessActivityDetail: 'courseAssessActivityResult/system/detailById', //根据批次id查询金课评审保存结果 以及模板
  reviewCommitRecord: 'ddpspj/template/commitRecord', //保存或提交数据
  getCourseAssessStatisticsData:
  'courseAssessActivityManage/assessSpace/statisticsData', //根据评审专家用户信息获取评审空间概要数据
  getCourseAssessBatchInfoListByUserId:
  'courseAssessActivityManage/assessSpace/batchInfoListByUserId', //根据评审专家信息获取其参与的正在或者历史的批次信息
  getCourseAssessPageSite: 'courseAssessActivityManage/assessSpace/pageSite', //获取批次下评审专家评审课程
  getCourseAssessPageSiteCount:
  'courseAssessActivityManage/assessSpace/batchSiteStatistics', // 翻页批次下评审专家评审课程统计
  getCourseAssessList: 'courseAssessActivity/list', // 查询活动列表
  getCourseAssessBatchList: 'courseAssessActivityBatch/batch/list', // 根据活动ID获取正在进行的批次列表
  getCourseAssessLevelList: 'courseAssessActivity/level/list', // 获取活动等级列表
  getCourseAssessResult: 'courseAssessActivityManage/getAssessResult', // 获取该课程在活动中获取的评审所有已有结果
  applyCourseAssess: 'courseAssessActivityManage/apply', // 申请参与活动批次

  // 学生评教
  getEvaluationActiveList: 'evaluation/participation/activity/list', // 查询参与评价者的评价活动列表
  saveEvaluationResult: 'evaluation/saveParticipationEvaluationResult', // 保存参评者结果
  submitEvaluationResult: 'evaluation/submitParticipationEvaluationResult', // 提交参与评价者的评价活动结果
  getEvaluationResult: 'evaluation/getParticipationEvaluationResult', // 查询参评者评价结果
  getBeEvaluationActiveList: 'evaluation/evaluatedUserId/activity/list', // 查询被评者的评价活动列表

  // common
  getSpecialTemplateRecordPage: 'ddpspj/template/record/page', // 分页查询课程结果列表
  deleteSpecialTemplateRecord: 'ddpspj/template/record/delete', // 批量删除课程结果列表
  querySpecialTemplateRecordDetail: 'ddpspj/template/queryRecordDetail', // 查询某条记录详情
};

interface InterfaceSystemApi {
  systemNotices: string;
  checkUpdate: string;
  diskFiles: string;
  authStore: string;
  setDocumentKey: string;
  removeDocumentKey: string;
  updateDocumentKey: string;
  resetDocumentKey: string;
  avatarSetting: string;
  latestAvatar: string;
  validText: string;
  buriedTrack: string;
}

export const SystemApi: InterfaceSystemApi = {
  systemNotices: 'notice/queryUrgentNoticeList',
  checkUpdate: 'ta_node/version',
  diskFiles: 'disk/files',
  authStore: 'auth/store', // 用户配置
  setDocumentKey: 'auth/user/node_key',
  removeDocumentKey: 'auth/user/remove_node_key',
  updateDocumentKey: 'auth/user/upd_node_key',
  resetDocumentKey: 'auth/user/reset_node_key',
  avatarSetting: 'auth/user/avatar/setting',
  latestAvatar: 'auth/user/latest/avatar',
  validText: 'group/green/scan_text',
  buriedTrack: 'lrp/track', // 前端埋点
};

interface InterfaceMineApi {
  groupResourcePersonal: string;
  groupPersonal: string;
  groupResourcePersonalFilesize: string;
  kgPersonal: string;
  evaluationPersonal: string;
  qbPersonal: string;
  thirdToolPersonal: string;
  sharedPersonal: string;
  collectionPersonal: string;
}

export const MineApi: InterfaceMineApi = {
  groupResourcePersonal: 'group/resource/personal',
  groupPersonal: 'group/personal',
  groupResourcePersonalFilesize: 'group/resource/personalFilesize',
  kgPersonal: 'kg/personal',
  evaluationPersonal: 'evaluation_scale/personal',
  qbPersonal: 'qb/personal',
  thirdToolPersonal: 'thirdTool/queryThirdToolByAuthorId',
  sharedPersonal: 'ta_node/shared/personal',
  collectionPersonal: 'ta_node/collection/personal',
};

interface InterfaceHomeApi {
  homeStat: string;
  taskUnCheck: string;
  taskUnFinish: string;
  taskUnFinishMark: string;
  homeRecentTask: string;
  groupBySiteId: string;
  groupConfig: string;
  configSearch: string;
  queryDeepThinkModel: string;

  // group
  groupQr: string;
  queryStudentGroups: string;
  queryTeacherGroups: string;
  groupVisits: string;
  queryGroup: string;
  queryJoinedGroups: string;
  deleteGroup: string;
  quitGroup: string;
  addGroup: string;
  updateGroup: string;
  updateGroupTheme: string;
  joinGroup: string;
  joinGroupNoVerify: string;
  queryGroupCollects: string;
  groupFiledSetting: string;
  groupEndSetting: string;
  groupApplication: string;
  queryGroupAccessAuth: string;
  groupResourceAutoPublic: string;
  groupResourceAllPublic: string;

  // class
  groupClass: string;
  groupClassList: string;
  groupClassMember: string;
  memberMoveToClass: string;
  muteMember: string;

  // learn
  learnRecord: string;
  queryResourceLearnTotal: string;
  queryResourceStudyLearn: string;
  queryResourceEveryStudy: string;
  queryStudentResourceStudyLearn: string;
  queryVisitorResourceStudyLearn: string;

  // setting
  queryOutlineByGroup: string;
  courseOutlineUpdate: string;
  publishOutline: string;
  groupVisit: string;
  queryAnnouncementList: string;
  putAnnouncement: string;
  addAnnouncement: string;

  // active
  queryNotices: string;

  // resource
  queryCourseResources: string;
  publicResources: string;
  addResource: string;
  updateResource: string;
  moveResource: string;
  sortResource: string;
  classResourceInfo: string;
  queryResourceStatus: string;
  copyResource: string;
  importResource: string;
  delResource: string;
  queryPaper: string;
  queryCourseTrends: string;
  getActivityTags: string;
  recordResourceHistory: string;
  getResourceRecordHistory: string;
  getResourceByQrcode: string;
  getResourceKnowledge: string;
  getSurveyKnowledgeBind: string;
  getResourceBindTag: string;
  updateResourceAttribute: string;
  checkSurveyScore: string;
  getRemoteControlPage: string;

  // member
  queryMembers: string;
  updateMember: string;
  updateRole: string;
  deleteMember: string;
  groupVerify: string;
  getGroupApply: string;
  inviteMember: string;
  verifyInvite: string;
  groupVerifyAll: string;
  groupMemberVerifyInviteBatch: string;
  groupChangeCreator: string;
  querySubgroupMemberDetail: string;
  queryMemberApplyInfo: string;

  // task
  finishActivity: string;
  queryTaskNotices: string;
  publishDiscussionTask: string;
  publishSurveyTask: string;
  publishWatchTask: string;
  addPublishRecord: string;
  updatePublishRecord: string;
  revokePublishRecord: string;
  updatePublishRecordBasic: string;
  updatePublishTime: string;
  updatePublishRecordAssign: string;
  updateMark: string;
  courseSurveyTaskFlow: string;
  queryDistributeMarkRecords: string;
  fastEndTask: string;
  checkVodTaskStatus: string;
  queryTaskDetails: string;
  queryStudentFinishInfo: string;
  querySharedAnswerRecords: string;

  // classroom
  openCourse: string;
  closeCourse: string;
  joinCourse: string;
  leaveCourse: string;
  getOpenCourse: string;
  studentRushAnswer: string;
  cancelRushAnswer: string;
  registerSign: string;
  registerSignCode: string;
  registerFast: string;
  switchCourseSync: string;
  switchCourseFolder: string;
  playCourseware: string;
  updateCourseware: string;
  queryCourseOnlineUsers: string;
  queryCourseClassOnlineUsers: string;
  querySubgroupOnlineUsers: string;
  pickCourseStudent: string;
  pickCoursePassing: string;
  pickRandomNumber: string;
  pickCourseNormal: string;
  pickCourseRandom: string;
  closePickStudent: string;
  updateCourseEvaluate: string;
  updatePickEvaluate: string;
  pickCourseRandomSubgroup: string;
  pickEvaluate: string;
  registerOpen: string;
  registerClose: string;
  registerSetting: string;
  registerSigning: string;
  registerQRCode: string;
  queryRegisterCode: string;
  courseRegisterList: string;
  getCourseRegisterDetail: string;
  openRushAnswer: string;
  getRushNormalHistory: string;
  getRushEvaluationList: string;
  openRushThemeActivity: string;
  getRushThemeHistory: string;
  getRushActiveTheme: string;
  getRushThemeEvaluation: string;
  restartRushTheme: string;
  closeRushAnswer: string;
  stopRushAnswer: string;
  closeRushThemeActivity: string;
  stopRushThemeActivity: string;
  getRushStuThemeList: string;
  getCourseRushAnswerDetail: string;
  registerStatusChange: string;
  getRegisterStudentStatus: string;
  getRegisterStudent: string;
  getRegisterStatusCount: string;
  registerDetail: string;
  registerEvent: string;
  registerStudent: string;
  openRaiseHand: string;
  closeRaiseHand: string;
  selectRaiseHand: string;
  raiseHandList: string;
  courseEvaluate: string;
  checkRushAnsStart: string;
  studentStartRaiseHand: string;
  studentEndRaiseHand: string;
  checkRaiseHandStart: string;
  raiseHandChange: string;
  toolUse: string;
  getCourseAnalysisList: string;

  // appraise
  queryEvaActivities: string;
  updateEvaluationPublish: string;
  evaluationStart: string;
  evaluationEnd: string;
  evaluationRevoke: string;
  evaluationDel: string;
  queryEvaJudgedByMe: string;
  queryEvaJudgedToMe: string;

  // subgroup
  querySubgroupSchema: string;
  querySubgroupSchemaFree: string;
  querySubgroupGroup: string;
  addSubgroupSchema: string;
  delSubgroupSchema: string;
  updateSubgroupSchema: string;
  addSubgroup: string;
  setSubgroupLeader: string;
  delSubgroupGroup: string;
  updateSubgroupGroup: string;
  querySubgroupTaskNotices: string;
  moveSubgroupMember: string;
  removeSubgroupMember: string;

  // sub member
  querySubgroupMembers: string;
  delSubgroupMember: string;
  addSubgroupMember: string;
  queryMembsersNotInSubgroupSchema: string;

  // sub resource
  querySubgroupNodes: string;
  delSubgroupResource: string;
  updateSubgroupResource: string;
  shareSubgroupResource: string;
  querySubgroupSharedResource: string;
  moveSubgroupResource: string;
  addSubgroupResource: string;
  importSubgroupResource: string;
  subgroupResourceCopy: string;
  subgroupResourceInfo: string;

  // note
  queryNode: string;
  queryNodeAnyway: string;
  queryNodeShared: string;

  // 文件
  cloudFileUrl: string;

  // video
  video_vod: string;
  video_auth: string;
  video_record: string;
  uploadVideoDuration: string;
  video_auth_vod: string;
  video_auth_vod_refresh: string;
  video_geo_ip: string;

  // reflect
  queryMyRethink: string;
  queryGroupRethink: string;

  // document
  documentsOperation: string;
  updateDocument: string;
  moveDocument: string;
  queryDocumentCollections: string;
  updateDocumentCollection: string;
  queryDocumentTags: string;
  delTrashDocument: string;
  trashDocument: string;
  trashDocumentTo: string;
  addDocument: string;
  copyDocument: string;
  lockDocument: string;
  createDocumentTag: string;
  shareDocument: string;
  updateDocumentTag: string;
  copyDocumentTo: string;
  sharedNodeInfo: string;

  // recommend
  resourceRecommend: string;
  gradeStudentTip: string;
  groupTeachingTip: string;

  // MOOC
  queryMoocMembers: string;
  queryMoocTaskDetails: string;
}

export const HomeApi: InterfaceHomeApi = {
  homeStat: 'statistics/mobile/homeStat',
  taskUnCheck: 'group/task/un_check',
  taskUnFinish: 'group/task/un_finish',
  taskUnFinishMark: 'group/task/student/unfinished',
  homeRecentTask: 'group/taskNotices',
  groupBySiteId: 'group/site_id',
  groupConfig: 'config',
  configSearch: 'config/search',
  queryDeepThinkModel: 'assistant/deepthinkmodel',
  // group
  groupQr: 'group/qr',
  queryStudentGroups: 'group/student/groups',
  queryTeacherGroups: 'group/teacher/groups',
  groupVisits: 'group/myVisited',
  queryGroup: 'group/queryGroup',
  queryJoinedGroups: 'group/joined',
  deleteGroup: 'group/delGroup',
  quitGroup: 'group/quitGroup',
  addGroup: 'group/addGroup',
  updateGroup: 'group/updateGroup',
  updateGroupTheme: 'group/customInfo',
  joinGroup: 'group/joinGroup',
  joinGroupNoVerify: 'group/joinGroupNoVerify',
  queryGroupCollects: 'group/myCollect',
  groupFiledSetting: 'group/filed/setting',
  groupEndSetting: 'group/end/setting',
  groupApplication: 'group/application',
  queryGroupAccessAuth: 'group/access/authorization',
  groupResourceAutoPublic: 'group/resource/auto_public',
  groupResourceAllPublic: 'group/resource/all_public',
  // class
  groupClass: 'group/class',
  groupClassList: 'group/class/list',
  groupClassMember: 'group/class/member',
  memberMoveToClass: 'group/member/to_class',
  muteMember: 'group/banMembers',
  // learn
  learnRecord: 'learnLength/learnRecord',
  queryResourceLearnTotal: 'learn_length/resource/total',
  queryResourceStudyLearn: 'learn_length/resource/student',
  queryResourceEveryStudy: 'ads/duration/resource',
  queryStudentResourceStudyLearn: 'learn_length/student/resources',
  queryVisitorResourceStudyLearn: 'learn_length/visitor/resources',
  // setting
  queryOutlineByGroup: 'courseOutline/queryByGroup',
  courseOutlineUpdate: 'courseOutline/update',
  publishOutline: 'group/announcement',
  groupVisit: 'statistics/group/visit',
  queryAnnouncementList: 'group/announcement/list',
  putAnnouncement: 'group/announcement',
  addAnnouncement: 'group/announcement/v2',
  // active
  queryNotices: 'notice/queryNotices',
  // resource
  queryCourseResources: 'resource/queryCourseResources',
  publicResources: 'resource/publicResources',
  addResource: 'resource/addResource',
  updateResource: 'resource/updateResource',
  moveResource: 'resource/moveResource',
  sortResource: 'resource/sortNode',
  classResourceInfo: 'resource/queryResource',
  queryResourceStatus: 'resource/queryStatus',
  copyResource: 'resource/group/copy',
  importResource: 'resource/group/import',
  delResource: 'resource/delResource',
  queryPaper: 'survey/queryPaper',
  queryCourseTrends: 'group/trends',
  getActivityTags: 'resource/activityTags',
  recordResourceHistory: 'resource/history/user/view',
  getResourceRecordHistory: 'resource/history/user/view',
  getResourceByQrcode: 'resource/qrcode/permission',
  getResourceKnowledge: 'graphs/kg/group/knowledge/bind',
  getSurveyKnowledgeBind: 'survey/knowledge/questions',
  getResourceBindTag: 'graphs/kg/group/label/bind',
  updateResourceAttribute: 'resource/batch/update/attribute',
  checkSurveyScore: 'survey/question/score/check',
  getRemoteControlPage: 'auth/user/be_control_page',
  // member
  queryMembers: 'group/queryMembers',
  updateMember: 'group/updateMember',
  updateRole: 'group/updateRole',
  deleteMember: 'group/delMember',
  groupVerify: 'group/verify',
  getGroupApply: 'message/im/group/apply',
  inviteMember: 'group/invite',
  verifyInvite: 'group/verifyInvite',
  groupVerifyAll: 'group/member/verify_invite/all',
  groupMemberVerifyInviteBatch: 'group/member/verify_invite/batch',
  groupChangeCreator: 'group/member/changecreator',
  querySubgroupMemberDetail: 'subgroup/querySubgroupMemberDetail',
  queryMemberApplyInfo: 'group/member/apply/info',
  // task
  finishActivity: 'resource/finishActivity',
  queryTaskNotices: 'group/task/queryTaskNotices',
  publishDiscussionTask: 'task/publish/discussion',
  publishSurveyTask: 'task/publish/survey',
  publishWatchTask: 'task/publish/watch',
  addPublishRecord: 'resource/addPublishRecord',
  updatePublishRecord: 'resource/updatePublishRecord',
  revokePublishRecord: 'resource/revokePublishRecord',
  updatePublishRecordBasic: 'resource/task/paper/updatePublishRecordBasic',
  updatePublishTime: 'task/start_end_time',
  updatePublishRecordAssign: 'resource/task/paper/updatePublishRecordAssign',
  updateMark: 'resource/task/paper/updateMark',
  courseSurveyTaskFlow: 'survey/course/task/flow',
  queryDistributeMarkRecords: 'survey/course/queryDistributeMarkRecords',
  fastEndTask: 'resource/task/end',
  checkVodTaskStatus: 'vod/checkTaskStatus',
  queryTaskDetails: 'group/task/queryTaskDetails',
  queryStudentFinishInfo: 'resource/task/studenFinishInfo',
  querySharedAnswerRecords: 'survey/course/querySharedAnswerRecords',
  // classroom
  openCourse: 'course/openCourse',
  closeCourse: 'course/closeCourse',
  joinCourse: 'course/joinCourse',
  leaveCourse: 'course/leaveCourse',
  getOpenCourse: 'course/getOpenCourse',
  studentRushAnswer: 'course/studentRushAnswer',
  cancelRushAnswer: 'course/rush_answer/cancel',
  registerSign: 'register/sign',
  registerSignCode: 'register/sign/code',
  registerFast: 'register/one_click/check_in',
  switchCourseSync: 'course/switch_course_sync',
  switchCourseFolder: 'course/switchFolder',
  playCourseware: 'course/playCourseware', // 播放课件
  updateCourseware: 'course/updateCourseware', // 完成授课
  queryCourseOnlineUsers: 'course/queryCourseOnlineUsers',
  queryCourseClassOnlineUsers: 'course/queryCourseClassOnlineUsers',
  querySubgroupOnlineUsers: 'subgroup/online/members',
  pickCourseStudent: 'course/pickStudent',
  pickCoursePassing: 'course/pickPassing',
  pickRandomNumber: 'course/pickRandomNumber',
  pickCourseNormal: 'course/normal/pick',
  pickCourseRandom: 'course/random/pick',
  closePickStudent: 'course/closePickStudent',
  updateCourseEvaluate: 'course/updateEvaluate',
  updatePickEvaluate: 'course/updatePickEvaluate',
  pickCourseRandomSubgroup: 'course/random/subgroup/pick',
  pickEvaluate: '/course/pickEvaluate',
  registerOpen: 'register/open',
  registerClose: 'register/close',
  registerSetting: 'register/setting',
  registerSigning: 'register/signing',
  registerQRCode: 'register/QRCode',
  queryRegisterCode: 'register/code',
  courseRegisterList: 'course/register/list',
  getCourseRegisterDetail: 'course/getCourseRegisterDetail',
  openRushAnswer: 'course/openRushAnswer',
  getRushNormalHistory: 'course/rush_answer/normal/opened/list',
  getRushEvaluationList: 'course/rush_answer/theme/evaluation',
  openRushThemeActivity: 'course/openRushThemeActivity',
  getRushThemeHistory: 'course/rush_answer/theme/opened/list',
  getRushActiveTheme: 'course/rush_answer/themes',
  getRushThemeEvaluation: 'course/rush_answer/theme/evaluation',
  restartRushTheme: 'course/rush_answer/theme/restart',
  closeRushAnswer: 'course/closeRushAnswer',
  stopRushAnswer: 'course/stopRushAnswer',
  closeRushThemeActivity: 'course/closeRushThemeActivity',
  stopRushThemeActivity: 'course/stopRushThemeActivity',
  getRushStuThemeList: 'course/rush_answer/themes',
  getCourseRushAnswerDetail: 'course/getCourseRushAnswerDetail',
  registerStatusChange: 'register/status/change',
  getRegisterStudentStatus: 'register/student/status',
  getRegisterStudent: 'register/one/student',
  getRegisterStatusCount: 'register/status/count',
  registerDetail: 'register/detail',
  registerEvent: 'register/event',
  registerStudent: 'register/student',
  openRaiseHand: 'course/raise_hand/start',
  closeRaiseHand: 'course/raise_hand/end',
  selectRaiseHand: 'course/raise_hand/select',
  raiseHandList: 'course/raise_hand/list',
  courseEvaluate: 'course/evaluate',
  checkRushAnsStart: 'course/rush_answer/reopen',
  studentStartRaiseHand: 'course/student/start/raise_hand',
  studentEndRaiseHand: 'course/student/end/raise_hand',
  checkRaiseHandStart: 'course/raise_hand/one/ongoing',
  raiseHandChange: 'course/raise_hand/change',
  toolUse: 'course/tool_use',
  getCourseAnalysisList: 'courseAnalysis/list',
  // appraise
  queryEvaActivities: 'evaluation/queryEvaActivities',
  updateEvaluationPublish: 'evaluation/updatePublish',
  evaluationStart: 'evaluation/start',
  evaluationEnd: 'evaluation/end',
  evaluationRevoke: 'evaluation/revoke',
  evaluationDel: 'evaluation/del',
  queryEvaJudgedByMe: 'evaluation/student/queryEvaJudgedByMe',
  queryEvaJudgedToMe: 'evaluation/student/queryEvaJudgedToMe',
  // subgroup
  querySubgroupSchema: 'subgroup/querySubgroupSchema',
  querySubgroupSchemaFree: 'subgroup/schema/free',
  querySubgroupGroup: 'subgroup/querySubgroupGroup',
  addSubgroupSchema: 'subgroup/addSubgroupSchema',
  delSubgroupSchema: 'subgroup/delSubgroupSchema',
  updateSubgroupSchema: 'subgroup/updateSubgroupSchema',
  addSubgroup: 'subgroup/addSubgroup',
  setSubgroupLeader: 'subgroup/member/leader',
  delSubgroupGroup: 'subgroup/delSubgroupGroup',
  updateSubgroupGroup: 'subgroup/updateSubgroupGroup',
  querySubgroupTaskNotices: 'group/task/querySubgroupTaskNotices',
  moveSubgroupMember: 'subgroup/member/move',
  removeSubgroupMember: 'subgroup/member/remove',
  // sub member
  querySubgroupMembers: 'subgroup/member/queryMembers',
  delSubgroupMember: 'subgroup/member/delMember',
  addSubgroupMember: 'subgroup/member/addMember',
  queryMembsersNotInSubgroupSchema: 'subgroup/queryMembsersNotInSubgroupSchema',
  // sub resource
  querySubgroupNodes: 'subgroup/resource/queryNodes',
  delSubgroupResource: 'subgroup/resource/delResource',
  updateSubgroupResource: 'subgroup/resource/updateResource',
  shareSubgroupResource: 'subgroup/resource/share',
  querySubgroupSharedResource: 'subgroup/resource/querySharedResource',
  moveSubgroupResource: 'subgroup/resource/moveResource',
  addSubgroupResource: 'subgroup/resource/addResource',
  importSubgroupResource: 'subgroup/resource/import',
  subgroupResourceCopy: 'subgroup/resource/copy',
  subgroupResourceInfo: 'subgroup/resource/queryResource',
  // note
  queryNode: 'ta_node/queryNode',
  queryNodeAnyway: 'ta_node/queryNodeAnyway',
  queryNodeShared: 'ta_node/shared/resource',
  // 文件
  cloudFileUrl: 'cloud/file_url/',
  // video
  video_vod: 'vod/video/',
  video_auth: 'vod/video/play_auth/',
  video_record: 'vod/duration/',
  uploadVideoDuration: 'vod/duration/',
  video_auth_vod: 'vod/video/auth',
  video_auth_vod_refresh: 'vod/video/auth/refresh',
  video_geo_ip: 'vod/geo_ip/country',
  // reflect
  queryMyRethink: 'resource/myRethink',
  queryGroupRethink: 'resource/groupRethink',
  // document
  documentsOperation: 'ta_node/nodes',
  updateDocument: 'ta_node/updateNode',
  moveDocument: 'ta_node/position/parent',
  queryDocumentCollections: 'ta_node/collections',
  updateDocumentCollection: 'ta_node/collection',
  queryDocumentTags: 'tags/all',
  delTrashDocument: 'ta_node/delTrash',
  trashDocument: 'ta_node/trash',
  trashDocumentTo: 'ta_node/trash/new',
  addDocument: 'ta_node/addNode',
  copyDocument: 'resource/ta_node/copy',
  lockDocument: 'ta_node/nodes/lock',
  createDocumentTag: 'ta_node/tag',
  shareDocument: 'ta_node/share',
  updateDocumentTag: 'tags/tag',
  copyDocumentTo: 'ta_node/copyNode',
  sharedNodeInfo: 'ta_node/shared',
  // recommend
  resourceRecommend: 'resource/recommend',
  gradeStudentTip: 'grade/student/tip',
  groupTeachingTip: 'group/teaching/tip',

  // MOOC
  queryMoocMembers: 'group/mooc/queryMembers',
  queryMoocTaskDetails: 'group/task/mooc/queryTaskDetails',
};
