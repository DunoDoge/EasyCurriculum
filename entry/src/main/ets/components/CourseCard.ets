import { CourseInfo } from '../model/CourseModel';
import { Constants } from '../common/constants/Constants';

@ComponentV2
export struct CourseCard {
  @Require @Param course: CourseInfo;
  @Param displayStartSlot: number = 0;
  @Param displayEndSlot: number = 0;
  @Param displayTeacher: string = '';
  @Param displayLocation: string = '';
  @Param onCardClick: (course: CourseInfo) => void = () => {};

  private getEffectiveStartSlot(): number {
    return this.displayStartSlot > 0 ? this.displayStartSlot : this.course.startSlot;
  }

  private getEffectiveEndSlot(): number {
    return this.displayEndSlot > 0 ? this.displayEndSlot : this.course.endSlot;
  }

  private getEffectiveLocation(): string {
    return this.displayLocation !== '' ? this.displayLocation : this.course.location;
  }

  private getEffectiveTeacher(): string {
    return this.displayTeacher !== '' ? this.displayTeacher : this.course.teacher;
  }

  private getSlotSpan(): number {
    return this.getEffectiveEndSlot() - this.getEffectiveStartSlot() + 1;
  }

  build() {
    Column() {
      Column() {
        Text(this.course.name)
          .fontSize(12)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
          .maxLines(this.getSlotSpan() === 1 ? 2 : 3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Text('@' + this.getEffectiveLocation())
          .fontSize(10)
          .fontColor(Color.White)
          .opacity(0.9)
          .maxLines(this.getSlotSpan() <= 2 ? 2 : 3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .margin({ top: 2 })

        if (this.getEffectiveTeacher() !== '') {
          Text(this.getEffectiveTeacher())
            .fontSize(10)
            .fontColor(Color.White)
            .opacity(0.8)
            .maxLines(this.getSlotSpan() <= 2 ? 1 : 2)
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
    .height(this.getSlotSpan() * Constants.SLOT_HEIGHT)
    .padding({ left: 2, right: 2 })
    .position({ x: 0, y: (this.getEffectiveStartSlot() - 1) * Constants.SLOT_HEIGHT })
    .clip(false)
    .onClick(() => {
      this.onCardClick(this.course);
    })
  }
}
