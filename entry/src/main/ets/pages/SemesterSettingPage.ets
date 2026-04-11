import { CourseViewModel } from '../viewmodel/CourseViewModel';
import { promptAction } from '@kit.ArkUI';

@Component
export struct SemesterSettingPage {
  @ObjectLink viewModel: CourseViewModel;
  navPathStack: NavPathStack = new NavPathStack();
  @State timetableName: string = '';
  @State selectedDate: string = '';
  @State selectedYear: number = 2026;
  @State selectedMonth: number = 1;
  @State selectedDay: number = 1;
  @State showDeleteConfirm: boolean = false;

  aboutToAppear(): void {
    if (this.viewModel.currentTimetable !== null) {
      this.timetableName = this.viewModel.currentTimetable.name;
      this.selectedDate = this.viewModel.currentTimetable.semesterStartDate;
    } else {
      this.timetableName = '我的课表';
      this.selectedDate = '';
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
          Text('课表设置')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .margin({ bottom: 24 })

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
              .onChange((value: DatePickerResult) => {
                this.selectedYear = value.year as number;
                this.selectedMonth = (value.month as number) + 1;
                this.selectedDay = value.day as number;
                this.updateSelectedDate();
              })
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
              .backgroundColor('#E0E0E0')
              .borderRadius(8)
              .layoutWeight(1)
              .height(48)
              .onClick(() => {
                this.navPathStack.pop();
              })

            Button('保存')
              .fontSize(16)
              .fontColor(Color.White)
              .backgroundColor('#4CAF50')
              .borderRadius(8)
              .layoutWeight(1)
              .height(48)
              .margin({ left: 12 })
              .onClick(async () => {
                if (this.timetableName.trim() === '') {
                  promptAction.showToast({ message: '请输入课表名称' });
                  return;
                }
                if (this.viewModel.currentTimetable !== null) {
                  await this.viewModel.updateTimetable(
                    this.viewModel.currentTimetable.id,
                    this.timetableName.trim(),
                    this.selectedDate
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
                    .backgroundColor('#E0E0E0')
                    .borderRadius(8)
                    .layoutWeight(1)
                    .height(44)
                    .onClick(() => {
                      this.showDeleteConfirm = false;
                    })

                  Button('删除')
                    .fontSize(16)
                    .fontColor(Color.White)
                    .backgroundColor('#F44336')
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
