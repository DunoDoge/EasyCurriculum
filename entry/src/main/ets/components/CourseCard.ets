import { CourseInfo } from '../model/CourseModel';
import { Constants } from '../common/constants/Constants';

@Component
export struct CourseCard {
  @Prop course: CourseInfo;
  onCardClick: (course: CourseInfo) => void = () => {};

  build() {
    Column() {
      Text(this.course.name)
        .fontSize(12)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Bold)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      Text('@' + this.course.location)
        .fontSize(10)
        .fontColor(Color.White)
        .opacity(0.9)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .margin({ top: 2 })

      if (this.course.teacher !== '') {
        Text(this.course.teacher)
          .fontSize(10)
          .fontColor(Color.White)
          .opacity(0.8)
          .maxLines(1)
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
    .onClick(() => {
      this.onCardClick(this.course);
    })
  }
}
