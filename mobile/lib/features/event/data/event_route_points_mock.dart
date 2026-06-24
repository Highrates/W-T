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
                  'будет с табличкой Walk&Talk.',
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
