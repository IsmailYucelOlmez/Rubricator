/// Generates an AI-assisted Turkish book description, kept separate from
/// [TrbooksRepository] since it talks to the FastAPI/Gemini backend rather
/// than the `trbooks` table.
abstract class TrbookDescriptionRepository {
  Future<String> generateDescription({
    required String title,
    required String author,
    required String isbn,
  });
}
