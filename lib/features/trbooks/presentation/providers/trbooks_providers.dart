import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/supabase_trbooks_repository.dart';
import '../../domain/repositories/trbooks_repository.dart';
import '../../domain/usecases/trbooks_usecases.dart';

final trbooksRepositoryProvider = Provider<TrbooksRepository>(
  (ref) => SupabaseTrbooksRepository(),
);

final searchTrbooksUseCaseProvider = Provider<SearchTrbooksUseCase>(
  (ref) => SearchTrbooksUseCase(ref.watch(trbooksRepositoryProvider)),
);

final popularTrbooksUseCaseProvider = Provider<PopularTrbooksUseCase>(
  (ref) => PopularTrbooksUseCase(ref.watch(trbooksRepositoryProvider)),
);

final trbooksByKeywordUseCaseProvider = Provider<TrbooksByKeywordUseCase>(
  (ref) => TrbooksByKeywordUseCase(ref.watch(trbooksRepositoryProvider)),
);
