import 'package:equatable/equatable.dart';

/// One playable photo puzzle: a title plus either a bundled asset
/// ([imagePath], the developer's own photos) or an internet URL
/// ([imageUrl]). The catalog is manifest-driven (see [PhotoCatalog]), so
/// adding a photo never requires touching game code.
class PhotoPuzzle extends Equatable {
  const PhotoPuzzle({
    required this.id,
    required this.title,
    this.imagePath,
    this.imageUrl,
  });

  final String id;
  final String title;

  /// Local bundled asset, e.g. `assets/images/photos/beach.jpg`.
  final String? imagePath;

  /// Internet image URL (used when there is no bundled asset).
  final String? imageUrl;

  bool get isLocal => imagePath != null;

  /// The source to render — either the asset or the URL.
  String get image => imagePath ?? imageUrl!;

  /// Parses one manifest entry, or returns `null` when it is malformed or
  /// has no usable image source.
  static PhotoPuzzle? tryParse(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final title = json['title'] as String?;
    final image = json['image'] as String?;
    final url = json['url'] as String?;
    if (id == null || id.isEmpty || title == null || title.isEmpty) {
      return null;
    }
    if (image == null && url == null) return null;
    return PhotoPuzzle(id: id, title: title, imagePath: image, imageUrl: url);
  }

  @override
  List<Object?> get props => [id, title, imagePath, imageUrl];
}
