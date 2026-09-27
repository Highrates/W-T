import '../../../shared/models/event_route_point.dart';
import '../../../shared/models/geo_point.dart';

/// Моки точек маршрута (Сочи). Координаты — как с API PostGIS.
abstract final class EventRoutePointsMock {
  static const _cards = 'assets/images/cards';

  static const _sochiCenter = GeoPoint(latitude: 43.5855, longitude: 39.7231);

  static List<EventRoutePoint> forEvent(String id) => switch (id) {
        'dragons' => const [
            EventRoutePoint(
              title: 'Старт — Парк Ривьера',
              location: GeoPoint(latitude: 43.5731, longitude: 39.7392),
              address: 'Сочи, Парк Ривьера',
              detail: '13:15 · Сбор у фонтана',
              description:
                  'Встречаемся у главного входа, возле фонтана. Организатор '
                  'будет с табличкой JOOW.',
              photoAssets: ['$_cards/01.jpg', '$_cards/02.jpg'],
            ),
            EventRoutePoint(
              title: 'Смотровая площадка',
              location: GeoPoint(latitude: 43.5680, longitude: 39.7450),
              detail: 'Остановка для фото',
              description:
                  'Короткая остановка с видом на город и море. Можно '
                  'загрузить свои кадры в точку маршрута.',
              photoAssets: ['$_cards/03.jpg'],
            ),
            EventRoutePoint(
              title: 'Пикник',
              location: GeoPoint(latitude: 43.5645, longitude: 39.7485),
              detail: 'Перекус и общение',
              description:
                  'Приносите перекус с собой или заказываем на месте. '
                  'Есть лавочки и тень.',
              photoAssets: ['$_cards/04.jpg', '$_cards/05.jpg'],
            ),
            EventRoutePoint(
              title: 'Финиш — набережная',
              location: GeoPoint(latitude: 43.5608, longitude: 39.7520),
              detail: '~16:00',
              description: 'Свободное время, обмен контактами, фото на закате.',
            ),
          ],
        'terrenkur' => const [
            EventRoutePoint(
              title: 'Вход на Terrenkur',
              location: GeoPoint(latitude: 43.5612, longitude: 39.7288),
              detail: 'Сбор группы',
              description: 'Старт маршрута, знакомство участников.',
              photoAssets: ['$_cards/06.jpg'],
            ),
            EventRoutePoint(
              title: 'Лесная тропа',
              location: GeoPoint(latitude: 43.5588, longitude: 39.7315),
              detail: 'Спокойный темп',
              description:
                  'Ровная тропа, удобная обувь. Остановки по желанию группы.',
            ),
            EventRoutePoint(
              title: 'Кофейня',
              location: GeoPoint(latitude: 43.5565, longitude: 39.7340),
              detail: 'Короткая остановка',
              description: 'Кофе и десерт, при желании — отзыв о точке.',
              photoAssets: ['$_cards/07.jpg'],
            ),
          ],
        'sunset' => const [
            EventRoutePoint(
              title: 'Маяк',
              location: GeoPoint(latitude: 43.5528, longitude: 39.7514),
              address: 'Сочи, маяк',
              detail: '18:30 · Старт',
              description: 'Классная точка для первого кадра на закат.',
              photoAssets: ['$_cards/08.jpg'],
            ),
            EventRoutePoint(
              title: 'Набережная',
              location: GeoPoint(latitude: 43.5505, longitude: 39.7548),
              detail: 'Прогулка вдоль моря',
              description: 'Идём вдоль воды, темп неспешный.',
              photoAssets: ['$_cards/09.jpg', '$_cards/10.jpg'],
            ),
            EventRoutePoint(
              title: 'Закат',
              location: GeoPoint(latitude: 43.5488, longitude: 39.7575),
              detail: 'Встреча на пирсе',
              description: 'Финальная точка — встречаем закат вместе.',
            ),
          ],
        'banya-chill' => const [
            EventRoutePoint(
              title: 'Баня',
              location: GeoPoint(latitude: 43.5768, longitude: 39.7156),
              detail: '16:00 · Сбор у входа',
              description:
                  'Встречаемся у входа и сразу заходим. Пар, чай, свои '
                  'разговоры — без прогулок.',
              photoAssets: ['$_cards/banya.jpg'],
            ),
          ],
        'beer-bar' => const [
            EventRoutePoint(
              title: 'Пивной бар',
              location: GeoPoint(latitude: 43.5801, longitude: 39.7210),
              detail: '19:30 · Сбор',
              description: 'Ждём у входа, дальше берём столик.',
              photoAssets: ['$_cards/bar.jpg'],
            ),
          ],
        'astrakhan-fishing' => const [
            EventRoutePoint(
              title: 'Сбор у причала',
              location: GeoPoint(latitude: 46.3512, longitude: 48.0524),
              address: 'Астрахань',
              detail: '5:30',
              description: 'Проверяем снасти и выходим на воду.',
              photoAssets: ['$_cards/fishing.jpg'],
            ),
            EventRoutePoint(
              title: 'Точка ловли',
              location: GeoPoint(latitude: 46.3620, longitude: 48.0710),
              detail: 'Утро на воде',
              description: 'Основная точка рыбалки.',
            ),
          ],
        'astrakhan-embankment' => const [
            EventRoutePoint(
              title: 'Набережная Волги',
              location: GeoPoint(latitude: 46.3491, longitude: 48.0398),
              address: 'Астрахань',
              detail: '18:00 · Старт',
              description: 'Сбор у парапета, дальше вдоль воды.',
              photoAssets: ['$_cards/11.jpg'],
            ),
            EventRoutePoint(
              title: 'Кофе на закате',
              location: GeoPoint(latitude: 46.3518, longitude: 48.0415),
              detail: 'Остановка',
              description: 'Короткая пауза с видом на Волгу.',
              photoAssets: ['$_cards/12.jpg'],
            ),
          ],
        'pool-krasnaya-polyana' => const [
            EventRoutePoint(
              title: 'Парковка / сбор',
              location: GeoPoint(latitude: 43.6789, longitude: 40.2045),
              address: 'Красная Поляна',
              detail: '12:00',
              description: 'Сбор у входа, дальше к бассейну.',
              photoAssets: ['$_cards/pool-kp.jpg'],
            ),
            EventRoutePoint(
              title: 'Бассейн',
              location: GeoPoint(latitude: 43.6802, longitude: 40.2088),
              detail: 'Купание',
              description: 'Основная точка — бассейн с видом на горы.',
              photoAssets: ['$_cards/pool-kp.jpg'],
            ),
          ],
        _ => const [
            EventRoutePoint(
              title: 'Старт',
              location: _sochiCenter,
            ),
            EventRoutePoint(
              title: 'Финиш',
              location: GeoPoint(latitude: 43.5870, longitude: 39.7200),
            ),
          ],
      };
}
