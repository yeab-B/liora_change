import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../models/check_in_models.dart';

abstract class ChallengeRepository {
  Future<Challenge> getChallenge(int id);
  Future<Challenge> activateChallenge(int id);
  Future<List<CheckIn>> getCheckIns(int id);
  Future<CheckInResult> submitCheckIn({
    required int challengeId,
    required String status,
    String? note,
  });
}

class ApiChallengeRepository implements ChallengeRepository {
  ApiChallengeRepository(this._dio);

  final Dio _dio;

  @override
  Future<Challenge> getChallenge(int id) async {
    final response = await _dio.get<Map<String, dynamic>>(ApiEndpoints.challenge(id));
    return Challenge.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  @override
  Future<Challenge> activateChallenge(int id) async {
    final response =
        await _dio.post<Map<String, dynamic>>(ApiEndpoints.activateChallenge(id));
    return Challenge.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  @override
  Future<List<CheckIn>> getCheckIns(int id) async {
    final response =
        await _dio.get<Map<String, dynamic>>(ApiEndpoints.checkIns(id));
    final list = response.data!['data'] as List<dynamic>;
    return list
        .map((e) => CheckIn.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<CheckInResult> submitCheckIn({
    required int challengeId,
    required String status,
    String? note,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.checkIns(challengeId),
      data: {
        'status': status,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
    return CheckInResult.fromJson(response.data!['data'] as Map<String, dynamic>);
  }
}

final challengeRepositoryProvider = Provider<ChallengeRepository>((ref) {
  return ApiChallengeRepository(ref.watch(dioProvider));
});
