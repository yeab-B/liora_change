import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/endpoints.dart';
import '../../../models/recovery.dart';

/// `GET /recovery/current` from `docs/mvp/05-api-contract.md` §5.1.
///
/// The contract has no "acknowledge" route: recovery clears itself when the
/// member completes a check-in on the challenge (§5.1's backend rule), so the
/// suggested action is the whole accept path.
class RecoveryRepository {
  const RecoveryRepository(this._dio);

  final Dio _dio;

  Future<Recovery> getCurrent() async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        Endpoints.currentRecovery,
      );
      final dynamic body = response.data;
      if (body is Map && body['data'] is Map) {
        return Recovery.fromJson(
          Map<String, dynamic>.from(body['data'] as Map),
        );
      }
      throw const ApiException(
        message: 'The server returned an unexpected response.',
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}

final Provider<RecoveryRepository> recoveryRepositoryProvider =
    Provider<RecoveryRepository>(
      (Ref ref) => RecoveryRepository(ref.watch(apiClientProvider)),
    );
