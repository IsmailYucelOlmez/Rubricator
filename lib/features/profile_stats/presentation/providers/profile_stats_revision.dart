import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Increment to refetch rating-dependent profile stats without circular imports.
final userRatingsRevisionProvider = StateProvider<int>((ref) => 0);
