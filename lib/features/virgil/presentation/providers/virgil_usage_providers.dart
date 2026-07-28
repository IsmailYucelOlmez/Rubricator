import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/presentation/auth_provider.dart';
import '../../data/datasources/virgil_usage_remote_datasource.dart';

final virgilUsageRemoteDataSourceProvider =
    Provider<VirgilUsageRemoteDataSource>(
  (ref) => VirgilUsageRemoteDataSource(Supabase.instance.client),
);

/// Today's Virgil quotas for the signed-in user. Null when signed out.
final virgilUsageTodayProvider =
    FutureProvider.autoDispose<VirgilUsageToday?>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return null;
  return ref.watch(virgilUsageRemoteDataSourceProvider).fetchToday();
});

final virgilUsageServiceProvider = Provider<VirgilUsageService>((ref) {
  return VirgilUsageService(
    ref.watch(virgilUsageRemoteDataSourceProvider),
    onConsumed: () => ref.invalidate(virgilUsageTodayProvider),
  );
});

class VirgilUsageService {
  VirgilUsageService(this._remote, {required this.onConsumed});

  final VirgilUsageRemoteDataSource _remote;
  final void Function() onConsumed;

  Future<void> consumeRecommendation() async {
    await _remote.consume(VirgilUsageAction.recommendation);
    onConsumed();
  }

  Future<void> consumeUpload() async {
    await _remote.consume(VirgilUsageAction.upload);
    onConsumed();
  }
}
