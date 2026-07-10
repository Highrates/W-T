import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/geo/data/geo_api_client.dart';
import '../../features/geo/data/geo_repository.dart';

final geoApiClientProvider = Provider<GeoApiClient>((ref) {
  return GeoApiClient();
});

final geoRepositoryProvider = Provider<GeoRepository>((ref) {
  return GeoRepositoryImpl(ref.watch(geoApiClientProvider));
});
