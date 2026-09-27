import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/supabase_trbooks_repository.dart';
import '../../data/repositories/trbook_description_repository_impl.dart';
import '../../domain/repositories/trbook_description_repository.dart';
import '../../domain/repositories/trbooks_repository.dart';
import '../../domain/usecases/trbooks_usecases.dart';

final trbooksRepositoryProvider = Provider<TrbooksRepository>(
  (ref) => SupabaseTrbooksRepository(),
);

final trbookDescriptionRepositoryProvider = Provider<TrbookDescriptionRepository>(
  (ref) => TrbookDescriptionRepositoryImpl(),
);

final submitUserTrbookUseCaseProvider = Provider<SubmitUserTrbookUseCase>(
  (ref) => SubmitUserTrbookUseCase(ref.watch(trbooksRepositoryProvider)),
);

final generateTrbookDescriptionUseCaseProvider = Provider<GenerateTrbookDescriptionUseCase>(
  (ref) => GenerateTrbookDescriptionUseCase(ref.watch(trbookDescriptionRepositoryProvider)),
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

final trbooksByGenreKeyUseCaseProvider = Provider<TrbooksByGenreKeyUseCase>(
  (ref) => TrbooksByGenreKeyUseCase(ref.watch(trbooksRepositoryProvider)),
);
