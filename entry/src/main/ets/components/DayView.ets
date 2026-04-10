import { CourseInfo } from '../model/CourseModel';
import { WeekDay, getWeekDayName } from '../model/WeekDay';
import { Constants } from '../common/constants/Constants';
import { CourseViewModel } from '../viewmodel/CourseViewModel';
import { CourseCard } from './CourseCard';
import { TimeSlotHeader } from './TimeSlotHeader';

@Component
export struct DayView {
  @Prop selectedWeekDay: number = 1;
  @Prop currentWeek: number = 1;
  @ObjectLink viewModel: CourseViewModel;
  onBack: () => void = () => {};
  onCourseClick: (course: CourseInfo) => void = () => {};
  onSlotClick: (slot: number) => void = () => {};

  build() {
    Column() {
      Row() {
        Text('←')
          .fontSize(22)
          .fontColor('#333333')
          .fontWeight(FontWeight.Bold)
          .onClick(() => {
            this.onBack();
          })

        Text(this.viewModel.getDayFullDate() + ' 周' + getWeekDayName(this.selectedWeekDay as WeekDay))
          .fontSize(18)
          .fontColor('#333333')
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Text('←')
          .fontSize(22)
          .fontColor(Color.Transparent)
      }
      .width('100%')
      .height(Constants.HEADER_HEIGHT)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)

      Scroll() {
        Row() {
          TimeSlotHeader()

          Stack() {
            Column() {
              ForEach(Array.from({ length: Constants.TOTAL_SLOTS }, (_v: Object, k: number) => k + 1), (slot: number) => {
                Column() {}
                  .width('100%')
                  .height(Constants.SLOT_HEIGHT)
                  .borderWidth(0.5)
                  .borderColor('#E0E0E0')
                  .backgroundColor(Color.White)
                  .onClick(() => {
                    if (this.viewModel.getCourseAtSlot(this.selectedWeekDay, slot) === undefined) {
                      this.onSlotClick(slot);
                    }
                  })
              }, (slot: number) => slot.toString())
            }

            ForEach(this.viewModel.getCoursesByDay(this.selectedWeekDay), (course: CourseInfo) => {
              CourseCard({
                course: course,
                onCardClick: (clickedCourse: CourseInfo) => {
                  this.onCourseClick(clickedCourse);
                }
              })
            }, (course: CourseInfo) => course.id)
          }
          .layoutWeight(1)
          .height(Constants.TOTAL_SLOTS * Constants.SLOT_HEIGHT)
          .clip(false)
        }
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
