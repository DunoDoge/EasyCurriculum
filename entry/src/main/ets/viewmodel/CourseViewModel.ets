import { preferences } from '@kit.ArkData';
import { Context } from '@kit.AbilityKit';
import { CourseInfo, SemesterConfig, Timetable } from '../model/CourseModel';
import { Constants } from '../common/constants/Constants';
import { Logger } from '../common/utils/Logger';

@Observed
export class CourseViewModel {
  timetables: Timetable[] = [];
  currentTimetableId: string = '';
  currentTimetable: Timetable | null = null;
  currentWeek: number = 1;
  semesterStartDate: string = '';
  viewMode: string = 'week';
  selectedWeekDay: number = 0;
  private prefs: preferences.Preferences | null = null;

  get currentTimetableName(): string {
    if (this.currentTimetable !== null) {
      return this.currentTimetable.name;
    }
    return '我的课表';
  }

  get courses(): CourseInfo[] {
    if (this.currentTimetable !== null) {
      return this.currentTimetable.courses;
    }
    return [];
  }

  get currentTotalSlots(): number {
    if (this.currentTimetable !== null) {
      return this.currentTimetable.totalSlots;
    }
    return 13;
  }

  get currentTotalWeeks(): number {
    if (this.currentTimetable !== null) {
      return this.currentTimetable.totalWeeks;
    }
    return 20;
  }

  async init(context: Context): Promise<void> {
    try {
      this.prefs = await preferences.getPreferences(context, Constants.PREFERENCES_NAME);
      await this.loadTimetables();
      this.initCurrentTimetable();
      this.calculateCurrentWeekFromToday();
      Logger.info('CourseViewModel init success, timetables count: ' + this.timetables.length);
    } catch (err) {
      let error = err as Error;
      Logger.error('CourseViewModel init failed: ' + error.message);
    }
  }

  private initCurrentTimetable(): void {
    if (this.timetables.length === 0) {
      let defaultTimetable = Timetable.createDefault();
      defaultTimetable.id = Timetable.generateId();
      this.timetables.push(defaultTimetable);
      this.currentTimetableId = defaultTimetable.id;
      this.currentTimetable = defaultTimetable;
      this.semesterStartDate = '';
      this.persistTimetables();
    } else {
      let found = false;
      for (let i = 0; i < this.timetables.length; i++) {
        if (this.timetables[i].id === this.currentTimetableId) {
          this.currentTimetable = this.timetables[i];
          this.semesterStartDate = this.currentTimetable.semesterStartDate;
          found = true;
          break;
        }
      }
      if (!found) {
        this.currentTimetable = this.timetables[0];
        this.currentTimetableId = this.currentTimetable.id;
        this.semesterStartDate = this.currentTimetable.semesterStartDate;
      }
    }
  }

  async loadTimetables(): Promise<void> {
    if (this.prefs === null) {
      return;
    }
    try {
      let timetablesDataStr = await this.prefs.get(Constants.TIMETABLES_KEY, '') as string;
      let currentIdStr = await this.prefs.get(Constants.CURRENT_TIMETABLE_ID_KEY, '') as string;
      this.currentTimetableId = currentIdStr;

      if (timetablesDataStr === '') {
        await this.migrateFromOldData();
        return;
      }

      let jsonArray: Record<string, Object>[] = JSON.parse(timetablesDataStr) as Record<string, Object>[];
      this.timetables = [];
      for (let i = 0; i < jsonArray.length; i++) {
        let timetable = Timetable.fromJson(jsonArray[i]);
        this.timetables.push(timetable);
      }
      Logger.info('Loaded ' + this.timetables.length + ' timetables');
    } catch (err) {
      let error = err as Error;
      Logger.error('Load timetables failed: ' + error.message);
      await this.migrateFromOldData();
    }
  }

  private async migrateFromOldData(): Promise<void> {
    if (this.prefs === null) {
      return;
    }
    try {
      let courseDataStr = await this.prefs.get(Constants.COURSE_DATA_KEY, '[]') as string;
      let jsonArray: Record<string, Object>[] = JSON.parse(courseDataStr) as Record<string, Object>[];

      let timetable = Timetable.createDefault();
      timetable.id = Timetable.generateId();
      timetable.name = '我的课表';

      for (let i = 0; i < jsonArray.length; i++) {
        let course = CourseInfo.fromJson(jsonArray[i]);
        timetable.courses.push(course);
      }

      let configStr = await this.prefs.get(Constants.SEMESTER_CONFIG_KEY, '') as string;
      if (configStr !== '') {
        let configJson: Record<string, Object> = JSON.parse(configStr) as Record<string, Object>;
        let config = SemesterConfig.fromJson(configJson);
        timetable.semesterStartDate = config.startDate;
      }

      this.timetables = [timetable];
      this.currentTimetableId = timetable.id;
      this.currentTimetable = timetable;
      this.semesterStartDate = timetable.semesterStartDate;

      await this.persistTimetables();
      Logger.info('Migrated from old data, courses count: ' + timetable.courses.length);
    } catch (err) {
      let error = err as Error;
      Logger.error('Migrate from old data failed: ' + error.message);
      let defaultTimetable = Timetable.createDefault();
      defaultTimetable.id = Timetable.generateId();
      this.timetables = [defaultTimetable];
      this.currentTimetableId = defaultTimetable.id;
      this.currentTimetable = defaultTimetable;
      await this.persistTimetables();
    }
  }

  async persistTimetables(): Promise<void> {
    if (this.prefs === null) {
      return;
    }
    try {
      let jsonArray: Record<string, Object>[] = [];
      for (let i = 0; i < this.timetables.length; i++) {
        jsonArray.push(this.timetables[i].toJson());
      }
      let dataStr = JSON.stringify(jsonArray);
      await this.prefs.put(Constants.TIMETABLES_KEY, dataStr);
      await this.prefs.put(Constants.CURRENT_TIMETABLE_ID_KEY, this.currentTimetableId);
      await this.prefs.flush();
    } catch (err) {
      let error = err as Error;
      Logger.error('Persist timetables failed: ' + error.message);
    }
  }

  async switchTimetable(timetableId: string): Promise<void> {
    for (let i = 0; i < this.timetables.length; i++) {
      if (this.timetables[i].id === timetableId) {
        this.currentTimetableId = timetableId;
        this.currentTimetable = this.timetables[i];
        this.semesterStartDate = this.currentTimetable.semesterStartDate;
        this.calculateCurrentWeekFromToday();
        await this.persistTimetables();
        Logger.info('Switched to timetable: ' + this.currentTimetable.name);
        return;
      }
    }
  }

  async createTimetable(name: string, semesterStartDate: string): Promise<Timetable> {
    let timetable = new Timetable(Timetable.generateId(), name, semesterStartDate, false);
    this.timetables.push(timetable);
    await this.persistTimetables();
    Logger.info('Created new timetable: ' + name);
    return timetable;
  }

  createTimetableSync(name: string, semesterStartDate: string): Timetable {
    let timetable = new Timetable(Timetable.generateId(), name, semesterStartDate, false);
    this.timetables.push(timetable);
    this.persistTimetables();
    Logger.info('Created new timetable (sync): ' + name);
    return timetable;
  }

  async deleteTimetable(timetableId: string): Promise<void> {
    if (this.timetables.length <= 1) {
      Logger.warn('Cannot delete the only timetable');
      return;
    }

    let indexToDelete = -1;
    for (let i = 0; i < this.timetables.length; i++) {
      if (this.timetables[i].id === timetableId) {
        indexToDelete = i;
        break;
      }
    }

    if (indexToDelete === -1) {
      return;
    }

    this.timetables.splice(indexToDelete, 1);

    if (this.currentTimetableId === timetableId) {
      this.currentTimetable = this.timetables[0];
      this.currentTimetableId = this.currentTimetable.id;
      this.semesterStartDate = this.currentTimetable.semesterStartDate;
      this.calculateCurrentWeekFromToday();
    }

    await this.persistTimetables();
    Logger.info('Deleted timetable, remaining count: ' + this.timetables.length);
  }

  async updateTimetable(timetableId: string, name: string, semesterStartDate: string, showWeekend?: boolean, totalSlots?: number, totalWeeks?: number): Promise<void> {
    for (let i = 0; i < this.timetables.length; i++) {
      if (this.timetables[i].id === timetableId) {
        this.timetables[i].name = name;
        this.timetables[i].semesterStartDate = semesterStartDate;
        if (showWeekend !== undefined) {
          this.timetables[i].showWeekend = showWeekend;
        }
        if (totalSlots !== undefined) {
          this.timetables[i].totalSlots = totalSlots;
        }
        if (totalWeeks !== undefined) {
          this.timetables[i].totalWeeks = totalWeeks;
        }

        if (this.currentTimetableId === timetableId) {
          this.currentTimetable = this.timetables[i];
          this.semesterStartDate = semesterStartDate;
          this.calculateCurrentWeekFromToday();
        }

        this.timetables = [...this.timetables];

        await this.persistTimetables();
        Logger.info('Updated timetable: ' + name);
        return;
      }
    }
  }

  async saveSemesterConfig(startDate: string): Promise<void> {
    if (this.currentTimetable !== null) {
      await this.updateTimetable(this.currentTimetable.id, this.currentTimetable.name, startDate);
    }
  }

  private getSemesterStartDate(): Date | null {
    if (this.semesterStartDate === '') {
      return null;
    }
    let parts: string[] = this.semesterStartDate.split('-');
    let startYear = Number(parts[0]);
    let startMonth = Number(parts[1]) - 1;
    let startDay = Number(parts[2]);
    return new Date(startYear, startMonth, startDay);
  }

  calculateCurrentWeekFromToday(): void {
    if (this.semesterStartDate === '') {
      this.currentWeek = 1;
      return;
    }
    let week = this.calculateWeekFromDate(new Date());
    if (week < 1) {
      week = 1;
    }
    let maxWeeks = this.currentTotalWeeks;
    if (week > maxWeeks) {
      week = maxWeeks;
    }
    this.currentWeek = week;
  }

  calculateWeekFromDate(date: Date): number {
    let startDate = this.getSemesterStartDate();
    if (startDate === null) {
      return 1;
    }
    let diffMs = date.getTime() - startDate.getTime();
    let diffDays = diffMs / (1000 * 60 * 60 * 24);
    return Math.floor(diffDays / 7) + 1;
  }

  getDayDate(weekDay: number): string {
    let startDate = this.getSemesterStartDate();
    if (startDate === null) {
      return '';
    }
    let offsetDays = (this.currentWeek - 1) * 7 + (weekDay - 1);
    let targetDate = new Date(startDate.getTime() + offsetDays * 24 * 60 * 60 * 1000);
    let month = targetDate.getMonth() + 1;
    let day = targetDate.getDate();
    return month + '/' + day;
  }

  isToday(weekDay: number): boolean {
    let startDate = this.getSemesterStartDate();
    if (startDate === null) {
      return false;
    }
    let today = new Date();
    let offsetDays = (this.currentWeek - 1) * 7 + (weekDay - 1);
    let targetDate = new Date(startDate.getTime() + offsetDays * 24 * 60 * 60 * 1000);
    return today.getFullYear() === targetDate.getFullYear() &&
      today.getMonth() === targetDate.getMonth() &&
      today.getDate() === targetDate.getDate();
  }

  getWeekDateRange(): string {
    let startDate = this.getSemesterStartDate();
    if (startDate === null) {
      return '';
    }
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
    let startDate = this.getSemesterStartDate();
    if (startDate === null) {
      return 0;
    }
    let weekStartOffset = (this.currentWeek - 1) * 7;
    let mondayDate = new Date(startDate.getTime() + weekStartOffset * 24 * 60 * 60 * 1000);
    return mondayDate.getMonth() + 1;
  }

  getDayDateOfMonth(weekDay: number): number {
    let startDate = this.getSemesterStartDate();
    if (startDate === null) {
      return 0;
    }
    let offsetDays = (this.currentWeek - 1) * 7 + (weekDay - 1);
    let targetDate = new Date(startDate.getTime() + offsetDays * 24 * 60 * 60 * 1000);
    return targetDate.getDate();
  }

  getDayFullDate(): string {
    let startDate = this.getSemesterStartDate();
    if (startDate === null) {
      return '';
    }
    let offsetDays = (this.currentWeek - 1) * 7 + (this.selectedWeekDay - 1);
    let targetDate = new Date(startDate.getTime() + offsetDays * 24 * 60 * 60 * 1000);
    let month = targetDate.getMonth() + 1;
    let day = targetDate.getDate();
    return month + '月' + day + '日';
  }

  async addCourse(course: CourseInfo): Promise<void> {
    if (course.id === '') {
      course.id = this.generateId();
    }
    if (this.currentTimetable !== null) {
      this.currentTimetable.courses = [...this.currentTimetable.courses, course];
      this.timetables = [...this.timetables];
      await this.persistTimetables();
    }
  }

  async updateCourse(course: CourseInfo): Promise<void> {
    if (this.currentTimetable === null) {
      return;
    }
    for (let i = 0; i < this.currentTimetable.courses.length; i++) {
      if (this.currentTimetable.courses[i].id === course.id) {
        this.currentTimetable.courses[i].name = course.name;
        this.currentTimetable.courses[i].teacher = course.teacher;
        this.currentTimetable.courses[i].location = course.location;
        this.currentTimetable.courses[i].weekDay = course.weekDay;
        this.currentTimetable.courses[i].startSlot = course.startSlot;
        this.currentTimetable.courses[i].endSlot = course.endSlot;
        this.currentTimetable.courses[i].color = course.color;
        this.currentTimetable.courses[i].weekType = course.weekType;
        this.currentTimetable.courses[i].startWeek = course.startWeek;
        this.currentTimetable.courses[i].endWeek = course.endWeek;
        break;
      }
    }
    this.currentTimetable.courses = [...this.currentTimetable.courses];
    this.timetables = [...this.timetables];
    await this.persistTimetables();
  }

  async deleteCourse(id: string): Promise<void> {
    if (this.currentTimetable === null) {
      return;
    }
    this.currentTimetable.courses = this.currentTimetable.courses.filter((course: CourseInfo) => course.id !== id);
    this.currentTimetable.courses = [...this.currentTimetable.courses];
    this.timetables = [...this.timetables];
    await this.persistTimetables();
  }

  getCourseById(id: string): CourseInfo | null {
    if (this.currentTimetable === null) {
      return null;
    }
    for (let i = 0; i < this.currentTimetable.courses.length; i++) {
      if (this.currentTimetable.courses[i].id === id) {
        return this.currentTimetable.courses[i];
      }
    }
    return null;
  }

  getCoursesByDay(weekDay: number): CourseInfo[] {
    if (this.currentTimetable === null) {
      return [];
    }
    let result: CourseInfo[] = [];
    for (let i = 0; i < this.currentTimetable.courses.length; i++) {
      if (this.currentTimetable.courses[i].weekDay === weekDay && this.currentTimetable.courses[i].isOnWeek(this.currentWeek)) {
        result.push(this.currentTimetable.courses[i]);
      }
    }
    result.sort((a: CourseInfo, b: CourseInfo) => a.startSlot - b.startSlot);
    return result;
  }

  getCourseAtSlot(weekDay: number, slot: number): CourseInfo | undefined {
    if (this.currentTimetable === null) {
      return undefined;
    }
    for (let i = 0; i < this.currentTimetable.courses.length; i++) {
      let course = this.currentTimetable.courses[i];
      if (course.weekDay === weekDay && slot >= course.startSlot && slot <= course.endSlot && course.isOnWeek(this.currentWeek)) {
        return course;
      }
    }
    return undefined;
  }

  hasConflict(course: CourseInfo, excludeId: string): boolean {
    if (this.currentTimetable === null) {
      return false;
    }
    for (let i = 0; i < this.currentTimetable.courses.length; i++) {
      let existing = this.currentTimetable.courses[i];
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
    if (this.currentWeek < this.currentTotalWeeks) {
      this.currentWeek = this.currentWeek + 1;
    }
  }

  private generateId(): string {
    return Date.now().toString() + Math.floor(Math.random() * 1000).toString();
  }
}
