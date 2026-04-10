import { preferences } from '@kit.ArkData';
import { Context } from '@kit.AbilityKit';
import { CourseInfo, SemesterConfig } from '../model/CourseModel';
import { Constants } from '../common/constants/Constants';
import { Logger } from '../common/utils/Logger';

@Observed
export class CourseViewModel {
  courses: CourseInfo[] = [];
  currentWeek: number = 1;
  semesterStartDate: string = '';
  viewMode: string = 'week';
  selectedWeekDay: number = 0;
  private prefs: preferences.Preferences | null = null;

  async init(context: Context): Promise<void> {
    try {
      this.prefs = await preferences.getPreferences(context, Constants.PREFERENCES_NAME);
      await this.loadCourses();
      await this.loadSemesterConfig();
      this.calculateCurrentWeekFromToday();
      Logger.info('CourseViewModel init success');
    } catch (err) {
      let error = err as Error;
      Logger.error('CourseViewModel init failed: ' + error.message);
    }
  }

  async loadCourses(): Promise<void> {
    if (this.prefs === null) {
      return;
    }
    try {
      let dataStr = await this.prefs.get(Constants.COURSE_DATA_KEY, '[]') as string;
      let jsonArray: Record<string, Object>[] = JSON.parse(dataStr) as Record<string, Object>[];
      this.courses = [];
      for (let i = 0; i < jsonArray.length; i++) {
        let course = CourseInfo.fromJson(jsonArray[i]);
        this.courses.push(course);
      }
      Logger.info('Loaded ' + this.courses.length + ' courses');
    } catch (err) {
      let error = err as Error;
      Logger.error('Load courses failed: ' + error.message);
    }
  }

  async loadSemesterConfig(): Promise<void> {
    if (this.prefs === null) {
      return;
    }
    try {
      let dataStr = await this.prefs.get(Constants.SEMESTER_CONFIG_KEY, '') as string;
      if (dataStr === '') {
        this.semesterStartDate = '';
        return;
      }
      let json: Record<string, Object> = JSON.parse(dataStr) as Record<string, Object>;
      let config = SemesterConfig.fromJson(json);
      this.semesterStartDate = config.startDate;
      Logger.info('Loaded semester config: ' + this.semesterStartDate);
    } catch (err) {
      let error = err as Error;
      Logger.error('Load semester config failed: ' + error.message);
    }
  }

  async saveSemesterConfig(startDate: string): Promise<void> {
    if (this.prefs === null) {
      return;
    }
    try {
      let config = new SemesterConfig(startDate);
      let dataStr = JSON.stringify(config.toJson());
      await this.prefs.put(Constants.SEMESTER_CONFIG_KEY, dataStr);
      await this.prefs.flush();
      this.semesterStartDate = startDate;
      Logger.info('Saved semester config: ' + startDate);
    } catch (err) {
      let error = err as Error;
      Logger.error('Save semester config failed: ' + error.message);
    }
  }

  calculateCurrentWeekFromToday(): void {
    if (this.semesterStartDate === '') {
      return;
    }
    let week = this.calculateWeekFromDate(new Date());
    if (week < 1) {
      week = 1;
    }
    if (week > Constants.TOTAL_WEEKS) {
      week = Constants.TOTAL_WEEKS;
    }
    this.currentWeek = week;
  }

  calculateWeekFromDate(date: Date): number {
    if (this.semesterStartDate === '') {
      return 1;
    }
    let parts: string[] = this.semesterStartDate.split('-');
    let startYear = Number(parts[0]);
    let startMonth = Number(parts[1]) - 1;
    let startDay = Number(parts[2]);
    let startDate = new Date(startYear, startMonth, startDay);
    let diffMs = date.getTime() - startDate.getTime();
    let diffDays = diffMs / (1000 * 60 * 60 * 24);
    return Math.floor(diffDays / 7) + 1;
  }

  getDayDate(weekDay: number): string {
    if (this.semesterStartDate === '') {
      return '';
    }
    let parts: string[] = this.semesterStartDate.split('-');
    let startYear = Number(parts[0]);
    let startMonth = Number(parts[1]) - 1;
    let startDay = Number(parts[2]);
    let startDate = new Date(startYear, startMonth, startDay);
    let offsetDays = (this.currentWeek - 1) * 7 + (weekDay - 1);
    let targetDate = new Date(startDate.getTime() + offsetDays * 24 * 60 * 60 * 1000);
    let month = targetDate.getMonth() + 1;
    let day = targetDate.getDate();
    return month + '/' + day;
  }

  isToday(weekDay: number): boolean {
    if (this.semesterStartDate === '') {
      return false;
    }
    let today = new Date();
    let parts: string[] = this.semesterStartDate.split('-');
    let startYear = Number(parts[0]);
    let startMonth = Number(parts[1]) - 1;
    let startDay = Number(parts[2]);
    let startDate = new Date(startYear, startMonth, startDay);
    let offsetDays = (this.currentWeek - 1) * 7 + (weekDay - 1);
    let targetDate = new Date(startDate.getTime() + offsetDays * 24 * 60 * 60 * 1000);
    return today.getFullYear() === targetDate.getFullYear() &&
      today.getMonth() === targetDate.getMonth() &&
      today.getDate() === targetDate.getDate();
  }

  getWeekDateRange(): string {
    if (this.semesterStartDate === '') {
      return '';
    }
    let parts: string[] = this.semesterStartDate.split('-');
    let startYear = Number(parts[0]);
    let startMonth = Number(parts[1]) - 1;
    let startDay = Number(parts[2]);
    let startDate = new Date(startYear, startMonth, startDay);
    let weekStartOffset = (this.currentWeek - 1) * 7;
    let weekStartDate = new Date(startDate.getTime() + weekStartOffset * 24 * 60 * 60 * 1000);
    let weekEndDate = new Date(startDate.getTime() + (weekStartOffset + 6) * 24 * 60 * 60 * 1000);
    let startMonthNum = weekStartDate.getMonth() + 1;
    let startDayNum = weekStartDate.getDate();
    let endMonthNum = weekEndDate.getMonth() + 1;
    let endDayNum = weekEndDate.getDate();
    return startMonthNum + '月' + startDayNum + '日 - ' + endMonthNum + '月' + endDayNum + '日';
  }

  goToToday(): void {
    this.calculateCurrentWeekFromToday();
  }

  switchToDayView(weekDay: number): void {
    this.viewMode = 'day';
    this.selectedWeekDay = weekDay;
  }

  switchToWeekView(): void {
    this.viewMode = 'week';
    this.selectedWeekDay = 0;
  }

  getMonthOfWeek(): number {
    if (this.semesterStartDate === '') {
      return 0;
    }
    let parts: string[] = this.semesterStartDate.split('-');
    let startYear = Number(parts[0]);
    let startMonth = Number(parts[1]) - 1;
    let startDay = Number(parts[2]);
    let startDate = new Date(startYear, startMonth, startDay);
    let weekStartOffset = (this.currentWeek - 1) * 7;
    let mondayDate = new Date(startDate.getTime() + weekStartOffset * 24 * 60 * 60 * 1000);
    return mondayDate.getMonth() + 1;
  }

  getDayDateOfMonth(weekDay: number): number {
    if (this.semesterStartDate === '') {
      return 0;
    }
    let parts: string[] = this.semesterStartDate.split('-');
    let startYear = Number(parts[0]);
    let startMonth = Number(parts[1]) - 1;
    let startDay = Number(parts[2]);
    let startDate = new Date(startYear, startMonth, startDay);
    let offsetDays = (this.currentWeek - 1) * 7 + (weekDay - 1);
    let targetDate = new Date(startDate.getTime() + offsetDays * 24 * 60 * 60 * 1000);
    return targetDate.getDate();
  }

  getDayFullDate(): string {
    if (this.semesterStartDate === '') {
      return '';
    }
    let parts: string[] = this.semesterStartDate.split('-');
    let startYear = Number(parts[0]);
    let startMonth = Number(parts[1]) - 1;
    let startDay = Number(parts[2]);
    let startDate = new Date(startYear, startMonth, startDay);
    let offsetDays = (this.currentWeek - 1) * 7 + (this.selectedWeekDay - 1);
    let targetDate = new Date(startDate.getTime() + offsetDays * 24 * 60 * 60 * 1000);
    let month = targetDate.getMonth() + 1;
    let day = targetDate.getDate();
    return month + '月' + day + '日';
  }

  async saveCourses(): Promise<void> {
    if (this.prefs === null) {
      return;
    }
    try {
      let jsonArray: Record<string, Object>[] = [];
      for (let i = 0; i < this.courses.length; i++) {
        jsonArray.push(this.courses[i].toJson());
      }
      let dataStr = JSON.stringify(jsonArray);
      await this.prefs.put(Constants.COURSE_DATA_KEY, dataStr);
      await this.prefs.flush();
      Logger.info('Saved ' + this.courses.length + ' courses');
    } catch (err) {
      let error = err as Error;
      Logger.error('Save courses failed: ' + error.message);
    }
  }

  async addCourse(course: CourseInfo): Promise<void> {
    if (course.id === '') {
      course.id = this.generateId();
    }
    this.courses = [...this.courses, course];
    await this.saveCourses();
  }

  async updateCourse(course: CourseInfo): Promise<void> {
    for (let i = 0; i < this.courses.length; i++) {
      if (this.courses[i].id === course.id) {
        this.courses[i].name = course.name;
        this.courses[i].teacher = course.teacher;
        this.courses[i].location = course.location;
        this.courses[i].weekDay = course.weekDay;
        this.courses[i].startSlot = course.startSlot;
        this.courses[i].endSlot = course.endSlot;
        this.courses[i].color = course.color;
        this.courses[i].weekType = course.weekType;
        this.courses[i].startWeek = course.startWeek;
        this.courses[i].endWeek = course.endWeek;
        break;
      }
    }
    this.courses = [...this.courses];
    await this.saveCourses();
  }

  async deleteCourse(id: string): Promise<void> {
    this.courses = this.courses.filter((course: CourseInfo) => course.id !== id);
    await this.saveCourses();
  }

  getCourseById(id: string): CourseInfo | null {
    for (let i = 0; i < this.courses.length; i++) {
      if (this.courses[i].id === id) {
        return this.courses[i];
      }
    }
    return null;
  }

  getCoursesByDay(weekDay: number): CourseInfo[] {
    let result: CourseInfo[] = [];
    for (let i = 0; i < this.courses.length; i++) {
      if (this.courses[i].weekDay === weekDay && this.courses[i].isOnWeek(this.currentWeek)) {
        result.push(this.courses[i]);
      }
    }
    return result;
  }

  getCourseAtSlot(weekDay: number, slot: number): CourseInfo | undefined {
    for (let i = 0; i < this.courses.length; i++) {
      let course = this.courses[i];
      if (course.weekDay === weekDay && slot >= course.startSlot && slot <= course.endSlot && course.isOnWeek(this.currentWeek)) {
        return course;
      }
    }
    return undefined;
  }

  hasConflict(course: CourseInfo, excludeId: string): boolean {
    for (let i = 0; i < this.courses.length; i++) {
      let existing = this.courses[i];
      if (existing.id === excludeId) {
        continue;
      }
      if (existing.weekDay === course.weekDay) {
        if (course.startSlot <= existing.endSlot && course.endSlot >= existing.startSlot) {
          if (course.startWeek <= existing.endWeek && course.endWeek >= existing.startWeek) {
            return true;
          }
        }
      }
    }
    return false;
  }

  prevWeek(): void {
    if (this.currentWeek > 1) {
      this.currentWeek = this.currentWeek - 1;
    }
  }

  nextWeek(): void {
    if (this.currentWeek < Constants.TOTAL_WEEKS) {
      this.currentWeek = this.currentWeek + 1;
    }
  }

  private generateId(): string {
    return Date.now().toString() + Math.floor(Math.random() * 1000).toString();
  }
}
