export interface Notice {
  id: string
  title: string
  content: string
  endTime: Date
  attachmentInfoList: Record<string, string>[]
}

export class SystemNoticeStorage extends Map<string, Notice[]> {
}