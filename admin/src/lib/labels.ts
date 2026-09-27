/** Единые русские подписи для enum/статусов API. */

export function roleLabel(role: string): string {
  switch (role.toLowerCase()) {
    case 'admin':
      return 'Админ'
    case 'moderator':
      return 'Модератор'
    case 'user':
      return 'Пользователь'
    default:
      return role
  }
}

export function blockedLabel(isBlocked: boolean): string {
  return isBlocked ? 'Заблокирован' : 'Активен'
}

export function reportStatusLabel(status: string): string {
  switch (status.toLowerCase()) {
    case 'open':
      return 'Открыта'
    case 'reviewed':
      return 'Разбрана'
    case 'dismissed':
      return 'Отклонена'
    default:
      return status
  }
}

export function reportReasonLabel(reason: string): string {
  switch (reason.toLowerCase()) {
    case 'spam':
      return 'Спам'
    case 'inappropriate':
      return 'Неприемлемый контент'
    case 'harassment':
      return 'Домогательство'
    case 'fake':
      return 'Фейк'
    case 'other':
      return 'Другое'
    default:
      return reason
  }
}

export function occurrenceStatusLabel(status: string): string {
  switch (status.toLowerCase()) {
    case 'published':
      return 'Опубликовано'
    case 'hidden':
      return 'Скрыто'
    case 'cancelled':
      return 'Отменено'
    case 'completed':
      return 'Завершено'
    case 'draft':
      return 'Черновик'
    default:
      return status
  }
}

export function joinModeLabel(mode: string): string {
  switch (mode.toLowerCase()) {
    case 'auto':
    case 'open':
      return 'Авто'
    case 'approval':
    case 'request':
      return 'По заявке'
    case 'invite':
    case 'invite_only':
      return 'По приглашению'
    default:
      return mode
  }
}

export function reportActionLabel(action: string): string {
  switch (action.toLowerCase()) {
    case 'block_target_user':
      return 'Блок пользователя'
    case 'hide_occurrence':
      return 'Скрытие события'
    default:
      return action
  }
}

export function auditActionLabel(action: string): string {
  switch (action.toLowerCase()) {
    case 'user_blocked':
      return 'Блокировка пользователя'
    case 'user_unblocked':
      return 'Разблокировка пользователя'
    case 'user_role_changed':
      return 'Смена роли'
    case 'occurrence_hidden':
      return 'Скрытие события'
    case 'occurrence_unhidden':
      return 'Публикация события'
    case 'occurrence_cancelled':
      return 'Отмена события'
    case 'report_status_changed':
      return 'Смена статуса жалобы'
    default:
      return action
  }
}

export function auditTargetTypeLabel(type: string): string {
  switch (type.toLowerCase()) {
    case 'user':
      return 'Пользователь'
    case 'occurrence':
      return 'Событие'
    case 'report':
      return 'Жалоба'
    default:
      return type
  }
}

export function lifecycleActionLabel(
  action: 'hide' | 'cancel' | 'republish',
): string {
  switch (action) {
    case 'hide':
      return 'скрыто'
    case 'cancel':
      return 'отменено'
    case 'republish':
      return 'опубликовано'
  }
}

export function pointRoleLabel(point: {
  isStart: boolean
  isFinish: boolean
}): string {
  if (point.isStart) return 'Старт'
  if (point.isFinish) return 'Финиш'
  return 'Промежуточная'
}
