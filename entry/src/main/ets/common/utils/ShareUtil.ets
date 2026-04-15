import { systemShare } from '@kit.ShareKit';
import { fileIo as fs, fileUri, fileShare } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { Logger } from './Logger';

export class ShareUtil {
  /**
   * 分享图片
   * @param context 应用上下文
   * @param imageUri 图片文件URI（沙箱内file://路径）
   * @returns Promise<boolean> 分享是否成功启动
   */
  static async shareImage(context: common.UIAbilityContext, imageUri: string): Promise<boolean> {
    try {
      // 将沙箱路径转为可跨应用访问的URI
      let shareableUri = ShareUtil.toShareableUri(imageUri);

      // 授权其他应用读取该文件
      await ShareUtil.grantReadPermission(shareableUri);

      let record: systemShare.SharedRecord = {
        utd: 'general.image',
        uri: shareableUri
      };
      let sharedData: systemShare.SharedData = new systemShare.SharedData(record);

      let shareController: systemShare.ShareController = new systemShare.ShareController(sharedData);
      let options: systemShare.ShareControllerOptions = {};

      // 在分享面板关闭后清理临时文件和权限
      shareController.on('dismiss', () => {
        ShareUtil.revokePermission(shareableUri);
        ShareUtil.cleanupTempFile(imageUri);
        Logger.info('Share panel dismissed, cleaned up: ' + imageUri);
      });

      await shareController.show(context, options);
      Logger.info('Share image panel shown: ' + shareableUri);
      return true;
    } catch (err) {
      let error = err as Error;
      Logger.error('Share image failed: ' + error.message);
      return false;
    }
  }

  /**
   * 分享文件
   * @param context 应用上下文
   * @param fileUri 文件URI（沙箱内file://路径）
   * @returns Promise<boolean> 分享是否成功启动
   */
  static async shareFile(context: common.UIAbilityContext, fileUri: string): Promise<boolean> {
    try {
      // 将沙箱路径转为可跨应用访问的URI
      let shareableUri = ShareUtil.toShareableUri(fileUri);

      // 授权其他应用读取该文件
      await ShareUtil.grantReadPermission(shareableUri);

      let record: systemShare.SharedRecord = {
        utd: 'general.file',
        uri: shareableUri
      };
      let sharedData: systemShare.SharedData = new systemShare.SharedData(record);

      let shareController: systemShare.ShareController = new systemShare.ShareController(sharedData);
      let options: systemShare.ShareControllerOptions = {};

      // 在分享面板关闭后清理临时文件和权限
      shareController.on('dismiss', () => {
        ShareUtil.revokePermission(shareableUri);
        ShareUtil.cleanupTempFile(fileUri);
        Logger.info('Share panel dismissed, cleaned up: ' + fileUri);
      });

      await shareController.show(context, options);
      Logger.info('Share file panel shown: ' + shareableUri);
      return true;
    } catch (err) {
      let error = err as Error;
      Logger.error('Share file failed: ' + error.message);
      return false;
    }
  }

  /**
   * 将沙箱内file://路径转为可跨应用访问的URI
   * @param fileUri 沙箱内文件URI（file://开头）
   * @returns 可跨应用访问的URI
   */
  static toShareableUri(sandboxFileUri: string): string {
    let filePath = sandboxFileUri.replace('file://', '');
    let shareableUri = fileUri.getUriFromPath(filePath);
    Logger.info('Convert to shareable URI: ' + sandboxFileUri + ' -> ' + shareableUri);
    return shareableUri;
  }

  /**
   * 授权其他应用读取该文件URI
   * @param uri 可跨应用访问的文件URI
   */
  static async grantReadPermission(uri: string): Promise<void> {
    try {
      let policyInfo: fileShare.PolicyInfo = {
        uri: uri,
        operationMode: fileShare.OperationMode.READ_MODE
      };
      await fileShare.persistPermission([policyInfo]);
      Logger.info('Grant read permission success: ' + uri);
    } catch (err) {
      let error = err as Error;
      Logger.warn('Grant read permission failed: ' + error.message);
    }
  }

  /**
   * 撤销文件URI的读取权限
   * @param uri 可跨应用访问的文件URI
   */
  static revokePermission(uri: string): void {
    try {
      let policyInfo: fileShare.PolicyInfo = {
        uri: uri,
        operationMode: fileShare.OperationMode.READ_MODE
      };
      fileShare.revokePermission([policyInfo]).then(() => {
        Logger.info('Revoke permission success: ' + uri);
      }).catch((err: Error) => {
        Logger.warn('Revoke permission failed: ' + err.message);
      });
    } catch (err) {
      let error = err as Error;
      Logger.warn('Revoke permission call failed: ' + error.message);
    }
  }

  /**
   * 保存数据到临时文件
   * @param context 应用上下文
   * @param data 文件数据（字符串或ArrayBuffer）
   * @param fileName 文件名
   * @returns Promise<string> 临时文件URI（沙箱内file://路径）
   */
  static async saveToTempFile(context: common.UIAbilityContext, data: string | ArrayBuffer, fileName: string): Promise<string> {
    let tempDir = context.tempDir;
    let tempPath = tempDir + '/' + fileName;

    let file = fs.openSync(tempPath, fs.OpenMode.CREATE | fs.OpenMode.TRUNC | fs.OpenMode.READ_WRITE);

    if (typeof data === 'string') {
      let textEncoder = util.TextEncoder.create('utf-8');
      let encodedData = textEncoder.encodeInto(data);
      fs.writeSync(file.fd, encodedData.buffer);
    } else {
      fs.writeSync(file.fd, data);
    }

    fs.closeSync(file);

    let resultUri = 'file://' + tempPath;
    Logger.info('Save to temp file: ' + resultUri);
    return resultUri;
  }

  /**
   * 清理临时文件
   * @param fileUri 文件URI（沙箱内file://路径）
   */
  static cleanupTempFile(fileUri: string): void {
    try {
      let filePath = fileUri.replace('file://', '');
      fs.unlinkSync(filePath);
      Logger.info('Cleanup temp file: ' + filePath);
    } catch (err) {
      let error = err as Error;
      Logger.warn('Cleanup temp file failed: ' + error.message);
    }
  }
}
