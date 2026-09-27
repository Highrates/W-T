import '../../../shared/models/user_profile.dart';
import '../../shell/domain/feed_query.dart';

abstract interface class PeopleRepository {
  Future<List<UserProfile>> listPeople({FeedQuery? query});
}
