/// Пункт выпадающего списка локации / радиуса.
class LocationFilterOption {
  const LocationFilterOption({
    required this.id,
    required this.label,
    this.isRadius = false,
  });

  final String id;
  final String label;

  /// Радиус (рядом / +N км), иначе город.
  final bool isRadius;
}

/// Моки локации для dropdown (радиус + города).
abstract final class LocationFilterMock {
  static const List<LocationFilterOption> radiusOptions = [
    LocationFilterOption(id: 'nearby', label: 'Рядом', isRadius: true),
    LocationFilterOption(id: 'radius_3', label: '+ 3 км', isRadius: true),
    LocationFilterOption(id: 'radius_15', label: '+ 15 км', isRadius: true),
    LocationFilterOption(id: 'radius_100', label: '+ 100 км', isRadius: true),
  ];

  static const List<LocationFilterOption> cityOptions = [
    LocationFilterOption(id: 'moscow', label: 'Москва'),
    LocationFilterOption(id: 'spb', label: 'Санкт-Петербург'),
    LocationFilterOption(id: 'sochi', label: 'Сочи 🌴'),
    LocationFilterOption(id: 'astrakhan', label: 'Астрахань'),
    LocationFilterOption(id: 'kazan', label: 'Казань'),
    LocationFilterOption(id: 'ekb', label: 'Екатеринбург'),
    LocationFilterOption(id: 'novosibirsk', label: 'Новосибирск'),
    LocationFilterOption(id: 'krasnodar', label: 'Краснодар'),
    LocationFilterOption(id: 'nizhny', label: 'Нижний Новгород'),
    LocationFilterOption(id: 'samara', label: 'Самара'),
    LocationFilterOption(id: 'rostov', label: 'Ростов-на-Дону'),
    LocationFilterOption(id: 'ufa', label: 'Уфа'),
    LocationFilterOption(id: 'krasnoyarsk', label: 'Красноярск'),
    LocationFilterOption(id: 'voronezh', label: 'Воронеж'),
    LocationFilterOption(id: 'perm', label: 'Пермь'),
    LocationFilterOption(id: 'volgograd', label: 'Волгоград'),
    LocationFilterOption(id: 'tyumen', label: 'Тюмень'),
    LocationFilterOption(id: 'irkutsk', label: 'Иркутск'),
    LocationFilterOption(id: 'khabarovsk', label: 'Хабаровск'),
    LocationFilterOption(id: 'kaliningrad', label: 'Калининград'),
    LocationFilterOption(id: 'vladivostok', label: 'Владивосток'),
  ];

  static const LocationFilterOption defaultCity = LocationFilterOption(
    id: 'sochi',
    label: 'Сочи 🌴',
  );

  static List<LocationFilterOption> get all => [
        ...radiusOptions,
        ...cityOptions,
      ];
}
