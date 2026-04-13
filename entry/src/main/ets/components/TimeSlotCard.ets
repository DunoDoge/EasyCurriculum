import { TimeSlot, WeekType, getWeekTypeName } from '../model/CourseModel';
import { WeekDay, getWeekDayList, getWeekDayName } from '../model/WeekDay';
import { WeekSlotPickerDialog } from './WeekSlotPickerDialog';

@ComponentV2
export struct TimeSlotCard {
  @Require @Param timeSlot: TimeSlot;
  @Param slotIndex: number = 1;
  @Param totalSlotCount: number = 1;
  @Param maxSlotNumber: number = 13;
  @Param maxWeekNumber: number = 20;
  @Local sheetOpen: boolean = false;
  @Local pickerMode: string = 'week';
  @Local editingTeacher: boolean = false;
  @Local editingLocation: boolean = false;
  @Local tempTeacher: string = '';
  @Local tempLocation: string = '';
  @Param onDelete: () => void = () => {};

  @Builder
  PickerSheetBuilder() {
    WeekSlotPickerDialog({
      mode: this.pickerMode,
      maxValue: this.pickerMode === 'week' ? this.maxWeekNumber : this.maxSlotNumber,
      initStartValue: this.pickerMode === 'week' ? this.timeSlot.startWeek : this.timeSlot.startSlot,
      initEndValue: this.pickerMode === 'week' ? this.timeSlot.endWeek : this.timeSlot.endSlot,
      onConfirm: (startValue: number, endValue: number) => {
        if (this.pickerMode === 'week') {
          this.timeSlot.startWeek = startValue;
          this.timeSlot.endWeek = endValue;
        } else {
          this.timeSlot.startSlot = startValue;
          this.timeSlot.endSlot = endValue;
        }
        this.sheetOpen = false;
      },
      onCancel: () => {
        this.sheetOpen = false;
      }
    })
  }

  build() {
    Column() {
      // 标题行：时间段序号 + 删除按钮
      Row() {
        Text('时间段' + this.slotIndex)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)

        if (this.totalSlotCount > 1) {
          Text('🗑️')
            .fontSize(18)
            .onClick(() => {
              this.onDelete();
            })
        }
      }
      .width('100%')
      .padding({ bottom: 12 })

      // 周次和节次信息行
      Row() {
        // 周次信息（点击弹窗）
        Row() {
          Text('📅')
            .fontSize(14)
            .margin({ right: 4 })
          Text('第' + this.timeSlot.startWeek + '-' + this.timeSlot.endWeek + '周')
            .fontSize(15)
            .fontColor('#333333')
        }
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .borderRadius(8)
        .backgroundColor('#F0F0F0')
        .onClick(() => {
          this.pickerMode = 'week';
          this.sheetOpen = true;
        })

        Blank()

        // 节次信息（点击弹窗）
        Row() {
          Text('🕐')
            .fontSize(14)
            .margin({ right: 4 })
          Text('第' + this.timeSlot.startSlot + '-' + this.timeSlot.endSlot + '节')
            .fontSize(15)
            .fontColor('#333333')
        }
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .borderRadius(8)
        .backgroundColor('#F0F0F0')
        .onClick(() => {
          this.pickerMode = 'slot';
          this.sheetOpen = true;
        })
      }
      .width('100%')
      .margin({ bottom: 12 })

      // 星期选择器
      Column() {
        Text('星期')
          .fontSize(13)
          .fontColor('#666666')
          .margin({ bottom: 6 })

        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(getWeekDayList(), (day: WeekDay) => {
            Column() {
              Text(getWeekDayName(day))
                .fontSize(13)
                .fontColor(day === this.timeSlot.weekDay ? Color.White : '#333333')
            }
            .height(32)
            .padding({ left: 10, right: 10 })
            .borderRadius(16)
            .backgroundColor(day === this.timeSlot.weekDay ? '#5B9BD5' : '#F0F0F0')
            .justifyContent(FlexAlign.Center)
            .margin(3)
            .onClick(() => {
              this.timeSlot.weekDay = day;
            })
          }, (day: WeekDay) => 'ts_weekday_' + this.slotIndex.toString() + '_' + day.toString())
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .margin({ bottom: 10 })

      // 周类型选择器
      Column() {
        Text('周类型')
          .fontSize(13)
          .fontColor('#666666')
          .margin({ bottom: 6 })

        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach([WeekType.EVERY_WEEK, WeekType.ODD_WEEK, WeekType.EVEN_WEEK], (type: number) => {
            Column() {
              Text(getWeekTypeName(type))
                .fontSize(13)
                .fontColor(type === this.timeSlot.weekType ? Color.White : '#333333')
            }
            .height(32)
            .padding({ left: 10, right: 10 })
            .borderRadius(16)
            .backgroundColor(type === this.timeSlot.weekType ? '#5B9BD5' : '#F0F0F0')
            .justifyContent(FlexAlign.Center)
            .margin(3)
            .onClick(() => {
              this.timeSlot.weekType = type;
            })
          }, (type: number) => 'ts_weektype_' + this.slotIndex.toString() + '_' + type.toString())
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .margin({ bottom: 10 })

      // 教师行（原地编辑）
      Row() {
        Text('👤')
          .fontSize(14)
          .margin({ right: 6 })

        if (this.editingTeacher) {
          TextInput({ text: this.tempTeacher })
            .fontSize(15)
            .fontColor('#333333')
            .layoutWeight(1)
            .height(36)
            .borderRadius(8)
            .backgroundColor('#F5F5F5')
            .borderWidth(1)
            .borderColor('#5B9BD5')
            .onChange((value: string) => {
              this.tempTeacher = value;
            })
            .onBlur(() => {
              this.timeSlot.teacher = this.tempTeacher;
              this.editingTeacher = false;
            })
        } else {
          Text(this.timeSlot.teacher === '' ? '点击设置教师' : this.timeSlot.teacher)
            .fontSize(15)
            .fontColor(this.timeSlot.teacher === '' ? '#999999' : '#333333')
            .layoutWeight(1)
            .onClick(() => {
              this.tempTeacher = this.timeSlot.teacher;
              this.editingTeacher = true;
            })
        }
      }
      .width('100%')
      .height(40)
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 6 })

      // 教室行（原地编辑）
      Row() {
        Text('📍')
          .fontSize(14)
          .margin({ right: 6 })

        if (this.editingLocation) {
          TextInput({ text: this.tempLocation })
            .fontSize(15)
            .fontColor('#333333')
            .layoutWeight(1)
            .height(36)
            .borderRadius(8)
            .backgroundColor('#F5F5F5')
            .borderWidth(1)
            .borderColor('#5B9BD5')
            .onChange((value: string) => {
              this.tempLocation = value;
            })
            .onBlur(() => {
              this.timeSlot.location = this.tempLocation;
              this.editingLocation = false;
            })
        } else {
          Text(this.timeSlot.location === '' ? '点击设置教室' : this.timeSlot.location)
            .fontSize(15)
            .fontColor(this.timeSlot.location === '' ? '#999999' : '#333333')
            .layoutWeight(1)
            .onClick(() => {
              this.tempLocation = this.timeSlot.location;
              this.editingLocation = true;
            })
        }
      }
      .width('100%')
      .height(40)
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .borderWidth(1)
    .borderColor('#E0E0E0')
    .bindSheet(!!this.sheetOpen, this.PickerSheetBuilder(), {
      height: SheetSize.FIT_CONTENT,
      dragBar: false,
      showClose: true,
      backgroundColor: Color.Transparent,
      onDisappear: () => {
        this.sheetOpen = false;
      }
    })
  }
}
