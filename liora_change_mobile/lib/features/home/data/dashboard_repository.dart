import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/endpoints.dart';
import '../../../models/dashboard.dart';

/// `GET /dashboard` from `docs/mvp/05-api-contract.md` §4.1 — the single call
/// Home renders from.
class DashboardRepository {
  const DashboardRepository(this._dio);

  final Dio _dio;

  Future<Dashboard> getDashboard() async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        Endpoints.dashboard,
      );
      final dynamic body = response.data;
      if (body is Map && body['data'] is Map) {
        return Dashboard.fromJson(
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

final Provider<DashboardRepository> dashboardRepositoryProvider =
    Provider<DashboardRepository>(
      (Ref ref) => DashboardRepository(ref.watch(apiClientProvider)),
    );
