import '../../../core/network/api_client.dart';
import '../../../models/review_model.dart';

class ReviewService {
  final _api = ApiClient();

  Future<List<ReviewModel>> getUserReviews(int userId) async {
    final res = await _api.dio.get('/reviews/user/$userId');
    return (res.data as List).map((e) => ReviewModel.fromJson(e)).toList();
  }

  Future<void> createReview({
    required int revieweeId,
    required int listingId,
    required int rating,
    String? comment,
  }) async {
    await _api.dio.post('/reviews', data: {
      'revieweeId': revieweeId,
      'listingId': listingId,
      'rating': rating,
      'comment': comment,
    });
  }
}
