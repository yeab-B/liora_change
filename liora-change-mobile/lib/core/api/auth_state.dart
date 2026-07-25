import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Set to true when Dio interceptor clears token on 401.
final authExpiredProvider = StateProvider<bool>((ref) => false);
