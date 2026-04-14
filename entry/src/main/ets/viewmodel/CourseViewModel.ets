import { preferences } from '@kit.ArkData';
import { Context } from '@kit.AbilityKit';
import { CourseInfo, ConflictDetail, SemesterConfig, Timetable, TimeSlot, WeekType } from '../model/CourseModel';
import { Constants } from '../common/constants/Constants';
import { Logger } from '../common/utils/Logger';

export class CourseSlotDisplay {
  course: CourseInfo = CourseInfo.createDefault();
  timeSlot: TimeSlot = TimeSlot.createDefault();
}

@ObservedV2
export class CourseViewModel {
  @Trace timetables: Timetable[] = [];
  @Trace currentTimetableId: string = '';
  @Trace currentTimetable: Timetable | null = null;
  @Trace currentWeek: number = 1;
  @Trace semesterStartDate: string = '';
  @Trace viewMode: string = 'week';
  @Trace selectedWeekDay: number = 0;
  @Trace dataVersion: number = 0;
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
      this.dataVersion = this.dataVersion + 1;
      await this.persistTimetables();
    }
  }

  async updateCourse(course: CourseInfo): Promise<void> {
    if (this.currentTimetable === null) {
      return;
    }
    for (let i = 0; i < this.currentTimetable.courses.length; i++) {
      if (this.currentTimetable.courses[i].id === course.id) {
        this.currentTimetable.courses[i] = course;
        break;
      }
    }
    this.currentTimetable.courses = [...this.currentTimetable.courses];
    this.timetables = [...this.timetables];
    this.dataVersion = this.dataVersion + 1;
    await this.persistTimetables();
  }

  async deleteCourse(id: string): Promise<void> {
    if (this.currentTimetable === null) {
      return;
    }
    this.currentTimetable.courses = this.currentTimetable.courses.filter((course: CourseInfo) => course.id !== id);
    this.currentTimetable.courses = [...this.currentTimetable.courses];
    this.timetables = [...this.timetables];
    this.dataVersion = this.dataVersion + 1;
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
      let course = this.currentTimetable.courses[i];
      for (let j = 0; j < course.timeSlots.length; j++) {
        if (course.timeSlots[j].weekDay === weekDay && course.timeSlots[j].isOnWeek(this.currentWeek)) {
          result.push(course);
          break;
        }
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
      for (let j = 0; j < course.timeSlots.length; j++) {
        let ts = course.timeSlots[j];
        if (ts.weekDay === weekDay && slot >= ts.startSlot && slot <= ts.endSlot && ts.isOnWeek(this.currentWeek)) {
          return course;
        }
      }
    }
    return undefined;
  }

  static hasOddWeekInRange(start: number, end: number): boolean {
    if (start > end) {
      return false;
    }
    if (start % 2 === 1) {
      return true;
    }
    return start + 1 <= end;
  }

  static hasEvenWeekInRange(start: number, end: number): boolean {
    if (start > end) {
      return false;
    }
    if (start % 2 === 0) {
      return true;
    }
    return start + 1 <= end;
  }

  static weeksOverlap(ts: TimeSlot, ets: TimeSlot): boolean {
    let overlapStart = Math.max(ts.startWeek, ets.startWeek);
    let overlapEnd = Math.min(ts.endWeek, ets.endWeek);
    if (overlapStart > overlapEnd) {
      return false;
    }
    // 单周 vs 双周：永不重叠
    if ((ts.weekType === WeekType.ODD_WEEK && ets.weekType === WeekType.EVEN_WEEK) ||
      (ts.weekType === WeekType.EVEN_WEEK && ets.weekType === WeekType.ODD_WEEK)) {
      return false;
    }
    // 每周 vs 每周：交集区间非空即重叠
    if (ts.weekType === WeekType.EVERY_WEEK && ets.weekType === WeekType.EVERY_WEEK) {
      return true;
    }
    // 需要奇数周的场景：每周vs单周、单周vs每周、单周vs单周
    if ((ts.weekType === WeekType.EVERY_WEEK && ets.weekType === WeekType.ODD_WEEK) ||
      (ts.weekType === WeekType.ODD_WEEK && ets.weekType === WeekType.EVERY_WEEK) ||
      (ts.weekType === WeekType.ODD_WEEK && ets.weekType === WeekType.ODD_WEEK)) {
      return CourseViewModel.hasOddWeekInRange(overlapStart, overlapEnd);
    }
    // 需要偶数周的场景：每周vs双周、双周vs每周、双周vs双周
    if ((ts.weekType === WeekType.EVERY_WEEK && ets.weekType === WeekType.EVEN_WEEK) ||
      (ts.weekType === WeekType.EVEN_WEEK && ets.weekType === WeekType.EVERY_WEEK) ||
      (ts.weekType === WeekType.EVEN_WEEK && ets.weekType === WeekType.EVEN_WEEK)) {
      return CourseViewModel.hasEvenWeekInRange(overlapStart, overlapEnd);
    }
    return false;
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
      for (let j = 0; j < course.timeSlots.length; j++) {
        let ts = course.timeSlots[j];
        for (let k = 0; k < existing.timeSlots.length; k++) {
          let ets = existing.timeSlots[k];
          if (ts.weekDay === ets.weekDay &&
            ts.startSlot <= ets.endSlot && ts.endSlot >= ets.startSlot &&
            CourseViewModel.weeksOverlap(ts, ets)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  findConflict(course: CourseInfo, excludeId: string): ConflictDetail | undefined {
    if (this.currentTimetable === null) {
      return undefined;
    }
    for (let i = 0; i < this.currentTimetable.courses.length; i++) {
      let existing = this.currentTimetable.courses[i];
      if (existing.id === excludeId) {
        continue;
      }
      for (let j = 0; j < course.timeSlots.length; j++) {
        let ts = course.timeSlots[j];
        for (let k = 0; k < existing.timeSlots.length; k++) {
          let ets = existing.timeSlots[k];
          if (ts.weekDay === ets.weekDay &&
            ts.startSlot <= ets.endSlot && ts.endSlot >= ets.startSlot) {
            let overlapStart = Math.max(ts.startWeek, ets.startWeek);
            let overlapEnd = Math.min(ts.endWeek, ets.endWeek);
            let conflictWeeks: number[] = [];
            for (let w = overlapStart; w <= overlapEnd; w++) {
              if (ts.isOnWeek(w) && ets.isOnWeek(w)) {
                conflictWeeks.push(w);
              }
            }
            if (conflictWeeks.length > 0) {
              return new ConflictDetail(existing.name, ts.weekDay, ts.startSlot, ts.endSlot,
                conflictWeeks);
            }
          }
        }
      }
    }
    return undefined;
  }

  getCourseSlotsByDay(weekDay: number): CourseSlotDisplay[] {
    if (this.currentTimetable === null) {
      return [];
    }
    let result: CourseSlotDisplay[] = [];
    for (let i = 0; i < this.currentTimetable.courses.length; i++) {
      let course = this.currentTimetable.courses[i];
      for (let j = 0; j < course.timeSlots.length; j++) {
        let ts = course.timeSlots[j];
        if (ts.weekDay === weekDay && ts.isOnWeek(this.currentWeek)) {
          let csd = new CourseSlotDisplay();
          csd.course = course;
          csd.timeSlot = ts;
          result.push(csd);
        }
      }
    }
    result.sort((a: CourseSlotDisplay, b: CourseSlotDisplay) => a.timeSlot.startSlot - b.timeSlot.startSlot);
    return result;
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

  prevDay(): void {
    if (this.selectedWeekDay > 1) {
      this.selectedWeekDay = this.selectedWeekDay - 1;
    } else if (this.currentWeek > 1) {
      this.currentWeek = this.currentWeek - 1;
      this.selectedWeekDay = (this.currentTimetable?.showWeekend ?? true) ? 7 : 5;
    }
  }

  nextDay(): void {
    let maxDay = (this.currentTimetable?.showWeekend ?? true) ? 7 : 5;
    if (this.selectedWeekDay < maxDay) {
      this.selectedWeekDay = this.selectedWeekDay + 1;
    } else if (this.currentWeek < this.currentTotalWeeks) {
      this.currentWeek = this.currentWeek + 1;
      this.selectedWeekDay = 1;
    }
  }

  isAtFirstDay(): boolean {
    return this.currentWeek === 1 && this.selectedWeekDay === 1;
  }

  isAtLastDay(): boolean {
    let maxDay = (this.currentTimetable?.showWeekend ?? true) ? 7 : 5;
    return this.currentWeek === this.currentTotalWeeks && this.selectedWeekDay === maxDay;
  }

  private generateId(): string {
    return Date.now().toString() + Math.floor(Math.random() * 1000).toString();
  }
}
