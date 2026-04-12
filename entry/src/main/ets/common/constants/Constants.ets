export class Constants {
  static readonly TOTAL_SLOTS: number = 13;
  static readonly TOTAL_DAYS: number = 7;
  static readonly SLOT_HEIGHT: number = 60;
  static readonly TIME_HEADER_WIDTH: number = 50;
  static readonly DAY_COLUMN_WIDTH: string = '1fr';
  static readonly COURSE_CARD_RADIUS: number = 8;
  static readonly COURSE_CARD_PADDING: number = 6;
  static readonly HEADER_HEIGHT: number = 40;
  static readonly PREFERENCES_NAME: string = 'easy_curriculum_prefs';
  static readonly COURSE_DATA_KEY: string = 'course_data';
  static readonly SEMESTER_CONFIG_KEY: string = 'semester_config';
  static readonly TOTAL_WEEKS: number = 20;
  static readonly TIMETABLES_KEY: string = 'timetables';
  static readonly CURRENT_TIMETABLE_ID_KEY: string = 'current_timetable_id';

  static readonly SLOT_TIMES: Record<number, string> = {
    1: '08:00',
    2: '08:50',
    3: '09:50',
    4: '10:40',
    5: '11:30',
    6: '14:05',
    7: '14:55',
    8: '15:45',
    9: '16:40',
    10: '17:30',
    11: '18:30',
    12: '19:20',
    13: '20:10'
  } as Record<number, string>;

  static readonly COURSE_COLORS: string[] = [
    '#4CAF50',
    '#2196F3',
    '#FF9800',
    '#9C27B0',
    '#F44336',
    '#00BCD4',
    '#FF5722',
    '#3F51B5',
    '#E91E63',
    '#009688'
  ];
}
