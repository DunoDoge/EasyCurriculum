import { componentSnapshot } from '@kit.ArkUI';
import { image } from '@kit.ImageKit';
import { display } from '@kit.ArkUI';
import { Logger } from './Logger';

export class LongScreenshotUtil {
  private static readonly MAX_SEGMENTS: number = 20;

  static async captureLongScreenshot(
    componentId: string,
    scroller: Scroller,
    delayMs: number = 300
  ): Promise<image.PixelMap | null> {
    try {
      scroller.scrollEdge(Edge.Top);
      await LongScreenshotUtil.sleep(delayMs);

      let firstPm = await componentSnapshot.get(componentId, { waitUntilRenderFinished: true });
      let firstInfo = firstPm.getImageInfoSync();
      let viewWidth = firstInfo.size.width;
      let viewHeightPx = firstInfo.size.height;

      let disp = display.getDefaultDisplaySync();
      let density = disp.densityPixels;
      let viewHeightVp = viewHeightPx / density;

      let segments: image.PixelMap[] = [firstPm];
      let scrollOffsetsPx: number[] = [0];

      let segmentCount = 1;
      while (!scroller.isAtEnd() && segmentCount < LongScreenshotUtil.MAX_SEGMENTS) {
        scroller.scrollBy(0, viewHeightVp);
        await LongScreenshotUtil.sleep(delayMs);

        let currentOffsetVp = scroller.currentOffset().yOffset;
        let currentOffsetPx = Math.round(currentOffsetVp * density);

        let pm = await componentSnapshot.get(componentId, { waitUntilRenderFinished: true });
        segments.push(pm);
        scrollOffsetsPx.push(currentOffsetPx);
        segmentCount++;
      }

      if (segments.length === 1) {
        return firstPm;
      }

      let lastOffsetPx = scrollOffsetsPx[scrollOffsetsPx.length - 1];
      let totalHeight = lastOffsetPx + viewHeightPx;

      let bufferSize = viewWidth * totalHeight * 4;
      let targetBuffer = new ArrayBuffer(bufferSize);
      let targetView = new Uint8Array(targetBuffer);
      for (let i = 0; i < bufferSize; i += 4) {
        targetView[i] = 0xFF;
        targetView[i + 1] = 0xFF;
        targetView[i + 2] = 0xFF;
        targetView[i + 3] = 0xFF;
      }

      for (let i = 0; i < segments.length; i++) {
        let info = segments[i].getImageInfoSync();
        let segWidth = info.size.width;
        let segHeight = info.size.height;
        let startY = scrollOffsetsPx[i];

        let segBuffer = new ArrayBuffer(segWidth * segHeight * 4);
        segments[i].readPixelsToBufferSync(segBuffer);
        let segView = new Uint8Array(segBuffer);

        let skipRows = 0;
        if (i > 0) {
          let prevEndY = scrollOffsetsPx[i - 1] + viewHeightPx;
          skipRows = Math.max(0, prevEndY - startY);
        }

        for (let row = skipRows; row < segHeight; row++) {
          if (startY + row >= totalHeight) break;
          let srcOffset = row * segWidth * 4;
          let dstOffset = (startY + row) * viewWidth * 4;
          let copyLength = Math.min(segWidth, viewWidth) * 4;
          for (let col = 0; col < copyLength; col++) {
            targetView[dstOffset + col] = segView[srcOffset + col];
          }
        }

        segments[i].release();
      }

      let targetPm = image.createPixelMapSync(targetBuffer, {
        size: { width: viewWidth, height: totalHeight },
        pixelFormat: image.PixelMapFormat.RGBA_8888,
        alphaType: image.AlphaType.UNPREMUL
      });

      return targetPm;
    } catch (err) {
      let error = err as Error;
      Logger.error('Long screenshot failed: ' + error.message);
      return null;
    }
  }

  static sleep(ms: number): Promise<void> {
    return new Promise<void>((resolve) => {
      setTimeout(() => {
        resolve();
      }, ms);
    });
  }
}
