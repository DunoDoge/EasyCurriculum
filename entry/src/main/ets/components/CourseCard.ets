import { CourseInfo } from '../model/CourseModel';
import { Constants } from '../common/constants/Constants';

@Component
export struct CourseCard {
  @ObjectLink course: CourseInfo;
  onCardClick: (course: CourseInfo) => void = () => {};

  build() {
    Column() {
      Column() {
        Text(this.course.name)
          .fontSize(12)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
          .maxLines(this.course.endSlot - this.course.startSlot + 1 === 1 ? 2 : 3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Text('@' + this.course.location)
          .fontSize(10)
          .fontColor(Color.White)
          .opacity(0.9)
          .maxLines(this.course.endSlot - this.course.startSlot + 1 <= 2 ? 2 : 3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .margin({ top: 2 })

        if (this.course.teacher !== '') {
          Text(this.course.teacher)
            .fontSize(10)
            .fontColor(Color.White)
            .opacity(0.8)
            .maxLines(this.course.endSlot - this.course.startSlot + 1 <= 2 ? 1 : 2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
            .margin({ top: 2 })
        }
      }
      .width('100%')
      .height('100%')
      .padding(Constants.COURSE_CARD_PADDING)
      .borderRadius(Constants.COURSE_CARD_RADIUS)
      .backgroundColor(this.course.color)
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height((this.course.endSlot - this.course.startSlot + 1) * Constants.SLOT_HEIGHT)
    .padding({ left: 2, right: 2 })
    .position({ x: 0, y: (this.course.startSlot - 1) * Constants.SLOT_HEIGHT })
    .clip(false)
    .onClick(() => {
      this.onCardClick(this.course);
    })
  }
}
