/// Domain entity for an Open Library author (`/authors/{id}`).
class Author {
  const Author({
    required this.id,
    required this.name,
    required this.bio,
    this.birthDate,
    this.deathDate,
    this.photoId,
  });

  final String id;
  final String name;
  final String bio;
  final String? birthDate;
  final String? deathDate;
  final int? photoId;
}
