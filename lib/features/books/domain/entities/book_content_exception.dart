/// Validation / auth failures raised while adding or editing book content
/// (reviews, quotes, ratings). The UI maps [error] to a localized message
/// instead of matching on exception text.
enum BookContentError {
  signInRequired,
  reviewTooShort,
  titleRequired,
  invalidUrl,
  quoteRequired,
  ratingOutOfRange,
}

class BookContentException implements Exception {
  const BookContentException(this.error);

  final BookContentError error;

  @override
  String toString() => 'BookContentException(${error.name})';
}
