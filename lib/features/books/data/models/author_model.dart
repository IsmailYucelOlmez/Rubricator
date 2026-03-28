import '../../domain/entities/author.dart';

class AuthorModel {
  const AuthorModel({
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

  Author toEntity() {
    return Author(
      id: id,
      name: name,
      bio: bio,
      birthDate: birthDate,
      deathDate: deathDate,
      photoId: photoId,
    );
  }

  static String _normalizeBio(dynamic raw) {
    if (raw == null) return '';
    if (raw is String) return raw;
    if (raw is Map) {
      final v = raw['value'];
      if (v is String) return v;
    }
    return '';
  }

  factory AuthorModel.fromJson(Map<String, dynamic> json) {
    final key = json['key'] as String? ?? '';
    final id = key.replaceFirst(RegExp(r'^/authors/'), '');
    final photos = json['photos'];
    int? photoId;
    if (photos is List && photos.isNotEmpty) {
      final p = photos.first;
      if (p is int) photoId = p;
    }
    return AuthorModel(
      id: id.isEmpty ? 'unknown' : id,
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? json['name'] as String
          : 'Unknown author',
      bio: _normalizeBio(json['bio'] ?? json['comment']),
      birthDate: json['birth_date'] as String?,
      deathDate: json['death_date'] as String?,
      photoId: photoId,
    );
  }
}
