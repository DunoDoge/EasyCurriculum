import { CourseViewModel } from '../viewmodel/CourseViewModel';
import { CourseInfo, getWeekTypeName, TimeSlot, Timetable } from '../model/CourseModel';
import { WeekDay, getWeekDayList, getWeekDayName } from '../model/WeekDay';
import { Constants } from '../common/constants/Constants';
import { CourseCard } from '../components/CourseCard';
import { WeekHeader } from '../components/WeekHeader';
import { TimeSlotHeader } from '../components/TimeSlotHeader';
import { DayView } from '../components/DayView';
import { SemesterSettingPage } from './SemesterSettingPage';
import { ImportExportUtil } from '../common/utils/ImportExportUtil';
import { ShareUtil } from '../common/utils/ShareUtil';
import { Logger } from '../common/utils/Logger';
import { promptAction } from '@kit.ArkUI';
import { componentSnapshot } from '@kit.ArkUI';
import { image } from '@kit.ImageKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { TimeSlotCard } from '../components/TimeSlotCard';
import { CourseSlotDisplay } from '../viewmodel/CourseViewModel';

@Entry
@ComponentV2
struct Index {
  @Local viewModel: CourseViewModel = new CourseViewModel();
  navPathStack: NavPathStack = new NavPathStack();
  @Local showWeekPicker: boolean = false;
  @Local showTimetablePicker: boolean = false;
  @Local showNewTimetableDialog: boolean = false;
  @Local newTimetableName: string = '';
  @Local showImportExportPanel: boolean = false;
  @Local showSharePanel: boolean = false;
  @Local showImportPreview: boolean = false;
  @Local importPreviewTimetable: Timetable | null = null;

  aboutToAppear(): void {
    this.viewModel.init(this.getUIContext().getHostContext() as common.UIAbilityContext);
  }

  private showToast(message: string): void {
    try {
      promptAction.showToast({ message: message });
    } catch (error) {
      let e: BusinessError = error as BusinessError;
      console.error('showToast error: ' + JSON.stringify(e));
    }
  }

  private async handleExportToFile(): Promise<void> {
    if (this.viewModel.currentTimetable === null) {
      this.showToast('当前没有课表可导出');
      return;
    }
    let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    let success = await ImportExportUtil.exportToFile(context, this.viewModel.currentTimetable);
    if (success) {
      this.showToast('导出成功');
    } else {
      this.showToast('导出失败或已取消');
    }
  }

  private async handleExportToClipboard(): Promise<void> {
    if (this.viewModel.currentTimetable === null) {
      this.showToast('当前没有课表可导出');
      return;
    }
    let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    let success = await ImportExportUtil.exportToClipboard(context, this.viewModel.currentTimetable);
    if (success) {
      this.showToast('已复制到剪贴板');
    } else {
      this.showToast('导出到剪贴板失败');
    }
  }

  private async handleImportFromFile(): Promise<void> {
    let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    let timetable = await ImportExportUtil.importFromFile(context);
    if (timetable !== null) {
      this.importPreviewTimetable = timetable;
      this.showImportPreview = true;
    } else {
      this.showToast('导入失败或已取消');
    }
  }

  private async handleImportFromClipboard(): Promise<void> {
    let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    let timetable = await ImportExportUtil.importFromClipboard(context);
    if (timetable !== null) {
      this.importPreviewTimetable = timetable;
      this.showImportPreview = true;
    } else {
      this.showToast('剪贴板中没有有效的课表数据');
    }
  }

  private async confirmImport(): Promise<void> {
    if (this.importPreviewTimetable === null) {
      return;
    }
    let imported = await this.viewModel.importTimetable(this.importPreviewTimetable);
    await this.viewModel.switchTimetable(imported.id);
    this.showImportPreview = false;
    this.importPreviewTimetable = null;
    this.showToast('导入成功');
  }

  private async generateScheduleImage(): Promise<string | null> {
    try {
      let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      let componentId = this.viewModel.viewMode === 'week' ? 'weekViewForShare' : 'dayViewForShare';

      let pixelMap = await componentSnapshot.get(componentId);

      let imagePacker = image.createImagePacker();
      let packOpts: image.PackingOption = { format: 'image/png', quality: 100 };
      let arrayBuffer = await imagePacker.packing(pixelMap, packOpts);

      let fileName = this.viewModel.currentTimetableName + '_课表.png';
      let fileUri = await ShareUtil.saveToTempFile(context, arrayBuffer, fileName);

      Logger.info('Generate schedule image success: ' + fileUri);
      return fileUri;
    } catch (err) {
      let error = err as Error;
      Logger.error('Generate schedule image failed: ' + error.message);
      return null;
    }
  }

  private async handleShareAsImage(): Promise<void> {
    if (this.viewModel.currentTimetable === null) {
      this.showToast('当前没有课表可分享');
      return;
    }

    let imageUri = await this.generateScheduleImage();
    if (imageUri === null) {
      this.showToast('图片生成失败，请重试');
      return;
    }

    let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    let success = await ShareUtil.shareImage(context, imageUri);

    if (!success) {
      ShareUtil.cleanupTempFile(imageUri);
      this.showToast('分享失败或已取消');
    }
  }

  private async handleShareAsFile(): Promise<void> {
    if (this.viewModel.currentTimetable === null) {
      this.showToast('当前没有课表可分享');
      return;
    }

    let context = this.getUIContext().getHostContext() as common.UIAbilityContext;

    let jsonStr = ImportExportUtil.timetableToJsonString(this.viewModel.currentTimetable);

    let fileName = this.viewModel.currentTimetableName + '_课表.json';
    let fileUri = await ShareUtil.saveToTempFile(context, jsonStr, fileName);

    let success = await ShareUtil.shareFile(context, fileUri);

    if (!success) {
      ShareUtil.cleanupTempFile(fileUri);
      this.showToast('分享失败或已取消');
    }
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
            Text('⇄')
              .fontSize(18)
              .fontColor('#666666')
          }
          .type(ButtonType.Circle)
          .width(36)
          .height(36)
          .backgroundColor('#E0E0E0')
          .margin({ left: 12 })
          .onClick(() => {
            this.showImportExportPanel = !this.showImportExportPanel;
            this.showSharePanel = false;
          })

          Button() {
            Image($r('app.media.ic_public_share'))
              .width(24)
          }
          .type(ButtonType.Circle)
          .width(36)
          .height(36)
          .backgroundColor('#E0E0E0')
          .margin({ left: 12 })
          .onClick(() => {
            this.showSharePanel = !this.showSharePanel;
            this.showImportExportPanel = false;
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
          .id('weekViewForShare')
          .parallelGesture(
            PanGesture({ fingers: 1, direction: PanDirection.Horizontal, distance: 50 })
              .onActionEnd((event: GestureEvent) => {
                if (event.offsetX < -Constants.SWIPE_THRESHOLD) {
                  this.viewModel.nextWeek();
                } else if (event.offsetX > Constants.SWIPE_THRESHOLD) {
                  this.viewModel.prevWeek();
                }
              })
          )
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
              let newTs = newCourse.timeSlots[0];
              newTs.weekDay = this.viewModel.selectedWeekDay;
              newTs.startSlot = slot;
              newTs.endSlot = slot;
              newTs.startWeek = this.viewModel.currentWeek;
              newTs.endWeek = this.viewModel.currentWeek;
              this.navPathStack.pushPath({
                name: 'CourseEditPage',
                param: newCourse
              });
            },
            onSwipePrev: () => {
              this.viewModel.prevDay();
            },
            onSwipeNext: () => {
              this.viewModel.nextDay();
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
                    try {
                      promptAction.showToast({ message: '请输入课表名称' });
                    } catch (error) {
                      let e: BusinessError = error as BusinessError;
                      console.error('showToast error: ' + JSON.stringify(e));
                    }
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

        // 导入导出弹出菜单
        if (this.showImportExportPanel) {
          Column() {
            Column() {
              Text('导出为文件')
                .fontSize(15)
                .fontColor('#333333')
                .width('100%')
                .height(44)
                .padding({ left: 16, right: 16 })
                .onClick(() => {
                  this.showImportExportPanel = false;
                  this.handleExportToFile();
                })

              Divider().color('#F0F0F0').margin({ left: 12, right: 12 })

              Text('复制到剪贴板')
                .fontSize(15)
                .fontColor('#333333')
                .width('100%')
                .height(44)
                .padding({ left: 16, right: 16 })
                .onClick(() => {
                  this.showImportExportPanel = false;
                  this.handleExportToClipboard();
                })

              Divider().color('#F0F0F0').margin({ left: 12, right: 12 })

              Text('从文件导入')
                .fontSize(15)
                .fontColor('#333333')
                .width('100%')
                .height(44)
                .padding({ left: 16, right: 16 })
                .onClick(() => {
                  this.showImportExportPanel = false;
                  this.handleImportFromFile();
                })

              Divider().color('#F0F0F0').margin({ left: 12, right: 12 })

              Text('从剪贴板导入')
                .fontSize(15)
                .fontColor('#333333')
                .width('100%')
                .height(44)
                .padding({ left: 16, right: 16 })
                .onClick(() => {
                  this.showImportExportPanel = false;
                  this.handleImportFromClipboard();
                })
            }
            .backgroundColor(Color.White)
            .borderRadius(8)
            .shadow({ radius: 8, color: '#33000000', offsetY: 2 })
          }
          .position({ x: '65%', y: 52 })
          .zIndex(999)
        }

        // 分享弹出菜单
        if (this.showSharePanel) {
          Column() {
            Column() {
              Text('分享为图片')
                .fontSize(15)
                .fontColor('#333333')
                .width('100%')
                .height(44)
                .padding({ left: 16, right: 16 })
                .onClick(() => {
                  this.showSharePanel = false;
                  this.handleShareAsImage();
                })

              Divider().color('#F0F0F0').margin({ left: 12, right: 12 })

              Text('分享为文件')
                .fontSize(15)
                .fontColor('#333333')
                .width('100%')
                .height(44)
                .padding({ left: 16, right: 16 })
                .onClick(() => {
                  this.showSharePanel = false;
                  this.handleShareAsFile();
                })
            }
            .backgroundColor(Color.White)
            .borderRadius(8)
            .shadow({ radius: 8, color: '#33000000', offsetY: 2 })
          }
          .position({ x: '55%', y: 52 })
          .zIndex(999)
        }

        // 导入预览弹窗
        if (this.showImportPreview && this.importPreviewTimetable !== null) {
          Column() {
            Column() {
              Text('导入预览')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333333')
                .margin({ bottom: 16 })

              Row() {
                Text('课表名称')
                  .fontSize(14)
                  .fontColor('#999999')
                  .width(70)
                Text(this.importPreviewTimetable!.name)
                  .fontSize(15)
                  .fontColor('#333333')
                  .layoutWeight(1)
              }
              .width('100%')
              .margin({ bottom: 8 })

              Row() {
                Text('课程数量')
                  .fontSize(14)
                  .fontColor('#999999')
                  .width(70)
                Text(this.importPreviewTimetable!.courses.length.toString() + '门')
                  .fontSize(15)
                  .fontColor('#333333')
                  .layoutWeight(1)
              }
              .width('100%')
              .margin({ bottom: 8 })

              if (this.importPreviewTimetable!.semesterStartDate !== '') {
                Row() {
                  Text('学期日期')
                    .fontSize(14)
                    .fontColor('#999999')
                    .width(70)
                  Text(this.importPreviewTimetable!.semesterStartDate)
                    .fontSize(15)
                    .fontColor('#333333')
                    .layoutWeight(1)
                }
                .width('100%')
                .margin({ bottom: 8 })
              }

              Row() {
                Text('每天节数')
                  .fontSize(14)
                  .fontColor('#999999')
                  .width(70)
                Text(this.importPreviewTimetable!.totalSlots.toString() + '节')
                  .fontSize(15)
                  .fontColor('#333333')
                  .layoutWeight(1)
              }
              .width('100%')
              .margin({ bottom: 8 })

              Row() {
                Text('学期周数')
                  .fontSize(14)
                  .fontColor('#999999')
                  .width(70)
                Text(this.importPreviewTimetable!.totalWeeks.toString() + '周')
                  .fontSize(15)
                  .fontColor('#333333')
                  .layoutWeight(1)
              }
              .width('100%')
              .margin({ bottom: 12 })

              if (this.importPreviewTimetable!.courses.length > 0) {
                Divider().color('#F0F0F0').margin({ bottom: 8 })

                Text('课程列表')
                  .fontSize(13)
                  .fontColor('#999999')
                  .margin({ bottom: 6 })
                  .alignSelf(ItemAlign.Start)

                Scroll() {
                  Column() {
                    ForEach(this.importPreviewTimetable!.courses, (course: CourseInfo, index: number) => {
                      Row() {
                        Column()
                          .width(4)
                          .height(20)
                          .borderRadius(2)
                          .backgroundColor(course.color)
                          .margin({ right: 8 })

                        Text(course.name)
                          .fontSize(14)
                          .fontColor('#333333')
                          .layoutWeight(1)

                        if (course.timeSlots.length > 0 && course.timeSlots[0].teacher !== '') {
                          Text(course.timeSlots[0].teacher)
                            .fontSize(12)
                            .fontColor('#999999')
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                            .constraintSize({ maxWidth: 80 })
                        }
                      }
                      .width('100%')
                      .height(32)
                      .alignItems(VerticalAlign.Center)
                    }, (course: CourseInfo) => course.id + '_' + course.name)
                  }
                }
                .height(Math.min(this.importPreviewTimetable!.courses.length * 32, 160))
                .scrollBar(BarState.Auto)
              }

              Row() {
                Button('取消')
                  .fontSize(16)
                  .fontColor('#666666')
                  .backgroundColor('#B4C6E7')
                  .borderRadius(8)
                  .layoutWeight(1)
                  .height(44)
                  .onClick(() => {
                    this.showImportPreview = false;
                    this.importPreviewTimetable = null;
                  })

                Button('导入')
                  .fontSize(16)
                  .fontColor(Color.White)
                  .backgroundColor('#5B9BD5')
                  .borderRadius(8)
                  .layoutWeight(1)
                  .height(44)
                  .margin({ left: 12 })
                  .onClick(() => {
                    this.confirmImport();
                  })
              }
              .width('100%')
              .margin({ top: 16 })
            }
            .width('85%')
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
                let newTs = newCourse.timeSlots[0];
                newTs.weekDay = day;
                newTs.startSlot = slot;
                newTs.endSlot = slot;
                newTs.startWeek = this.viewModel.currentWeek;
                newTs.endWeek = this.viewModel.currentWeek;
                this.navPathStack.pushPath({
                  name: 'CourseEditPage',
                  param: newCourse
                });
              }
            })
        }, (slot: number) => slot.toString())
      }

      ForEach(this.viewModel.getCourseSlotsByDay(day), (csd: CourseSlotDisplay) => {
        CourseCard({
          course: csd.course,
          displayStartSlot: csd.timeSlot.startSlot,
          displayEndSlot: csd.timeSlot.endSlot,
          displayTeacher: csd.timeSlot.teacher,
          displayLocation: csd.timeSlot.location,
          onCardClick: (clickedCourse: CourseInfo) => {
            this.navPathStack.pushPath({
              name: 'CourseDetailPage',
              param: clickedCourse
            });
          }
        })
      }, (csd: CourseSlotDisplay, index: number) => csd.course.id + '_' + index.toString() + '_v' + this.viewModel.dataVersion.toString())
    }
    .layoutWeight(1)
    .height(this.viewModel.currentTotalSlots * Constants.SLOT_HEIGHT)
    .clip(false)
  }
}

@ComponentV2
struct CourseEditPage {
  @Require @Param course: CourseInfo;
  @Require @Param viewModel: CourseViewModel;
  @Require @Param navPathStack: NavPathStack;
  @Local selectedColorIndex: number = 0;
  @Local inputName: string = '';
  @Local timeSlots: TimeSlot[] = [];

  formatConflictWeeks(weeks: number[]): string {
    if (weeks.length === 0) {
      return '';
    }
    let parts: string[] = [];
    let rangeStart = weeks[0];
    let rangeEnd = weeks[0];
    for (let i = 1; i < weeks.length; i++) {
      if (weeks[i] === rangeEnd + 1) {
        rangeEnd = weeks[i];
      } else {
        if (rangeStart === rangeEnd) {
          parts.push(`${rangeStart}`);
        } else {
          parts.push(`${rangeStart}-${rangeEnd}`);
        }
        rangeStart = weeks[i];
        rangeEnd = weeks[i];
      }
    }
    if (rangeStart === rangeEnd) {
      parts.push(`${rangeStart}`);
    } else {
      parts.push(`${rangeStart}-${rangeEnd}`);
    }
    return parts.join(',') + '周';
  }

  aboutToAppear(): void {
    this.inputName = this.course.name;
    // 深拷贝timeSlots以避免直接修改原数据
    let copiedSlots: TimeSlot[] = [];
    for (let i = 0; i < this.course.timeSlots.length; i++) {
      let ts = this.course.timeSlots[i];
      copiedSlots.push(new TimeSlot(ts.weekDay, ts.startSlot, ts.endSlot, ts.startWeek, ts.endWeek, ts.weekType, ts.teacher, ts.location));
    }
    this.timeSlots = copiedSlots;
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
          // 课程名称
          Column() {
            Text('课程名称')
              .fontSize(14)
              .fontColor('#333333')
              .margin({ bottom: 8 })

            TextInput({ text: this.inputName })
              .fontSize(16)
              .width('100%')
              .height(44)
              .borderRadius(8)
              .backgroundColor(Color.White)
              .borderWidth(1)
              .borderColor('#E0E0E0')
              .onChange((value: string) => {
                this.inputName = value;
              })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })
          .alignItems(HorizontalAlign.Start)

          // 颜色选择器
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

          // 时间段卡片列表
          ForEach(this.timeSlots, (ts: TimeSlot, index: number) => {
            Column() {
              TimeSlotCard({
                timeSlot: ts,
                slotIndex: index + 1,
                totalSlotCount: this.timeSlots.length,
                maxSlotNumber: this.viewModel.currentTotalSlots,
                maxWeekNumber: this.viewModel.currentTotalWeeks,
                onDelete: () => {
                  this.timeSlots.splice(index, 1);
                  let newSlots: TimeSlot[] = [];
                  for (let i = 0; i < this.timeSlots.length; i++) {
                    newSlots.push(this.timeSlots[i]);
                  }
                  this.timeSlots = newSlots;
                }
              })
            }
            .padding({ left: 16, right: 16, top: 6, bottom: 6 })
          }, (_: TimeSlot, index: number) => index.toString())

          // 添加时间段按钮
          Row() {
            Text('+ 添加时间段')
              .fontSize(15)
              .fontColor('#5B9BD5')
              .fontWeight(FontWeight.Medium)
          }
          .width('100%')
          .height(48)
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          .backgroundColor(Color.White)
          .borderRadius(12)
          .borderWidth(1)
          .borderColor('#E0E0E0')
          .margin({ left: 16, right: 16, top: 8, bottom: 8 })
          .onClick(() => {
            let newSlots: TimeSlot[] = [];
            for (let i = 0; i < this.timeSlots.length; i++) {
              newSlots.push(this.timeSlots[i]);
            }
            newSlots.push(TimeSlot.createDefault());
            this.timeSlots = newSlots;
          })

          // 保存/取消按钮
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

  private saveCourse(): void {
    if (this.inputName.trim() === '') {
      try {
        promptAction.showToast({ message: '请输入课程名称' });
      } catch (error) {
        let e: BusinessError = error as BusinessError;
        console.error('showToast error: ' + JSON.stringify(e));
      }
      return;
    }
    let course = new CourseInfo(
      this.course.id,
      this.inputName,
      Constants.COURSE_COLORS[this.selectedColorIndex],
      this.timeSlots
    );
    let conflictDetail = this.viewModel.findConflict(course, this.course.id);
    if (conflictDetail !== undefined) {
      let weekDayName = getWeekDayName(conflictDetail.conflictWeekDay);
      let weeksStr = this.formatConflictWeeks(conflictDetail.conflictWeeks);
      let msg = `与"${conflictDetail.conflictCourseName}"在${weekDayName}第${conflictDetail.conflictStartSlot}-${conflictDetail.conflictEndSlot}节的第${weeksStr}存在冲突`;
      try {
        promptAction.showToast({ message: msg });
      } catch (error) {
        let e: BusinessError = error as BusinessError;
        console.error('showToast error: ' + JSON.stringify(e));
      }
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

@ComponentV2
struct CourseDetailPage {
  @Require @Param course: CourseInfo;
  @Require @Param viewModel: CourseViewModel;
  @Require @Param navPathStack: NavPathStack;

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
        Scroll() {
          Column() {
            ForEach(this.course.timeSlots, (ts: TimeSlot, index: number) => {
              Column() {
                if (this.course.timeSlots.length > 1) {
                  Text('时间段' + (index + 1))
                    .fontSize(15)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#5B9BD5')
                    .width('100%')
                    .margin({ bottom: 8, top: index > 0 ? 12 : 0 })
                }

                this.DetailRow('教师', ts.teacher);
                this.DetailRow('教室', ts.location);
                this.DetailRow('星期', getWeekDayName(ts.weekDay as WeekDay));
                this.DetailRow('节次', '第' + ts.startSlot + '-' + ts.endSlot + '节');
                this.DetailRow('周次', '第' + ts.startWeek + '-' + ts.endWeek + '周');
                this.DetailRow('周类型', getWeekTypeName(ts.weekType));
              }
              .width('100%')
              .padding(16)
              .backgroundColor(Color.White)
              .borderRadius(12)
              .margin({ bottom: index < this.course.timeSlots.length - 1 ? 12 : 0 })
            }, (_: TimeSlot, index: number) => index.toString())
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 0, bottom: 16 })
          .alignItems(HorizontalAlign.Start)
        }
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Auto)
        .width('100%')
        .layoutWeight(1)
        .align(Alignment.Top)

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