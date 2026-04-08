import { Constants } from '../common/constants/Constants';

@Component
export struct TimeSlotHeader {
  build() {
    Column() {
      ForEach(Array.from({ length: Constants.TOTAL_SLOTS }, (_v: Object, k: number) => k + 1), (slot: number) => {
        Column() {
          Text(slot.toString())
            .fontSize(12)
            .fontColor('#666666')
            .fontWeight(FontWeight.Medium)

          Text(Constants.SLOT_TIMES[slot])
            .fontSize(8)
            .fontColor('#999999')
            .margin({ top: 2 })
        }
        .width(Constants.TIME_HEADER_WIDTH)
        .height(Constants.SLOT_HEIGHT)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }, (slot: number) => slot.toString())
    }
    .width(Constants.TIME_HEADER_WIDTH)
  }
}
