import '../../domain/repositories/trbook_description_repository.dart';
import '../datasources/trbook_description_api_datasource.dart';

class TrbookDescriptionRepositoryImpl implements TrbookDescriptionRepository {
  TrbookDescriptionRepositoryImpl({TrbookDescriptionApiDataSource? dataSource})
      : _dataSource = dataSource ?? TrbookDescriptionApiDataSource();

  final TrbookDescriptionApiDataSource _dataSource;

  @override
  Future<String> generateDescription({
    required String title,
    required String author,
    required String isbn,
  }) {
    return _dataSource.generateDescription(
      title: title,
      author: author,
      isbn: isbn,
    );
  }
}
