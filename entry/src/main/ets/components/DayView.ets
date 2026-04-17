import { CourseInfo } from '../model/CourseModel';
import { WeekDay, getWeekDayName } from '../model/WeekDay';
import { Constants } from '../common/constants/Constants';
import { CourseViewModel, CourseSlotDisplay } from '../viewmodel/CourseViewModel';
import { DayCourseCard } from './DayCourseCard';

@ComponentV2
export struct DayView {
  @Param selectedWeekDay: number = 1;
  @Param currentWeek: number = 1;
  @Require @Param viewModel: CourseViewModel;
  @Param onBack: () => void = () => {};
  @Param onCourseClick: (course: CourseInfo) => void = () => {};
  @Param onSlotClick: (slot: number) => void = () => {};
  @Param onSwipePrev: () => void = () => {};
  @Param onSwipeNext: () => void = () => {};
  @Param scroller: Scroller = new Scroller();

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
      Scroll(this.scroller) {
        Column() {
          ForEach(this.viewModel.getCourseSlotsByDay(this.selectedWeekDay), (csd: CourseSlotDisplay) => {
            DayCourseCard({
              course: csd.course,
              displayStartSlot: csd.timeSlot.startSlot,
              displayEndSlot: csd.timeSlot.endSlot,
              displayTeacher: csd.timeSlot.teacher,
              displayLocation: csd.timeSlot.location,
              onCardClick: (clickedCourse: CourseInfo) => {
                this.onCourseClick(clickedCourse);
              }
            })
          }, (csd: CourseSlotDisplay, index: number) => csd.course.id + '_' + index.toString() + '_v' + this.viewModel.dataVersion.toString())
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
      .align(Alignment.Top)
      .id('dayScrollForShare')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
    .id('dayViewForShare')
    .parallelGesture(
      PanGesture({ fingers: 1, direction: PanDirection.Horizontal, distance: 50 })
        .onActionEnd((event: GestureEvent) => {
          if (event.offsetX < -Constants.SWIPE_THRESHOLD) {
            this.onSwipeNext();
          } else if (event.offsetX > Constants.SWIPE_THRESHOLD) {
            this.onSwipePrev();
          }
        })
    )
  }
}
