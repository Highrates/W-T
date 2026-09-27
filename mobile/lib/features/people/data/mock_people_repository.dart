import '../../../shared/models/user_profile.dart';
import '../../profile/data/user_profile_repository.dart';
import '../../shell/domain/feed_query.dart';
import 'people_mock.dart';
import 'people_repository.dart';

class MockPeopleRepository implements PeopleRepository {
  MockPeopleRepository(this._profiles);

  final UserProfileRepository _profiles;

  @override
  Future<List<UserProfile>> listPeople({FeedQuery? query}) async {
    final results = <UserProfile>[];
    for (final id in PeopleMock.profileIds) {
      final profile = await _profiles.getProfile(id);
      if (profile != null) results.add(profile);
    }
    return results;
  }
}
