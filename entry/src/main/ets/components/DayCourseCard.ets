import { CourseInfo } from '../model/CourseModel';
import { Constants } from '../common/constants/Constants';

@Component
export struct DayCourseCard {
  @ObjectLink course: CourseInfo;
  onCardClick: (course: CourseInfo) => void = () => {};

  private DAY_CARD_HEIGHT: number = 80;
  private TIME_AXIS_WIDTH: number = 56;

  build() {
    Row() {
      // 左侧时间轴
      Column() {
        Text(Constants.SLOT_TIMES[this.course.startSlot])
          .fontSize(12)
          .fontColor('#666666')
          .fontWeight(FontWeight.Medium)

        Text(Constants.SLOT_TIMES[this.course.endSlot])
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 4 })
      }
      .width(this.TIME_AXIS_WIDTH)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      // 课程色竖线
      Column() {}
        .width(3)
        .height('100%')
        .backgroundColor(this.course.color)
        .borderRadius(2)
        .margin({ left: 3, right: 8 })

      // 课程信息卡片（白色背景+左侧课程色条）
      Row() {
        // 左侧课程色条
        Column() {}
          .width(4)
          .height('100%')
          .backgroundColor(this.course.color)
          .borderRadius({ topLeft: 4, bottomLeft: 4 })

        // 右侧内容
        Column() {
          Text(this.course.name)
            .fontSize(16)
            .fontColor('#333333')
            .fontWeight(FontWeight.Bold)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')

          Row() {
            Text('第' + this.course.startSlot + '-' + this.course.endSlot + '节')
              .fontSize(12)
              .fontColor('#666666')

          }
          .width('100%')
          .margin({ top: 4 })

          Row() {
            if (this.course.location !== '') {
              Text('@' + this.course.location)
                .fontSize(12)
                .fontColor('#666666')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .layoutWeight(1)
            } else {
              Blank()
                .layoutWeight(1)
            }

            if (this.course.teacher !== '') {
              Text(this.course.teacher)
                .fontSize(12)
                .fontColor('#999999')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .margin({ left: 8 })
            }
          }
          .width('100%')
          .margin({ top: 4 })
        }
        .layoutWeight(1)
        .height('100%')
        .padding({ left: 10, right: 12, top: 8, bottom: 8 })
        .justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .height('100%')
      .borderRadius(8)
      .backgroundColor(Color.White)
      .shadow({ radius: 2, color: '#1A000000', offsetY: 1 })
    }
    .width('100%')
    .height(this.DAY_CARD_HEIGHT)
    .margin({ bottom: 8 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.onCardClick(this.course);
    })
  }
}
