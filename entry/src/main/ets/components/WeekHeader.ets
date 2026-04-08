import { getWeekDayList, getWeekDayName, WeekDay } from '../model/WeekDay';
import { Constants } from '../common/constants/Constants';

@Component
export struct WeekHeader {
  build() {
    Row() {
      Column() {
        Text('')
          .fontSize(0)
      }
      .width(Constants.TIME_HEADER_WIDTH)
      .height(Constants.HEADER_HEIGHT)

      ForEach(getWeekDayList(), (day: WeekDay) => {
        Column() {
          Text(getWeekDayName(day))
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
        }
        .layoutWeight(1)
        .height(Constants.HEADER_HEIGHT)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }, (day: WeekDay) => day.toString())
    }
    .width('100%')
  }
}
