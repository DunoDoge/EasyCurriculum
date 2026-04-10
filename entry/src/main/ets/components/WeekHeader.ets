import { getWeekDayList, getWeekDayName, WeekDay } from '../model/WeekDay';
import { Constants } from '../common/constants/Constants';

@Component
export struct WeekHeader {
  @Prop currentWeek: number = 1;
  @Prop semesterStartDate: string = '';
  @Prop monthOfWeek: number = 0;
  onDateClick: (weekDay: number) => void = (_weekDay: number) => {};

  private getDayDate(weekDay: number): string {
    if (this.semesterStartDate === '') {
      return '';
    }
    let parts: string[] = this.semesterStartDate.split('-');
    let year: number = Number(parts[0]);
    let month: number = Number(parts[1]) - 1;
    let day: number = Number(parts[2]);
    let startDate: Date = new Date(year, month, day);
    let offsetDays: number = (this.currentWeek - 1) * 7 + (weekDay - 1);
    let targetDate: Date = new Date(startDate.getTime() + offsetDays * 24 * 60 * 60 * 1000);
    let targetDay: number = targetDate.getDate();
    return targetDay.toString();
  }

  private isToday(weekDay: number): boolean {
    if (this.semesterStartDate === '') {
      return false;
    }
    let parts: string[] = this.semesterStartDate.split('-');
    let year: number = Number(parts[0]);
    let month: number = Number(parts[1]) - 1;
    let day: number = Number(parts[2]);
    let startDate: Date = new Date(year, month, day);
    let offsetDays: number = (this.currentWeek - 1) * 7 + (weekDay - 1);
    let targetDate: Date = new Date(startDate.getTime() + offsetDays * 24 * 60 * 60 * 1000);
    let today: Date = new Date();
    return targetDate.getFullYear() === today.getFullYear() &&
      today.getMonth() === targetDate.getMonth() &&
      today.getDate() === targetDate.getDate();
  }

  build() {
    Row() {
      Column() {
        if (this.semesterStartDate !== '') {
          Text(this.monthOfWeek.toString())
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
          Text('月')
            .fontSize(10)
            .fontColor('#999999')
            .margin({ top: 2 })
        }
      }
      .width(Constants.TIME_HEADER_WIDTH)
      .height(Constants.HEADER_HEIGHT + 16)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      ForEach(getWeekDayList(), (day: WeekDay) => {
        Column() {
          Text(getWeekDayName(day))
            .fontSize(14)
            .fontWeight(this.isToday(day as number) ? FontWeight.Bold : FontWeight.Medium)
            .fontColor(this.isToday(day as number) ? '#4CAF50' : '#333333')
          if (this.semesterStartDate !== '') {
            Text(this.getDayDate(day as number))
              .fontSize(10)
              .fontWeight(this.isToday(day as number) ? FontWeight.Bold : FontWeight.Medium)
              .fontColor(this.isToday(day as number) ? '#4CAF50' : '#999999')
              .margin({ top: 2 })
          }
        }
        .layoutWeight(1)
        .height(Constants.HEADER_HEIGHT + 16)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          this.onDateClick(day as number);
        })
      }, (day: WeekDay) => day.toString())
    }
    .width('100%')
  }
}
