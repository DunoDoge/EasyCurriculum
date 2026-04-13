@ComponentV2
export struct WeekSlotPickerDialog {
  @Param mode: string = 'week';
  @Param maxValue: number = 16;
  @Param initStartValue: number = 1;
  @Param initEndValue: number = 16;
  @Local tempStartValue: number = 1;
  @Local tempEndValue: number = 16;
  @Param onConfirm: (startValue: number, endValue: number) => void = () => {};
  @Param onCancel: () => void = () => {};

  aboutToAppear(): void {
    this.tempStartValue = this.initStartValue;
    this.tempEndValue = this.initEndValue;
  }

  private getRange(): string[] {
    let range: string[] = [];
    if (this.mode === 'week') {
      for (let i = 1; i <= this.maxValue; i++) {
        range.push('第' + i + '周');
      }
    } else {
      for (let i = 1; i <= this.maxValue; i++) {
        range.push('第' + i + '节');
      }
    }
    return range;
  }

  build() {
    Column() {
      Row() {
        Text(this.mode === 'week' ? '选择周次' : '选择节次')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 12 })
      .alignItems(VerticalAlign.Center)

      Row() {
        Column() {
          Text(this.mode === 'week' ? '开始周次' : '开始节次')
            .fontSize(14)
            .fontColor('#333333')
            .margin({ bottom: 8 })

          TextPicker({ range: this.getRange(), selected: this.tempStartValue - 1 })
            .height(150)
            .canLoop(false)
            .selectedTextStyle({
              color: '#5B9BD5',
              font: { size: '18fp', weight: FontWeight.Medium }
            })
            .textStyle({
              color: '#666666',
              font: { size: '14fp', weight: FontWeight.Regular }
            })
            .disappearTextStyle({
              color: '#999999',
              font: { size: '12fp', weight: FontWeight.Regular }
            })
            .onChange((value: string | string[], index: number | number[]) => {
              let idx: number = index as number;
              this.tempStartValue = idx + 1;
              if (this.tempEndValue < this.tempStartValue) {
                this.tempEndValue = this.tempStartValue;
              }
            })
        }
        .layoutWeight(1)
        .padding({ right: 8 })

        Column() {
          Text(this.mode === 'week' ? '结束周次' : '结束节次')
            .fontSize(14)
            .fontColor('#333333')
            .margin({ bottom: 8 })

          TextPicker({ range: this.getRange(), selected: this.tempEndValue - 1 })
            .height(150)
            .canLoop(false)
            .selectedTextStyle({
              color: '#5B9BD5',
              font: { size: '18fp', weight: FontWeight.Medium }
            })
            .textStyle({
              color: '#666666',
              font: { size: '14fp', weight: FontWeight.Regular }
            })
            .disappearTextStyle({
              color: '#999999',
              font: { size: '12fp', weight: FontWeight.Regular }
            })
            .onChange((value: string | string[], index: number | number[]) => {
              let idx: number = index as number;
              this.tempEndValue = idx + 1;
              if (this.tempEndValue < this.tempStartValue) {
                this.tempEndValue = this.tempStartValue;
              }
            })
        }
        .layoutWeight(1)
        .padding({ left: 8 })
      }
      .width('100%')
      .padding({ left: 16, right: 16 })

      Row() {
        Button('取消')
          .fontSize(16)
          .fontColor('#666666')
          .backgroundColor('#B4C6E7')
          .borderRadius(8)
          .layoutWeight(1)
          .height(44)
          .onClick(() => {
            this.onCancel();
          })

        Button('确定')
          .fontSize(16)
          .fontColor(Color.White)
          .backgroundColor('#5B9BD5')
          .borderRadius(8)
          .layoutWeight(1)
          .height(44)
          .margin({ left: 12 })
          .onClick(() => {
            this.onConfirm(this.tempStartValue, this.tempEndValue);
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 16 })
    }
    .width('100%')
    .backgroundColor(Color.White)
    .borderRadius({ topLeft: 16, topRight: 16 })
  }
}
