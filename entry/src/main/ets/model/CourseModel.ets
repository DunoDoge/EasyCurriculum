export enum WeekType {
  EVERY_WEEK = 0,
  ODD_WEEK = 1,
  EVEN_WEEK = 2
}

export function getWeekTypeName(type: WeekType): string {
  let names: Record<number, string> = {
    0: '每周',
    1: '单周',
    2: '双周'
  } as Record<number, string>;
  return names[type];
}

@ObservedV2
export class TimeSlot {
  @Trace weekDay: number = 1;
  @Trace startSlot: number = 1;
  @Trace endSlot: number = 2;
  @Trace startWeek: number = 1;
  @Trace endWeek: number = 16;
  @Trace weekType: number = WeekType.EVERY_WEEK;
  @Trace teacher: string = '';
  @Trace location: string = '';

  constructor(
    weekDay: number,
    startSlot: number,
    endSlot: number,
    startWeek: number,
    endWeek: number,
    weekType: number,
    teacher: string,
    location: string
  ) {
    this.weekDay = weekDay;
    this.startSlot = startSlot;
    this.endSlot = endSlot;
    this.startWeek = startWeek;
    this.endWeek = endWeek;
    this.weekType = weekType;
    this.teacher = teacher;
    this.location = location;
  }

  static createDefault(): TimeSlot {
    return new TimeSlot(1, 1, 2, 1, 16, WeekType.EVERY_WEEK, '', '');
  }

  toJson(): Record<string, Object> {
    return {
      'weekDay': this.weekDay,
      'startSlot': this.startSlot,
      'endSlot': this.endSlot,
      'startWeek': this.startWeek,
      'endWeek': this.endWeek,
      'weekType': this.weekType,
      'teacher': this.teacher,
      'location': this.location
    } as Record<string, Object>;
  }

  static fromJson(json: Record<string, Object>): TimeSlot {
    let weekDay = json['weekDay'] as number;
    let startSlot = json['startSlot'] as number;
    let endSlot = json['endSlot'] as number;
    let startWeek = json['startWeek'] as number;
    let endWeek = json['endWeek'] as number;
    let weekType = json['weekType'] as number;
    let teacher = json['teacher'] as string;
    let location = json['location'] as string;
    return new TimeSlot(weekDay, startSlot, endSlot, startWeek, endWeek, weekType, teacher, location);
  }

  isOnWeek(week: number): boolean {
    if (week < this.startWeek || week > this.endWeek) {
      return false;
    }
    if (this.weekType === WeekType.EVERY_WEEK) {
      return true;
    }
    if (this.weekType === WeekType.ODD_WEEK) {
      return week % 2 === 1;
    }
    if (this.weekType === WeekType.EVEN_WEEK) {
      return week % 2 === 0;
    }
    return false;
  }
}

@ObservedV2
export class CourseInfo {
  @Trace id: string = '';
  @Trace name: string = '';
  @Trace color: string = '#4CAF50';
  @Trace timeSlots: TimeSlot[] = [];

  constructor(id: string, name: string, color: string, timeSlots: TimeSlot[]) {
    this.id = id;
    this.name = name;
    this.color = color;
    this.timeSlots = timeSlots;
  }

  static createDefault(): CourseInfo {
    return new CourseInfo('', '', '#4CAF50', [TimeSlot.createDefault()]);
  }

  get teacher(): string {
    if (this.timeSlots.length > 0) {
      return this.timeSlots[0].teacher;
    }
    return '';
  }

  get location(): string {
    if (this.timeSlots.length > 0) {
      return this.timeSlots[0].location;
    }
    return '';
  }

  get weekDay(): number {
    if (this.timeSlots.length > 0) {
      return this.timeSlots[0].weekDay;
    }
    return 1;
  }

  get startSlot(): number {
    if (this.timeSlots.length > 0) {
      return this.timeSlots[0].startSlot;
    }
    return 1;
  }

  get endSlot(): number {
    if (this.timeSlots.length > 0) {
      return this.timeSlots[0].endSlot;
    }
    return 2;
  }

  get startWeek(): number {
    if (this.timeSlots.length > 0) {
      return this.timeSlots[0].startWeek;
    }
    return 1;
  }

  get endWeek(): number {
    if (this.timeSlots.length > 0) {
      return this.timeSlots[0].endWeek;
    }
    return 16;
  }

  get weekType(): number {
    if (this.timeSlots.length > 0) {
      return this.timeSlots[0].weekType;
    }
    return WeekType.EVERY_WEEK;
  }

  toJson(): Record<string, Object> {
    let timeSlotJsonArray: Record<string, Object>[] = [];
    for (let i = 0; i < this.timeSlots.length; i++) {
      timeSlotJsonArray.push(this.timeSlots[i].toJson());
    }
    return {
      'id': this.id,
      'name': this.name,
      'color': this.color,
      'timeSlots': timeSlotJsonArray
    } as Record<string, Object>;
  }

  static fromJson(json: Record<string, Object>): CourseInfo {
    let id = json['id'] as string;
    let name = json['name'] as string;
    let color = json['color'] as string;
    let timeSlots: TimeSlot[] = [];

    let timeSlotsData = json['timeSlots'];
    if (timeSlotsData !== undefined && timeSlotsData !== null) {
      let timeSlotJsonArray: Record<string, Object>[] = timeSlotsData as Record<string, Object>[];
      for (let i = 0; i < timeSlotJsonArray.length; i++) {
        timeSlots.push(TimeSlot.fromJson(timeSlotJsonArray[i]));
      }
    } else {
      // 向后兼容：从旧格式构造单个TimeSlot
      let teacher = json['teacher'] as string;
      let location = json['location'] as string;
      let weekDay = json['weekDay'] as number;
      let startSlot = json['startSlot'] as number;
      let endSlot = json['endSlot'] as number;
      let startWeek = json['startWeek'] as number;
      let endWeek = json['endWeek'] as number;
      let weekType = json['weekType'] as number;
      timeSlots.push(new TimeSlot(weekDay, startSlot, endSlot, startWeek, endWeek, weekType, teacher, location));
    }

    return new CourseInfo(id, name, color, timeSlots);
  }

  isOnWeek(week: number): boolean {
    if (this.timeSlots.length > 0) {
      return this.timeSlots[0].isOnWeek(week);
    }
    return false;
  }
}

export class SemesterConfig {
  startDate: string = '';

  constructor(startDate: string) {
    this.startDate = startDate;
  }

  toJson(): Record<string, Object> {
    return { 'startDate': this.startDate } as Record<string, Object>;
  }

  static fromJson(json: Record<string, Object>): SemesterConfig {
    let startDate = json['startDate'] as string;
    return new SemesterConfig(startDate);
  }

  static createDefault(): SemesterConfig {
    return new SemesterConfig('');
  }
}

@ObservedV2
export class Timetable {
  @Trace id: string = '';
  @Trace name: string = '';
  @Trace semesterStartDate: string = '';
  @Trace courses: CourseInfo[] = [];
  @Trace isDefault: boolean = false;
  @Trace showWeekend: boolean = true;
  @Trace totalSlots: number = 13;
  @Trace totalWeeks: number = 20;

  constructor(id: string, name: string, semesterStartDate: string, isDefault: boolean, showWeekend: boolean = true, totalSlots: number = 13, totalWeeks: number = 20) {
    this.id = id;
    this.name = name;
    this.semesterStartDate = semesterStartDate;
    this.isDefault = isDefault;
    this.showWeekend = showWeekend;
    this.totalSlots = totalSlots;
    this.totalWeeks = totalWeeks;
  }

  toJson(): Record<string, Object> {
    let courseJsonArray: Record<string, Object>[] = [];
    for (let i = 0; i < this.courses.length; i++) {
      courseJsonArray.push(this.courses[i].toJson());
    }
    return {
      'id': this.id,
      'name': this.name,
      'semesterStartDate': this.semesterStartDate,
      'courses': courseJsonArray,
      'isDefault': this.isDefault,
      'showWeekend': this.showWeekend,
      'totalSlots': this.totalSlots,
      'totalWeeks': this.totalWeeks
    } as Record<string, Object>;
  }

  static fromJson(json: Record<string, Object>): Timetable {
    let id = json['id'] as string;
    let name = json['name'] as string;
    let semesterStartDate = json['semesterStartDate'] as string;
    let isDefault = json['isDefault'] as boolean;
    let showWeekend = json['showWeekend'] as boolean;
    let totalSlots = json['totalSlots'] as number;
    let totalWeeks = json['totalWeeks'] as number;
    if (showWeekend === undefined) {
      showWeekend = true;
    }
    if (totalSlots === undefined) {
      totalSlots = 13;
    }
    if (totalWeeks === undefined) {
      totalWeeks = 20;
    }
    let timetable = new Timetable(id, name, semesterStartDate, isDefault, showWeekend, totalSlots, totalWeeks);

    let coursesArray = json['courses'];
    if (coursesArray !== undefined && coursesArray !== null) {
      let courseJsonArray: Record<string, Object>[] = coursesArray as Record<string, Object>[];
      for (let i = 0; i < courseJsonArray.length; i++) {
        let course = CourseInfo.fromJson(courseJsonArray[i]);
        timetable.courses.push(course);
      }
    }
    return timetable;
  }

  static createDefault(): Timetable {
    let timetable = new Timetable('', '我的课表', '', true, true, 13, 20);
    return timetable;
  }

  static generateId(): string {
    return Date.now().toString() + Math.floor(Math.random() * 1000).toString();
  }
}
