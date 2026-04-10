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

@Observed
export class CourseInfo {
  id: string = '';
  name: string = '';
  teacher: string = '';
  location: string = '';
  weekDay: number = 1;
  startSlot: number = 1;
  endSlot: number = 2;
  startWeek: number = 1;
  endWeek: number = 16;
  color: string = '#4CAF50';
  weekType: number = WeekType.EVERY_WEEK;

  constructor(
    id: string,
    name: string,
    teacher: string,
    location: string,
    weekDay: number,
    startSlot: number,
    endSlot: number,
    startWeek: number,
    endWeek: number,
    color: string,
    weekType: number
  ) {
    this.id = id;
    this.name = name;
    this.teacher = teacher;
    this.location = location;
    this.weekDay = weekDay;
    this.startSlot = startSlot;
    this.endSlot = endSlot;
    this.startWeek = startWeek;
    this.endWeek = endWeek;
    this.color = color;
    this.weekType = weekType;
  }

  static createDefault(): CourseInfo {
    return new CourseInfo('', '', '', '', 1, 1, 2, 1, 16, '#4CAF50', WeekType.EVERY_WEEK);
  }

  toJson(): Record<string, Object> {
    return {
      'id': this.id,
      'name': this.name,
      'teacher': this.teacher,
      'location': this.location,
      'weekDay': this.weekDay,
      'startSlot': this.startSlot,
      'endSlot': this.endSlot,
      'startWeek': this.startWeek,
      'endWeek': this.endWeek,
      'color': this.color,
      'weekType': this.weekType
    } as Record<string, Object>;
  }

  static fromJson(json: Record<string, Object>): CourseInfo {
    let id = json['id'] as string;
    let name = json['name'] as string;
    let teacher = json['teacher'] as string;
    let location = json['location'] as string;
    let weekDay = json['weekDay'] as number;
    let startSlot = json['startSlot'] as number;
    let endSlot = json['endSlot'] as number;
    let startWeek = json['startWeek'] as number;
    let endWeek = json['endWeek'] as number;
    let color = json['color'] as string;
    let weekType = json['weekType'] as number;
    return new CourseInfo(id, name, teacher, location, weekDay, startSlot, endSlot, startWeek, endWeek, color, weekType);
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
