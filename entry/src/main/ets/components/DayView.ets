import { CourseInfo } from '../model/CourseModel';
import { WeekDay, getWeekDayName } from '../model/WeekDay';
import { Constants } from '../common/constants/Constants';
import { CourseViewModel } from '../viewmodel/CourseViewModel';
import { DayCourseCard } from './DayCourseCard';

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
      // 顶部标题栏
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

      // 课程列表区域
      Scroll() {
        Column() {
          ForEach(this.viewModel.getCoursesByDay(this.selectedWeekDay), (course: CourseInfo) => {
            DayCourseCard({
              course: course,
              onCardClick: (clickedCourse: CourseInfo) => {
                this.onCourseClick(clickedCourse);
              }
            })
          }, (course: CourseInfo) => course.id)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
