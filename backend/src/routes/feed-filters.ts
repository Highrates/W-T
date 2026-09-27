/** Feed filter taxonomy — ids aligned with mobile FeedHotFilterMock. */
export const PARTICIPATION_FILTER_IDS = ['one_on_one', 'group'] as const;
export const FORMAT_FILTER_IDS = ['walk', 'drive'] as const;
export const THEME_FILTER_IDS = [
  'culture',
  'nature',
  'food',
  'sport',
  'relax',
  'social',
  'bike',
  'photo',
  'kids',
  'night',
  'dog',
] as const;

export const ALL_FILTER_IDS = new Set<string>([
  ...PARTICIPATION_FILTER_IDS,
  ...FORMAT_FILTER_IDS,
  ...THEME_FILTER_IDS,
]);

export const FILTER_LABELS: Record<string, string> = {
  one_on_one: '🤝 1×1',
  group: '👥 Группа',
  walk: 'Пешком',
  drive: 'Авто',
  culture: 'Культура',
  nature: 'Природа',
  food: 'Еда',
  sport: 'Спорт',
  relax: 'Отдых',
  social: 'Общение',
  bike: 'Велосипед',
  photo: 'Фото',
  kids: 'С детьми',
  night: 'Ночь',
  dog: 'С собакой',
};

export function isParticipationId(id: string): boolean {
  return PARTICIPATION_FILTER_IDS.includes(id as (typeof PARTICIPATION_FILTER_IDS)[number]);
}

export function isFormatId(id: string): boolean {
  return FORMAT_FILTER_IDS.includes(id as (typeof FORMAT_FILTER_IDS)[number]);
}

export function isThemeId(id: string): boolean {
  return THEME_FILTER_IDS.includes(id as (typeof THEME_FILTER_IDS)[number]);
}

/** Empty set = match all. Within axis OR, across axes AND. */
export function matchesFeedFilters(
  selectedIds: Set<string>,
  formatIds: string[],
  themeIds: string[],
  isOneOnOne: boolean,
): boolean {
  if (selectedIds.size === 0) return true;

  const participation = [...selectedIds].filter(isParticipationId);
  const formats = [...selectedIds].filter(isFormatId);
  const themes = [...selectedIds].filter(isThemeId);

  if (participation.length > 0) {
    const wantOne = participation.includes('one_on_one');
    const wantGroup = participation.includes('group');
    if (wantOne && !wantGroup && !isOneOnOne) return false;
    if (wantGroup && !wantOne && isOneOnOne) return false;
  }

  if (formats.length > 0 && !formatIds.some((id) => formats.includes(id))) {
    return false;
  }

  if (themes.length > 0 && !themeIds.some((id) => themes.includes(id))) {
    return false;
  }

  return true;
}
