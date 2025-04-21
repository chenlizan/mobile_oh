export class MessageContentType {
  // 待办事项
  static readonly Invite_To_Group: number = 10004
  static readonly Apply_Join_Group: number = 10005
  static readonly Apply_Be_Friend:number =  10008
  static readonly Apply_Clone_Group: number = 10009
  static readonly Apply_Merge_Group:number =  10013
  // 系统消息
  static readonly Join_School_Verdict:number =  50001
  static readonly Split_Group_Verdict: number = 50002
  static readonly Merge_Group_Verdict: number = 50003
  static readonly Clone_Group_Verdict: number = 50004
  static readonly Exit_To_Group:number = 50005
  static readonly Remove_From_Group: number = 50006
  static readonly Group_Role_Change: number = 50007
  static readonly  Course_Stop_Open: number = 50008
  static readonly Download_Package_Verdict: number = 0
  // 课程消息
  static readonly Task_Publish: number = 210001
  static readonly Mark_Mode_Remind:number =  210002
  static readonly Answer_Be_Reject: number = 210003
  static readonly Publish_Evaluation_Activity:number =  210004
  static readonly Task_End_Remind:number =  210005
  static readonly Task_Cancel:number =  210006
  static readonly Task_Update: number = 210007
  static readonly Mark_Distribute_Paper:number =  210008
  static readonly Group_Announcement: number = 220001
  static readonly Subgroup_Publish_Discuss: number = 230001
  static readonly Subgroup_Member_Join: number = 230002
  static readonly Subgroup_Member_Exit: number = 230003
  static readonly Discuss_Be_Top: number = 240001
  static readonly  Discuss_Be_Best:number =  240002
  static readonly  Discuss_Be_Common: number = 240003
  static readonly Discuss_Be_Reply:number =  240004
  static readonly Area_add_Question: number = 250001
  static readonly Area_Be_Answer: number = 250002
  // 个人消息
  static readonly Join_Group_Result: number = 10006
  static readonly  Clone_Group_Result:number =  10010
  static readonly  Merge_Group_Result: number = 10014
  static readonly Review_Group_Result: number = 10015
  static readonly  Be_Friend_Result:number =  10017
  static readonly  User_Reflect_Reply: number = 10018
  static readonly QAArea_Question_Active:number =  0
};