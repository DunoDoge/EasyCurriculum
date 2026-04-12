import { CourseViewModel } from '../viewmodel/CourseViewModel';
import { CourseInfo, WeekType, getWeekTypeName } from '../model/CourseModel';
import { WeekDay, getWeekDayList, getWeekDayName } from '../model/WeekDay';
import { Constants } from '../common/constants/Constants';
import { CourseCard } from '../components/CourseCard';
import { WeekHeader } from '../components/WeekHeader';
import { TimeSlotHeader } from '../components/TimeSlotHeader';
import { DayView } from '../components/DayView';
import { SemesterSettingPage } from './SemesterSettingPage';
import { Timetable } from '../model/CourseModel';
import { promptAction } from '@kit.ArkUI';

@Entry
@Component
struct Index {
  @State viewModel: CourseViewModel = new CourseViewModel();
  navPathStack: NavPathStack = new NavPathStack();
  @State showWeekPicker: boolean = false;
  @State showTimetablePicker: boolean = false;
  @State showNewTimetableDialog: boolean = false;
  @State newTimetableName: string = '';

  aboutToAppear(): void {
    this.viewModel.init(this.getUIContext().getHostContext() as Context);
  }

  build() {
    Navigation(this.navPathStack) {
      Column() {
        Row() {
          Row() {
            Text(this.viewModel.currentTimetableName)
              .fontSize(16)
              .fontColor('#333333')
              .fontWeight(FontWeight.Medium)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .constraintSize({ maxWidth: '35%' })

            Text('▼')
              .fontSize(10)
              .fontColor('#666666')
              .margin({ left: 4 })
          }
          .padding({ left: 16, right: 8 })
          .onClick(() => {
            this.showTimetablePicker = true;
          })

          Text('第' + this.viewModel.currentWeek + '周')
            .fontSize(20)
            .fontColor('#333333')
            .fontWeight(FontWeight.Bold)
            .onClick(() => {
              this.showWeekPicker = true;
            })

          Blank()

          Button() {
            Image($r('app.media.ic_public_add'))
              .width(24)
          }
          .type(ButtonType.Circle)
          .width(36)
          .height(36)
          .backgroundColor('#9ACAF8')
          .margin({ left: 12 })
          .onClick(() => {
            this.navPathStack.pushPath({
              name: 'CourseEditPage',
              param: CourseInfo.createDefault()
            });
            })

          Button() {
            Image($r('app.media.ic_public_settings'))
              .width(24)
          }
          .type(ButtonType.Circle)
          .width(36)
          .height(36)
          .backgroundColor('#E0E0E0')
          .margin({ left: 12 })
          .onClick(() => {
            this.navPathStack.pushPath({ name: 'SemesterSettingPage' });
          })
        }
        .width('100%')
        .padding({ left: 0, right: 16, top: 12, bottom: 8 })
        .alignItems(VerticalAlign.Center)

        if (this.viewModel.viewMode === 'week') {
          WeekHeader({
            currentWeek: this.viewModel.currentWeek,
            semesterStartDate: this.viewModel.semesterStartDate,
            monthOfWeek: this.viewModel.getMonthOfWeek(),
            showWeekend: this.viewModel.currentTimetable?.showWeekend ?? true,
            onDateClick: (weekDay: number) => {
              this.viewModel.switchToDayView(weekDay);
            }
          })

          Scroll() {
            Row() {
              TimeSlotHeader({ totalSlots: this.viewModel.currentTotalSlots })

              Row() {
                ForEach(getWeekDayList(this.viewModel.currentTimetable?.showWeekend ?? true), (day: WeekDay) => {
                  this.DayColumn(day);
                }, (day: WeekDay) => day.toString())
              }
              .layoutWeight(1)
            }
          }
          .scrollable(ScrollDirection.Vertical)
          .scrollBar(BarState.Auto)
          .layoutWeight(1)
        } else {
          DayView({
            selectedWeekDay: this.viewModel.selectedWeekDay,
            currentWeek: this.viewModel.currentWeek,
            viewModel: this.viewModel,
            onBack: () => {
              this.viewModel.switchToWeekView();
            },
            onCourseClick: (course: CourseInfo) => {
              this.navPathStack.pushPath({
                name: 'CourseDetailPage',
                param: course
              });
            },
            onSlotClick: (slot: number) => {
              let newCourse = CourseInfo.createDefault();
              newCourse.weekDay = this.viewModel.selectedWeekDay;
              newCourse.startSlot = slot;
              newCourse.endSlot = slot;
              newCourse.startWeek = this.viewModel.currentWeek;
              newCourse.endWeek = this.viewModel.currentWeek;
              this.navPathStack.pushPath({
                name: 'CourseEditPage',
                param: newCourse
              });
            }
          })
        }

        if (this.showWeekPicker) {
          Column() {
            Row() {
              Text('选择周次')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333333')
                .layoutWeight(1)

              Text('✕')
                .fontSize(20)
                .fontColor('#999999')
                .onClick(() => {
                  this.showWeekPicker = false;
                })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 16, bottom: 12 })
            .alignItems(VerticalAlign.Center)

            Scroll() {
              Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
                ForEach(Array.from({ length: this.viewModel.currentTotalWeeks }, (_v: Object, k: number) => k + 1), (week: number) => {
                  Column() {
                    Text('第' + week + '周')
                      .fontSize(14)
                      .fontColor(week === this.viewModel.currentWeek ? Color.White : '#333333')
                  }
                  .width(72)
                  .height(40)
                  .borderRadius(8)
                  .backgroundColor(week === this.viewModel.currentWeek ? '#5B9BD5' : '#F0F0F0')
                  .justifyContent(FlexAlign.Center)
                  .margin(6)
                  .onClick(() => {
                    this.viewModel.currentWeek = week;
                    this.showWeekPicker = false;
                  })
                }, (week: number) => week.toString())
              }
              .padding({ left: 10, right: 10 })
            }
            .layoutWeight(1)
            .scrollBar(BarState.Auto)

            Row() {
              Button('今天')
                .fontSize(16)
                .fontColor(Color.White)
                .backgroundColor('#5B9BD5')
                .borderRadius(8)
                .width('100%')
                .height(44)
                .onClick(() => {
                  this.viewModel.goToToday();
                  this.showWeekPicker = false;
                })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 12, bottom: 16 })
          }
          .width('100%')
          .height(360)
          .backgroundColor(Color.White)
          .borderRadius({ topLeft: 16, topRight: 16 })
          .shadow({ radius: 20, color: '#33000000', offsetY: -4 })
        }

        if (this.showTimetablePicker) {
          Column() {
            Row() {
              Text('选择课表')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333333')
                .layoutWeight(1)

              Text('✕')
                .fontSize(20)
                .fontColor('#999999')
                .onClick(() => {
                  this.showTimetablePicker = false;
                })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 16, bottom: 12 })
            .alignItems(VerticalAlign.Center)

            Scroll() {
              Column() {
                ForEach(this.viewModel.timetables, (timetable: Timetable) => {
                  Row() {
                    Text(timetable.name)
                      .fontSize(16)
                      .fontColor(timetable.id === this.viewModel.currentTimetableId ? '#5B9BD5' : '#333333')
                      .layoutWeight(1)

                    if (timetable.id === this.viewModel.currentTimetableId) {
                      Text('✓')
                        .fontSize(16)
                        .fontColor('#5B9BD5')
                    }
                  }
                  .width('100%')
                  .height(48)
                  .padding({ left: 16, right: 16 })
                  .backgroundColor(timetable.id === this.viewModel.currentTimetableId ? '#DEEBF7' : Color.Transparent)
                  .borderRadius(8)
                  .onClick(() => {
                    this.viewModel.switchTimetable(timetable.id);
                    this.showTimetablePicker = false;
                  })
                }, (timetable: Timetable) => timetable.id)
              }
              .padding({ left: 16, right: 16 })
            }
            .layoutWeight(1)
            .scrollBar(BarState.Auto)

            Row() {
              Button('新建课表')
                .fontSize(16)
                .fontColor(Color.White)
                .backgroundColor('#5B9BD5')
                .borderRadius(8)
                .width('100%')
                .height(44)
                .onClick(() => {
                  this.showTimetablePicker = false;
                  this.showNewTimetableDialog = true;
                })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 12, bottom: 16 })
          }
          .width('100%')
          .height(400)
          .backgroundColor(Color.White)
          .borderRadius({ topLeft: 16, topRight: 16 })
          .shadow({ radius: 20, color: '#33000000', offsetY: -4 })
        }

        if (this.showNewTimetableDialog) {
          Column() {
            Row() {
              Text('新建课表')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333333')
                .layoutWeight(1)

              Text('✕')
                .fontSize(20)
                .fontColor('#999999')
                .onClick(() => {
                  this.showNewTimetableDialog = false;
                  this.newTimetableName = '';
                })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 16, bottom: 12 })
            .alignItems(VerticalAlign.Center)

            Text('课表名称')
              .fontSize(14)
              .fontColor('#666666')
              .width('100%')
              .padding({ left: 16, right: 16, bottom: 8 })

            TextInput({ placeholder: '请输入课表名称', text: this.newTimetableName })
              .fontSize(16)
              .width('100%')
              .height(44)
              .borderRadius(8)
              .backgroundColor('#F5F5F5')
              .margin({ left: 16, right: 16, bottom: 16 })
              .onChange((value: string) => {
                this.newTimetableName = value;
              })

            Row() {
              Button('取消')
                .fontSize(16)
                .fontColor('#666666')
                .backgroundColor('#B4C6E7')
                .borderRadius(8)
                .layoutWeight(1)
                .height(44)
                .onClick(() => {
                  this.showNewTimetableDialog = false;
                  this.newTimetableName = '';
                })

              Button('创建')
                .fontSize(16)
                .fontColor(Color.White)
                .backgroundColor('#5B9BD5')
                .borderRadius(8)
                .layoutWeight(1)
                .height(44)
                .margin({ left: 12 })
                .onClick(() => {
                  if (this.newTimetableName.trim() === '') {
                    promptAction.showToast({ message: '请输入课表名称' });
                    return;
                  }
                  let newTimetable = this.viewModel.createTimetableSync(this.newTimetableName.trim(), '');
                  this.viewModel.switchTimetable(newTimetable.id);
                  this.showNewTimetableDialog = false;
                  this.newTimetableName = '';
                  this.navPathStack.pushPath({ name: 'SemesterSettingPage' });
                })
            }
            .width('100%')
            .padding({ left: 16, right: 16, bottom: 16 })
          }
          .width('100%')
          .height(280)
          .backgroundColor(Color.White)
          .borderRadius({ topLeft: 16, topRight: 16 })
          .shadow({ radius: 20, color: '#33000000', offsetY: -4 })
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')
    }
    .navDestination(this.buildNavDestination)
    .mode(NavigationMode.Stack)
    .titleMode(NavigationTitleMode.Mini)
    .hideTitleBar(true)
  }

  @Builder
  buildNavDestination(name: string, param: Object) {
    if (name === 'CourseEditPage') {
      CourseEditPage({ course: param as CourseInfo, viewModel: this.viewModel, navPathStack: this.navPathStack });
    } else if (name === 'CourseDetailPage') {
      CourseDetailPage({ course: param as CourseInfo, viewModel: this.viewModel, navPathStack: this.navPathStack });
    } else if (name === 'SemesterSettingPage') {
      SemesterSettingPage({ viewModel: this.viewModel, navPathStack: this.navPathStack });
    }
  }

  @Builder
  DayColumn(day: WeekDay) {
    Stack() {
      Column() {
        ForEach(Array.from({ length: this.viewModel.currentTotalSlots }, (_v: Object, k: number) => k + 1), (slot: number) => {
          Column() {}
            .width('100%')
            .height(Constants.SLOT_HEIGHT)
            .borderWidth(0.5)
            .borderColor('#E0E0E0')
            .backgroundColor(Color.White)
            .onClick(() => {
              if (this.viewModel.getCourseAtSlot(day, slot) === undefined) {
                let newCourse = CourseInfo.createDefault();
                newCourse.weekDay = day;
                newCourse.startSlot = slot;
                newCourse.endSlot = slot;
                newCourse.startWeek = this.viewModel.currentWeek;
                newCourse.endWeek = this.viewModel.currentWeek;
                this.navPathStack.pushPath({
                  name: 'CourseEditPage',
                  param: newCourse
                });
              }
            })
        }, (slot: number) => slot.toString())
      }

      ForEach(this.viewModel.getCoursesByDay(day), (course: CourseInfo) => {
        CourseCard({
          course: course,
          onCardClick: (clickedCourse: CourseInfo) => {
            this.navPathStack.pushPath({
              name: 'CourseDetailPage',
              param: clickedCourse
            });
          }
        })
      }, (course: CourseInfo) => course.id)
    }
    .layoutWeight(1)
    .height(this.viewModel.currentTotalSlots * Constants.SLOT_HEIGHT)
    .clip(false)
  }
}

@Component
struct CourseEditPage {
  @State course: CourseInfo = CourseInfo.createDefault();
  @ObjectLink viewModel: CourseViewModel;
  navPathStack: NavPathStack = new NavPathStack();
  @State selectedWeekDay: number = 1;
  @State selectedStartSlot: number = 1;
  @State selectedEndSlot: number = 2;
  @State selectedWeekType: number = 0;
  @State selectedStartWeek: number = 1;
  @State selectedEndWeek: number = 16;
  @State selectedColorIndex: number = 0;
  @State inputName: string = '';
  @State inputTeacher: string = '';
  @State inputLocation: string = '';

  aboutToAppear(): void {
    this.inputName = this.course.name;
    this.inputTeacher = this.course.teacher;
    this.inputLocation = this.course.location;
    this.selectedWeekDay = this.course.weekDay;
    this.selectedStartSlot = this.course.startSlot;
    this.selectedEndSlot = this.course.endSlot;
    this.selectedWeekType = this.course.weekType;
    this.selectedStartWeek = this.course.startWeek;
    this.selectedEndWeek = this.course.endWeek;
    for (let i = 0; i < Constants.COURSE_COLORS.length; i++) {
      if (Constants.COURSE_COLORS[i] === this.course.color) {
        this.selectedColorIndex = i;
        break;
      }
    }
  }

  build() {
    NavDestination() {
      Scroll() {
        Column() {
          this.FormItem('课程名称', this.inputName, (value: string) => {
            this.inputName = value;
          });

          this.FormItem('教师', this.inputTeacher, (value: string) => {
            this.inputTeacher = value;
          });

          this.FormItem('教室', this.inputLocation, (value: string) => {
            this.inputLocation = value;
          });

          this.WeekDaySelector();

          this.SlotSelector();

          this.WeekTypeSelector();

          this.WeekSelector();

          Column() {
            Text('颜色')
              .fontSize(14)
              .fontColor('#333333')
              .margin({ bottom: 8 })

            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(Constants.COURSE_COLORS, (color: string, index: number) => {
                Column() {
                  if (index === this.selectedColorIndex) {
                    Text('✓')
                      .fontSize(16)
                      .fontColor(Color.White)
                  }
                }
                .width(40)
                .height(40)
                .borderRadius(20)
                .backgroundColor(color)
                .justifyContent(FlexAlign.Center)
                .margin(4)
                .onClick(() => {
                  this.selectedColorIndex = index;
                })
              }, (color: string, index: number) => color + index.toString())
            }
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })

          Row() {
            Button('取消')
              .fontSize(16)
              .fontColor('#666666')
              .backgroundColor('#B4C6E7')
              .borderRadius(8)
              .layoutWeight(1)
              .height(44)
              .onClick(() => {
                this.navPathStack.pop();
              })

            Button('保存')
              .fontSize(16)
              .fontColor(Color.White)
              .backgroundColor('#5B9BD5')
              .borderRadius(8)
              .layoutWeight(1)
              .height(44)
              .margin({ left: 12 })
              .onClick(() => {
                this.saveCourse();
              })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 20, bottom: 20 })
        }
        .width('100%')
      }
      .scrollable(ScrollDirection.Vertical)
    }
    .title('编辑课程')
    .hideBackButton(false)
  }

  @Builder
  FormItem(label: string, value: string, onChange: (value: string) => void) {
    Column() {
      Text(label)
        .fontSize(14)
        .fontColor('#333333')
        .margin({ bottom: 8 })

      TextInput({ text: value })
        .fontSize(16)
        .width('100%')
        .height(44)
        .borderRadius(8)
        .backgroundColor(Color.White)
        .borderWidth(1)
        .borderColor('#E0E0E0')
        .onChange(onChange)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  WeekDaySelector() {
    Column() {
      Text('星期')
        .fontSize(14)
        .fontColor('#333333')
        .margin({ bottom: 8 })

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(getWeekDayList(), (day: WeekDay) => {
          Column() {
            Text(getWeekDayName(day))
              .fontSize(13)
              .fontColor(day === this.selectedWeekDay ? Color.White : '#333333')
          }
          .height(36)
          .padding({ left: 12, right: 12 })
          .borderRadius(18)
          .backgroundColor(day === this.selectedWeekDay ? '#5B9BD5' : '#F0F0F0')
          .justifyContent(FlexAlign.Center)
          .margin(4)
          .onClick(() => {
            this.selectedWeekDay = day;
          })
        }, (day: WeekDay) => 'weekday_' + day.toString())
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  SlotSelector() {
    Column() {
      Row() {
        Column() {
          Text('开始节次')
            .fontSize(14)
            .fontColor('#333333')
            .margin({ bottom: 8 })

          TextPicker({ range: this.getSlotRange(), selected: this.selectedStartSlot - 1 })
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
              this.selectedStartSlot = idx + 1;
              if (this.selectedEndSlot < this.selectedStartSlot) {
                this.selectedEndSlot = this.selectedStartSlot;
              }
            })
        }
        .layoutWeight(1)
        .padding({ right: 8 })

        Column() {
          Text('结束节次')
            .fontSize(14)
            .fontColor('#333333')
            .margin({ bottom: 8 })

          TextPicker({ range: this.getSlotRange(), selected: this.selectedEndSlot - 1 })
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
              this.selectedEndSlot = idx + 1;
              if (this.selectedEndSlot < this.selectedStartSlot) {
                this.selectedEndSlot = this.selectedStartSlot;
              }
            })
        }
        .layoutWeight(1)
        .padding({ left: 8 })
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
  }

  private getSlotRange(): string[] {
    let range: string[] = [];
    for (let i = 1; i <= this.viewModel.currentTotalSlots; i++) {
      range.push('第' + i + '节');
    }
    return range;
  }

  @Builder
  WeekTypeSelector() {
    Column() {
      Text('周类型')
        .fontSize(14)
        .fontColor('#333333')
        .margin({ bottom: 8 })

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach([WeekType.EVERY_WEEK, WeekType.ODD_WEEK, WeekType.EVEN_WEEK], (type: number) => {
          Column() {
            Text(getWeekTypeName(type))
              .fontSize(13)
              .fontColor(type === this.selectedWeekType ? Color.White : '#333333')
          }
          .height(36)
          .padding({ left: 12, right: 12 })
          .borderRadius(18)
          .backgroundColor(type === this.selectedWeekType ? '#5B9BD5' : '#F0F0F0')
          .justifyContent(FlexAlign.Center)
          .margin(4)
          .onClick(() => {
            this.selectedWeekType = type;
          })
        }, (type: number) => 'weektype_' + type.toString())
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  WeekSelector() {
    Column() {
      Row() {
        Column() {
          Text('开始周次')
            .fontSize(14)
            .fontColor('#333333')
            .margin({ bottom: 8 })

          TextPicker({ range: this.getWeekRange(), selected: this.selectedStartWeek - 1 })
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
              this.selectedStartWeek = idx + 1;
              if (this.selectedEndWeek < this.selectedStartWeek) {
                this.selectedEndWeek = this.selectedStartWeek;
              }
            })
        }
        .layoutWeight(1)
        .padding({ right: 8 })

        Column() {
          Text('结束周次')
            .fontSize(14)
            .fontColor('#333333')
            .margin({ bottom: 8 })

          TextPicker({ range: this.getWeekRange(), selected: this.selectedEndWeek - 1 })
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
              this.selectedEndWeek = idx + 1;
              if (this.selectedEndWeek < this.selectedStartWeek) {
                this.selectedEndWeek = this.selectedStartWeek;
              }
            })
        }
        .layoutWeight(1)
        .padding({ left: 8 })
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
  }

  private getWeekRange(): string[] {
    let range: string[] = [];
    for (let i = 1; i <= this.viewModel.currentTotalWeeks; i++) {
      range.push('第' + i + '周');
    }
    return range;
  }

  private saveCourse(): void {
    if (this.inputName.trim() === '') {
      promptAction.showToast({ message: '请输入课程名称' });
      return;
    }
    let course = new CourseInfo(
      this.course.id,
      this.inputName,
      this.inputTeacher,
      this.inputLocation,
      this.selectedWeekDay,
      this.selectedStartSlot,
      this.selectedEndSlot,
      this.selectedStartWeek,
      this.selectedEndWeek,
      Constants.COURSE_COLORS[this.selectedColorIndex],
      this.selectedWeekType
    );
    if (this.viewModel.hasConflict(course, this.course.id)) {
      promptAction.showToast({ message: '课程时间冲突，请重新选择' });
      return;
    }
    if (this.course.id === '') {
      this.viewModel.addCourse(course);
    } else {
      this.viewModel.updateCourse(course);
    }
    this.navPathStack.clear();
  }
}

@Component
struct CourseDetailPage {
  @State course: CourseInfo = CourseInfo.createDefault();
  @ObjectLink viewModel: CourseViewModel;
  navPathStack: NavPathStack = new NavPathStack();

  build() {
    NavDestination() {
      Column() {
        Column() {
          Text(this.course.name)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
        }
        .width('100%')
        .height(120)
        .backgroundColor(this.course.color)
        .justifyContent(FlexAlign.Center)
        .padding(16)

        Column() {
          this.DetailRow('教师', this.course.teacher);
          this.DetailRow('教室', this.course.location);
          this.DetailRow('星期', getWeekDayName(this.course.weekDay as WeekDay));
          this.DetailRow('节次', '第' + this.course.startSlot + '-' + this.course.endSlot + '节');
          this.DetailRow('周次', '第' + this.course.startWeek + '-' + this.course.endWeek + '周');
          this.DetailRow('周类型', getWeekTypeName(this.course.weekType));
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Color.White)
        .borderRadius(12)
        .margin({ top: -20, left: 16, right: 16 })

        Row() {
          Button('编辑')
            .fontSize(16)
            .fontColor(Color.White)
            .backgroundColor('#5B9BD5')
            .borderRadius(8)
            .layoutWeight(1)
            .height(44)
            .onClick(() => {
              this.navPathStack.pushPath({
                name: 'CourseEditPage',
                param: this.course
              });
            })

          Button('删除')
            .fontSize(16)
            .fontColor(Color.White)
            .backgroundColor('#F44336')
            .borderRadius(8)
            .layoutWeight(1)
            .height(44)
            .margin({ left: 12 })
            .onClick(() => {
              this.viewModel.deleteCourse(this.course.id);
              this.navPathStack.pop();
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 24, bottom: 16 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')
    }
    .title('课程详情')
    .hideBackButton(false)
  }

  @Builder
  DetailRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor('#999999')
        .width(60)

      Text(value)
        .fontSize(16)
        .fontColor('#333333')
        .layoutWeight(1)
    }
    .width('100%')
    .height(48)
    .alignItems(VerticalAlign.Center)
  }
}