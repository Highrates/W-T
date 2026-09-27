String formatCreateRouteDate(DateTime value) {
  const months = [
    'янв',
    'фев',
    'мар',
    'апр',
    'май',
    'июн',
    'июл',
    'авг',
    'сен',
    'окт',
    'ноя',
    'дек',
  ];
  final month = months[value.month - 1];
  return '${value.day} $month ${value.year}';
}

String formatCreateRouteTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String formatCreateRouteWhen(DateTime value) {
  return '${formatCreateRouteDate(value)}, ${formatCreateRouteTime(value)}';
}
