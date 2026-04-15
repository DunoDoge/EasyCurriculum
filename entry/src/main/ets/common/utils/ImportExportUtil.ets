import { fileIo as fs } from '@kit.CoreFileKit';
import { picker } from '@kit.CoreFileKit';
import { pasteboard } from '@kit.BasicServicesKit';
import { Context } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { Timetable } from '../../model/CourseModel';
import { Logger } from './Logger';

export class ImportExportUtil {
  /**
   * 导出课表为JSON文件，使用DocumentViewPicker让用户选择保存位置
   */
  static async exportToFile(context: Context, timetable: Timetable): Promise<boolean> {
    try {
      let jsonStr = ImportExportUtil.timetableToJsonString(timetable);
      let fileName = timetable.name + '_课表.json';

      // 先写入临时文件，再通过Picker让用户选择保存位置
      let tempDir = context.tempDir;
      let tempPath = tempDir + '/' + fileName;
      let file = fs.openSync(tempPath, fs.OpenMode.CREATE | fs.OpenMode.TRUNC | fs.OpenMode.READ_WRITE);
      fs.writeSync(file.fd, jsonStr);
      fs.closeSync(file);

      let documentSaveOptions = new picker.DocumentSaveOptions();
      documentSaveOptions.newFileNames = [fileName];
      let documentViewPicker = new picker.DocumentViewPicker(context);
      let uris = await documentViewPicker.save(documentSaveOptions);

      if (uris !== undefined && uris.length > 0) {
        let destUri = uris[0];
        // 将临时文件内容复制到用户选择的位置
        let srcFile = fs.openSync(tempPath, fs.OpenMode.READ_ONLY);
        let destFile = fs.openSync(destUri, fs.OpenMode.WRITE_ONLY | fs.OpenMode.TRUNC);
        let bufferSize = 4096;
        let buf = new ArrayBuffer(bufferSize);
        let readLen = fs.readSync(srcFile.fd, buf);
        while (readLen > 0) {
          fs.writeSync(destFile.fd, buf, { length: readLen });
          readLen = fs.readSync(srcFile.fd, buf);
        }
        fs.closeSync(srcFile);
        fs.closeSync(destFile);

        // 删除临时文件
        fs.unlinkSync(tempPath);
        Logger.info('Export to file success: ' + destUri);
        return true;
      } else {
        // 用户取消选择，删除临时文件
        fs.unlinkSync(tempPath);
        Logger.info('Export to file cancelled by user');
        return false;
      }
    } catch (err) {
      let error = err as Error;
      Logger.error('Export to file failed: ' + error.message);
      return false;
    }
  }

  /**
   * 从文件导入课表，使用DocumentViewPicker让用户选择文件
   */
  static async importFromFile(context: Context): Promise<Timetable | null> {
    try {
      let documentSelectOptions = new picker.DocumentSelectOptions();
      let documentViewPicker = new picker.DocumentViewPicker(context);
      let uris = await documentViewPicker.select(documentSelectOptions);

      if (uris !== undefined && uris.length > 0) {
        let srcUri = uris[0];
        let file = fs.openSync(srcUri, fs.OpenMode.READ_ONLY);
        let stat = fs.statSync(srcUri);
        let fileSize = stat.size;
        let buf = new ArrayBuffer(fileSize);
        let readLen = fs.readSync(file.fd, buf);
        fs.closeSync(file);

        let textDecoder = util.TextDecoder.create('utf-8');
        let jsonStr = textDecoder.decodeToString(new Uint8Array(buf, 0, readLen));

        let timetable = ImportExportUtil.jsonStringToTimetable(jsonStr);
        if (timetable !== null) {
          Logger.info('Import from file success, courses: ' + timetable.courses.length);
        }
        return timetable;
      } else {
        Logger.info('Import from file cancelled by user');
        return null;
      }
    } catch (err) {
      let error = err as Error;
      Logger.error('Import from file failed: ' + error.message);
      return null;
    }
  }

  /**
   * 导出课表到剪贴板
   */
  static async exportToClipboard(context: Context, timetable: Timetable): Promise<boolean> {
    try {
      let jsonStr = ImportExportUtil.timetableToJsonString(timetable);
      let pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, jsonStr);
      let systemPasteboard = pasteboard.getSystemPasteboard();
      await systemPasteboard.setData(pasteData);
      Logger.info('Export to clipboard success');
      return true;
    } catch (err) {
      let error = err as Error;
      Logger.error('Export to clipboard failed: ' + error.message);
      return false;
    }
  }

  /**
   * 从剪贴板导入课表
   */
  static async importFromClipboard(context: Context): Promise<Timetable | null> {
    try {
      let systemPasteboard = pasteboard.getSystemPasteboard();
      let pasteData = await systemPasteboard.getData();
      if (pasteData === undefined || pasteData === null) {
        Logger.warn('Clipboard is empty');
        return null;
      }
      let jsonStr = pasteData.getPrimaryText();
      if (jsonStr === undefined || jsonStr === null || jsonStr === '') {
        Logger.warn('Clipboard content is not text');
        return null;
      }
      let timetable = ImportExportUtil.jsonStringToTimetable(jsonStr);
      if (timetable !== null) {
        Logger.info('Import from clipboard success, courses: ' + timetable.courses.length);
      }
      return timetable;
    } catch (err) {
      let error = err as Error;
      Logger.error('Import from clipboard failed: ' + error.message);
      return null;
    }
  }

  /**
   * 将Timetable序列化为JSON字符串
   */
  static timetableToJsonString(timetable: Timetable): string {
    let jsonObj = timetable.toJson();
    // 添加版本标识，方便后续兼容
    let exportObj: Record<string, Object> = {
      'version': 1,
      'app': 'EasyCurriculum',
      'timetable': jsonObj
    } as Record<string, Object>;
    return JSON.stringify(exportObj);
  }

  /**
   * 将JSON字符串反序列化为Timetable
   */
  static jsonStringToTimetable(jsonStr: string): Timetable | null {
    try {
      let jsonObj: Record<string, Object> = JSON.parse(jsonStr) as Record<string, Object>;

      // 检查是否为带版本标识的导出格式
      if (jsonObj['version'] !== undefined && jsonObj['timetable'] !== undefined) {
        let timetableJson = jsonObj['timetable'] as Record<string, Object>;
        return Timetable.fromJson(timetableJson);
      }

      // 尝试直接作为Timetable对象解析
      if (jsonObj['id'] !== undefined && jsonObj['courses'] !== undefined) {
        return Timetable.fromJson(jsonObj);
      }

      // 尝试作为Timetable数组解析（取第一个）
      if (Array.isArray(jsonObj)) {
        let jsonArray = jsonObj as Record<string, Object>[];
        if (jsonArray.length > 0) {
          return Timetable.fromJson(jsonArray[0]);
        }
      }

      Logger.error('Invalid import data format');
      return null;
    } catch (err) {
      let error = err as Error;
      Logger.error('Parse JSON failed: ' + error.message);
      return null;
    }
  }
}
