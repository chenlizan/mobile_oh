import { common } from '@kit.AbilityKit';
import { fileIo, picker } from '@kit.CoreFileKit';
import { request } from '@kit.BasicServicesKit';
import { CustomToast } from '../components/CustomToast';

export async function DownloadUtil(url: string, filename: string) {
  try {
    const context = getContext() as common.UIAbilityContext;
    const filesDir = context.filesDir;
    const filePath = filesDir + '/' + filename

    if (fileIo.accessSync(filePath)) {
      fileIo.unlinkSync(filePath)
    }

    const downloadTask: request.DownloadTask = await request.downloadFile(context, {
      url: url,
      filePath: filePath
    });

    await new Promise<void>((resolve, reject) => {
      downloadTask.on('complete', () => resolve());
      downloadTask.on('fail', (err) => reject(err));
    });

    const stat = fileIo.statSync(filePath);
    const arrayBuffer = new ArrayBuffer(stat.size);

    const file_s = fileIo.openSync(filePath, fileIo.OpenMode.READ_ONLY);
    fileIo.readSync(file_s.fd, arrayBuffer);

    const documentSaveOptions = new picker.DocumentSaveOptions();
    documentSaveOptions.newFileNames = [filename];

    const documentPicker = new picker.DocumentViewPicker();
    const documentSelectResult = await documentPicker.save(documentSaveOptions);

    const uri = documentSelectResult[0];
    const file_d = fileIo.openSync(uri, fileIo.OpenMode.READ_WRITE);

    fileIo.writeSync(file_d.fd, arrayBuffer);

    CustomToast.toast_success('下载成功');
  } catch (error) {
    CustomToast.toast_success('下载失败' + error.message);
  }
}