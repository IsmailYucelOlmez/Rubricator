import '../../domain/entities/author.dart';

class AuthorModel {
  const AuthorModel({
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

  Author toEntity() {
    return Author(
      id: id,
      name: name,
      bio: bio,
      birthDate: birthDate,
      deathDate: deathDate,
    );
  }
}
