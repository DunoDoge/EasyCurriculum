import { preferences } from '@kit.ArkData';
import { Context } from '@kit.AbilityKit';
import { CourseInfo } from '../model/CourseModel';
import { Constants } from '../common/constants/Constants';
import { Logger } from '../common/utils/Logger';

@Observed
export class CourseViewModel {
  courses: CourseInfo[] = [];
  currentWeek: number = 1;
  private prefs: preferences.Preferences | null = null;

  async init(context: Context): Promise<void> {
    try {
      this.prefs = await preferences.getPreferences(context, Constants.PREFERENCES_NAME);
      await this.loadCourses();
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
