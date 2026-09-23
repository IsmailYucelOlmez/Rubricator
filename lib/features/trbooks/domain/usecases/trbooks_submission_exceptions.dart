/// Client-side pre-validation failure (empty field, malformed ISBN) — never
/// reaches the `submit_user_trbook` RPC.
class TrbooksValidationException implements Exception {
  TrbooksValidationException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// The submitted ISBN already exists in `trbooks`. [existingId] is a
/// `trbooks:<isbn-or-uuid>` id that can be resolved via
/// [ResolveBookByIdUseCase] to open the existing book instead of creating a
/// near-duplicate.
class TrbooksDuplicateIsbnException implements Exception {
  TrbooksDuplicateIsbnException(this.existingId);
  final String existingId;

  @override
  String toString() => 'DUPLICATE_ISBN:$existingId';
}
