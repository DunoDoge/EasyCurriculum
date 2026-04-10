import { CourseViewModel } from '../viewmodel/CourseViewModel';
import { CourseInfo, WeekType, getWeekTypeName } from '../model/CourseModel';
import { WeekDay, getWeekDayList, getWeekDayName } from '../model/WeekDay';
import { Constants } from '../common/constants/Constants';
import { CourseCard } from '../components/CourseCard';
import { WeekHeader } from '../components/WeekHeader';
import { TimeSlotHeader } from '../components/TimeSlotHeader';

@Entry
@Component
struct Index {
  @State viewModel: CourseViewModel = new CourseViewModel();
  navPathStack: NavPathStack = new NavPathStack();

  aboutToAppear(): void {
    this.viewModel.init(this.getUIContext().getHostContext() as Context);
  }

  build() {
    Navigation(this.navPathStack) {
      Column() {
        Row() {
          Text('Easy 课程表')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .layoutWeight(1)

          Button('+ 添加')
            .fontSize(14)
            .fontColor(Color.White)
            .backgroundColor('#4CAF50')
            .borderRadius(20)
            .height(36)
            .padding({ left: 16, right: 16 })
            .onClick(() => {
              this.navPathStack.pushPath({
                name: 'CourseEditPage',
                param: CourseInfo.createDefault()
              });
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 8 })
        .alignItems(VerticalAlign.Center)

        WeekHeader()

        Scroll() {
          Row() {
            TimeSlotHeader()

            Row() {
              ForEach(getWeekDayList(), (day: WeekDay) => {
                this.DayColumn(day);
              }, (day: WeekDay) => day.toString())
            }
            .layoutWeight(1)
          }
        }
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Auto)
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')
    }
    .navDestination(this.buildNavDestination)
    .mode(NavigationMode.Stack)
    .titleMode(NavigationTitleMode.Mini)
  }

  @Builder
  buildNavDestination(name: string, param: Object) {
    if (name === 'CourseEditPage') {
      CourseEditPage({ course: param as CourseInfo, viewModel: this.viewModel, navPathStack: this.navPathStack });
    } else if (name === 'CourseDetailPage') {
      CourseDetailPage({ course: param as CourseInfo, viewModel: this.viewModel, navPathStack: this.navPathStack });
    }
  }

  @Builder
  DayColumn(day: WeekDay) {
    Stack() {
      Column() {
        ForEach(Array.from({ length: Constants.TOTAL_SLOTS }, (_v: Object, k: number) => k + 1), (slot: number) => {
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
    .height(Constants.TOTAL_SLOTS * Constants.SLOT_HEIGHT)
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

          this.StartSlotSelector();

          this.EndSlotSelector();

          this.WeekTypeSelector();

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
              .backgroundColor('#E0E0E0')
              .borderRadius(8)
              .layoutWeight(1)
              .height(44)
              .onClick(() => {
                this.navPathStack.pop();
              })

            Button('保存')
              .fontSize(16)
              .fontColor(Color.White)
              .backgroundColor('#4CAF50')
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
          .backgroundColor(day === this.selectedWeekDay ? '#4CAF50' : '#F0F0F0')
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
  StartSlotSelector() {
    Column() {
      Text('开始节次')
        .fontSize(14)
        .fontColor('#333333')
        .margin({ bottom: 8 })

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(Array.from({ length: Constants.TOTAL_SLOTS }, (_v: Object, k: number) => k + 1), (slot: number) => {
          Column() {
            Text('第' + slot + '节')
              .fontSize(13)
              .fontColor(slot === this.selectedStartSlot ? Color.White : '#333333')
          }
          .height(36)
          .padding({ left: 12, right: 12 })
          .borderRadius(18)
          .backgroundColor(slot === this.selectedStartSlot ? '#4CAF50' : '#F0F0F0')
          .justifyContent(FlexAlign.Center)
          .margin(4)
          .onClick(() => {
            this.selectedStartSlot = slot;
            if (this.selectedEndSlot < this.selectedStartSlot) {
              this.selectedEndSlot = this.selectedStartSlot;
            }
          })
        }, (slot: number) => 'start_' + slot.toString())
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  EndSlotSelector() {
    Column() {
      Text('结束节次')
        .fontSize(14)
        .fontColor('#333333')
        .margin({ bottom: 8 })

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(Array.from({ length: Constants.TOTAL_SLOTS }, (_v: Object, k: number) => k + 1), (slot: number) => {
          Column() {
            Text('第' + slot + '节')
              .fontSize(13)
              .fontColor(slot === this.selectedEndSlot ? Color.White : '#333333')
          }
          .height(36)
          .padding({ left: 12, right: 12 })
          .borderRadius(18)
          .backgroundColor(slot === this.selectedEndSlot ? '#4CAF50' : '#F0F0F0')
          .justifyContent(FlexAlign.Center)
          .margin(4)
          .onClick(() => {
            this.selectedEndSlot = slot;
            if (this.selectedEndSlot < this.selectedStartSlot) {
              this.selectedEndSlot = this.selectedStartSlot;
            }
          })
        }, (slot: number) => 'end_' + slot.toString())
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .alignItems(HorizontalAlign.Start)
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
          .backgroundColor(type === this.selectedWeekType ? '#4CAF50' : '#F0F0F0')
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

  private saveCourse(): void {
    if (this.inputName.trim() === '') {
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
      Constants.COURSE_COLORS[this.selectedColorIndex],
      this.selectedWeekType
    );
    if (this.viewModel.hasConflict(course, this.course.id)) {
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
            .backgroundColor('#2196F3')
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
