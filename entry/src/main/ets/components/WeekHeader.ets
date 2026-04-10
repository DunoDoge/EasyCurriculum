import { getWeekDayList, getWeekDayName, WeekDay } from '../model/WeekDay';
import { Constants } from '../common/constants/Constants';

@Component
export struct WeekHeader {
  currentWeek: number = 1;
  semesterStartDate: string = '';

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
    let targetMonth: number = targetDate.getMonth() + 1;
    let targetDay: number = targetDate.getDate();
    return targetMonth.toString() + '/' + targetDay.toString();
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
      targetDate.getMonth() === today.getMonth() &&
      targetDate.getDate() === today.getDate();
  }

  build() {
    Row() {
      Column() {
        Text('')
          .fontSize(0)
      }
      .width(Constants.TIME_HEADER_WIDTH)
      .height(Constants.HEADER_HEIGHT + 16)

      ForEach(getWeekDayList(), (day: WeekDay) => {
        Column() {
          Text(getWeekDayName(day))
            .fontSize(14)
            .fontWeight(this.isToday(day as number) ? FontWeight.Bold : FontWeight.Medium)
            .fontColor(this.isToday(day as number) ? '#4CAF50' : '#333333')
          if (this.semesterStartDate !== '') {
            Text(this.getDayDate(day as number))
              .fontSize(10)
              .fontColor(this.isToday(day as number) ? '#4CAF50' : '#999999')
              .margin({ top: 2 })
          }
        }
        .layoutWeight(1)
        .height(Constants.HEADER_HEIGHT + 16)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }, (day: WeekDay) => day.toString())
    }
    .width('100%')
  }
}
