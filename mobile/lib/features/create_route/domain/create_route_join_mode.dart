/// Как принимаются участники (см. `Route.join_mode` на бэкенде).
enum CreateRouteJoinMode {
  /// До лимита — автоматически.
  auto,

  /// Организатор подтверждает каждую заявку.
  approval,
}

/// Дефолт по продуктовым правилам: 1×1 → approval, иначе auto.
CreateRouteJoinMode defaultCreateRouteJoinMode({required bool isOneOnOne}) {
  return isOneOnOne ? CreateRouteJoinMode.approval : CreateRouteJoinMode.auto;
}
