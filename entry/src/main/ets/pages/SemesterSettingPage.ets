import { CourseViewModel } from '../viewmodel/CourseViewModel';

@Component
export struct SemesterSettingPage {
  @ObjectLink viewModel: CourseViewModel;
  navPathStack: NavPathStack = new NavPathStack();
  @State selectedDate: string = '';
  @State selectedYear: number = 2026;
  @State selectedMonth: number = 1;
  @State selectedDay: number = 1;

  aboutToAppear(): void {
    this.selectedDate = this.viewModel.semesterStartDate;
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
      Column() {
        Text('学期设置')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 16 })

        Text('请选择学期第一周的周一日期')
          .fontSize(14)
          .fontColor('#666666')
          .margin({ bottom: 24 })

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

        Button('保存')
          .width('100%')
          .height(44)
          .fontSize(16)
          .fontColor(Color.White)
          .backgroundColor('#4CAF50')
          .borderRadius(8)
          .margin({ top: 32 })
          .onClick(async () => {
            await this.viewModel.saveSemesterConfig(this.selectedDate);
            this.navPathStack.pop();
          })

        Button('取消')
          .width('100%')
          .height(44)
          .fontSize(16)
          .fontColor('#666666')
          .backgroundColor('#E0E0E0')
          .borderRadius(8)
          .margin({ top: 12 })
          .onClick(() => {
            this.navPathStack.pop();
          })
      }
      .padding(16)
    }
    .title('学期设置')
    .hideBackButton(false)
  }
}
