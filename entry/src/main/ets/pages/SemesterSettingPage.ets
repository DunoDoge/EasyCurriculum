import { CourseViewModel } from '../viewmodel/CourseViewModel';
import { promptAction } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';

@ComponentV2
export struct SemesterSettingPage {
  @Require @Param viewModel: CourseViewModel;
  @Require @Param navPathStack: NavPathStack;
  @Local timetableName: string = '';
  @Local selectedDate: string = '';
  @Local selectedYear: number = 2026;
  @Local selectedMonth: number = 1;
  @Local selectedDay: number = 1;
  @Local showDeleteConfirm: boolean = false;
  @Local showWeekend: boolean = true;
  @Local totalSlots: number = 13;
  @Local totalWeeks: number = 20;

  aboutToAppear(): void {
    if (this.viewModel.currentTimetable !== null) {
      this.timetableName = this.viewModel.currentTimetable.name;
      this.selectedDate = this.viewModel.currentTimetable.semesterStartDate;
      this.showWeekend = this.viewModel.currentTimetable.showWeekend;
      this.totalSlots = this.viewModel.currentTimetable.totalSlots;
      this.totalWeeks = this.viewModel.currentTimetable.totalWeeks;
    } else {
      this.timetableName = '我的课表';
      this.selectedDate = '';
      this.showWeekend = true;
      this.totalSlots = 13;
      this.totalWeeks = 20;
    }

    if (this.selectedDate !== '') {
      let parts: string[] = this.selectedDate.split('-');
      this.selectedYear = Number(parts[0]);
      this.selectedMonth = Number(parts[1]);
      this.selectedDay = Number(parts[2]);
    } else {
      let now = new Date();
      this.selectedYear = now.getFullYear();
      this.selectedMonth = now.getMonth() + 1;
      this.selectedDay = now.getDate();
      this.updateSelectedDate();
    }
  }

  private updateSelectedDate(): void {
    let monthStr = this.selectedMonth < 10 ? '0' + this.selectedMonth : this.selectedMonth.toString();
    let dayStr = this.selectedDay < 10 ? '0' + this.selectedDay : this.selectedDay.toString();
    this.selectedDate = this.selectedYear.toString() + '-' + monthStr + '-' + dayStr;
  }

  build() {
    NavDestination() {
      Scroll() {
        Column() {
          Column() {
            Text('课表名称')
              .fontSize(14)
              .fontColor('#666666')
              .margin({ bottom: 8 })
              .alignSelf(ItemAlign.Start)

            TextInput({ text: this.timetableName, placeholder: '请输入课表名称' })
              .fontSize(16)
              .width('100%')
              .height(48)
              .borderRadius(8)
              .backgroundColor(Color.White)
              .borderWidth(1)
              .borderColor('#E0E0E0')
              .padding({ left: 12, right: 12 })
              .onChange((value: string) => {
                this.timetableName = value;
              })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 16 })
          .backgroundColor(Color.White)
          .borderRadius(12)
          .margin({ bottom: 16 })

          Column() {
            Text('学期开始日期')
              .fontSize(14)
              .fontColor('#666666')
              .margin({ bottom: 8 })
              .alignSelf(ItemAlign.Start)

            Text('请选择学期第一周的周一日期')
              .fontSize(12)
              .fontColor('#999999')
              .margin({ bottom: 12 })
              .alignSelf(ItemAlign.Start)

            DatePicker({
              start: new Date(2020, 0, 1),
              end: new Date(2030, 11, 31),
              selected: new Date(this.selectedYear, this.selectedMonth - 1, this.selectedDay)
            })
              .onDateChange((value: Date) => {
                this.selectedYear = value.getFullYear();
                this.selectedMonth = value.getMonth() + 1;
                this.selectedDay = value.getDate();
                this.updateSelectedDate();
              })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 16 })
          .backgroundColor(Color.White)
          .borderRadius(12)
          .margin({ bottom: 16 })

          Column() {
            Row() {
              Text('显示周末课程')
                .fontSize(16)
                .fontColor('#333333')
                .layoutWeight(1)

              Toggle({ type: ToggleType.Switch, isOn: this.showWeekend })
                .selectedColor('#4CAF50')
                .onChange((isOn: boolean) => {
                  this.showWeekend = isOn;
                })
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)

            Text('关闭后将只显示周一到周五的课程')
              .fontSize(12)
              .fontColor('#999999')
              .margin({ top: 4 })
              .alignSelf(ItemAlign.Start)
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 16 })
          .backgroundColor(Color.White)
          .borderRadius(12)
          .margin({ bottom: 16 })

          Column() {
            Text('一天课程节数')
              .fontSize(14)
              .fontColor('#666666')
              .margin({ bottom: 8 })
              .alignSelf(ItemAlign.Start)

            Row() {
              Text(this.totalSlots.toString() + '节')
                .fontSize(16)
                .fontColor('#333333')
                .width(50)

              Slider({
                value: this.totalSlots,
                min: 8,
                max: 16,
                step: 1,
                style: SliderStyle.OutSet
              })
                .width('100%')
                .layoutWeight(1)
                .onChange((value: number, _mode: SliderChangeMode) => {
                  this.totalSlots = Math.round(value);
                })
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)

            Text('设置一天中显示的课程节数（8-16节）')
              .fontSize(12)
              .fontColor('#999999')
              .margin({ top: 4 })
              .alignSelf(ItemAlign.Start)
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 16 })
          .backgroundColor(Color.White)
          .borderRadius(12)
          .margin({ bottom: 16 })

          Column() {
            Text('学期周数')
              .fontSize(14)
              .fontColor('#666666')
              .margin({ bottom: 8 })
              .alignSelf(ItemAlign.Start)

            Row() {
              Text(this.totalWeeks.toString() + '周')
                .fontSize(16)
                .fontColor('#333333')
                .width(50)

              Slider({
                value: this.totalWeeks,
                min: 10,
                max: 30,
                step: 1,
                style: SliderStyle.OutSet
              })
                .width('100%')
                .layoutWeight(1)
                .onChange((value: number, _mode: SliderChangeMode) => {
                  this.totalWeeks = Math.round(value);
                })
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)

            Text('设置学期的总周数（10-30周）')
              .fontSize(12)
              .fontColor('#999999')
              .margin({ top: 4 })
              .alignSelf(ItemAlign.Start)
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 16 })
          .backgroundColor(Color.White)
          .borderRadius(12)
          .margin({ bottom: 16 })

          if (this.viewModel.timetables.length > 1) {
            Button('删除课表')
              .fontSize(16)
              .fontColor('#F44336')
              .backgroundColor(Color.White)
              .borderRadius(8)
              .width('100%')
              .height(48)
              .margin({ bottom: 16 })
              .onClick(() => {
                this.showDeleteConfirm = true;
              })
          }

          Row() {
            Button('取消')
              .fontSize(16)
              .fontColor('#666666')
              .backgroundColor('#B4C6E7')
              .borderRadius(8)
              .layoutWeight(1)
              .height(48)
              .onClick(() => {
                this.navPathStack.pop();
              })

            Button('保存')
              .fontSize(16)
              .fontColor(Color.White)
              .backgroundColor('#5B9BD5')
              .borderRadius(8)
              .layoutWeight(1)
              .height(48)
              .margin({ left: 12 })
              .onClick(async () => {
                if (this.timetableName.trim() === '') {
                  try {
                    promptAction.showToast({ message: '请输入课表名称' });
                  } catch (error) {
                    let e: BusinessError = error as BusinessError;
                    console.error('showToast error: ' + JSON.stringify(e));
                  }
                  return;
                }
                if (this.viewModel.currentTimetable !== null) {
                  await this.viewModel.updateTimetable(
                    this.viewModel.currentTimetable.id,
                    this.timetableName.trim(),
                    this.selectedDate,
                    this.showWeekend,
                    this.totalSlots,
                    this.totalWeeks
                  );
                }
                this.navPathStack.pop();
              })
          }
          .width('100%')
          .margin({ top: 8 })

          if (this.showDeleteConfirm) {
            Column() {
              Column() {
                Text('确认删除')
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#333333')
                  .margin({ bottom: 12 })

                Text('确定要删除课表"' + this.timetableName + '"吗？此操作不可恢复。')
                  .fontSize(14)
                  .fontColor('#666666')
                  .textAlign(TextAlign.Center)
                  .margin({ bottom: 20 })

                Row() {
                  Button('取消')
                    .fontSize(16)
                    .fontColor('#666666')
                    .backgroundColor('#B4C6E7')
                    .borderRadius(8)
                    .layoutWeight(1)
                    .height(44)
                    .onClick(() => {
                      this.showDeleteConfirm = false;
                    })

                  Button('删除')
                    .fontSize(16)
                    .fontColor(Color.White)
                    .backgroundColor('#E57373')
                    .borderRadius(8)
                    .layoutWeight(1)
                    .height(44)
                    .margin({ left: 12 })
                    .onClick(async () => {
                      if (this.viewModel.currentTimetable !== null) {
                        await this.viewModel.deleteTimetable(this.viewModel.currentTimetable.id);
                      }
                      this.showDeleteConfirm = false;
                      this.navPathStack.pop();
                    })
                }
                .width('100%')
              }
              .width('80%')
              .padding(20)
              .backgroundColor(Color.White)
              .borderRadius(12)
            }
            .width('100%')
            .height('100%')
            .backgroundColor('rgba(0, 0, 0, 0.5)')
            .justifyContent(FlexAlign.Center)
            .position({ x: 0, y: 0 })
          }
        }
        .width('100%')
        .padding(16)
      }
      .scrollable(ScrollDirection.Vertical)
    }
    .title('课表设置')
    .hideBackButton(false)
  }
}
