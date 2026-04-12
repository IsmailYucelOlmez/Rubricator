/// Domain entity for an author (display name + bio; no external photo API).
class Author {
  const Author({
    required this.id,
    required this.name,
    required this.bio,
    this.birthDate,
    this.deathDate,
  });

  final String id;
  final String name;
  final String bio;
  final String? birthDate;
  final String? deathDate;
}
