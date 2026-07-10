import '../../domain/create_route_draft.dart';

enum CreateRoutePointRole { start, middle, finish }

CreateRoutePointRole defaultCreateRoutePointRole(CreateRouteDraft draft) {
  if (!draft.hasStartPoint) return CreateRoutePointRole.start;
  if (!draft.hasFinishPoint) return CreateRoutePointRole.finish;
  return CreateRoutePointRole.middle;
}

String createRoutePointRoleLabel(CreateRoutePointRole role) =>
    switch (role) {
      CreateRoutePointRole.start => 'Старт',
      CreateRoutePointRole.middle => 'Промежуточная точка',
      CreateRoutePointRole.finish => 'Финиш',
    };

String createRoutePointRoleShortLabel(CreateRoutePointRole role) =>
    switch (role) {
      CreateRoutePointRole.start => 'Старт',
      CreateRoutePointRole.middle => 'Промеж.',
      CreateRoutePointRole.finish => 'Финиш',
    };

String createRoutePointAddLabel(CreateRoutePointRole role) =>
    switch (role) {
      CreateRoutePointRole.start => 'Добавить как старт',
      CreateRoutePointRole.middle => 'Добавить точку',
      CreateRoutePointRole.finish => 'Добавить как финиш',
    };
