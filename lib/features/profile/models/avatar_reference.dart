/// Stable portable references. Temporary picker paths are never persisted.
abstract final class AvatarReference {
  static const presets = [
    'sage',
    'graphite',
    'olive',
    'silver',
    'stone',
    'midnight',
    'fog',
    'ash',
  ];
  static const imagesKey = 'avatar_images_v1';
  static final uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  );
  static String preset(String id) => 'aeon-avatar://preset/$id';
  static String photo(String id) => 'aeon-avatar://photo/$id';
  static String? presetId(String? reference) {
    final id = _id(reference, 'preset');
    return presets.contains(id) ? id : null;
  }

  static String? photoId(String? reference) {
    final id = _id(reference, 'photo');
    return id != null && uuid.hasMatch(id) ? id : null;
  }

  static String? _id(String? reference, String kind) {
    final uri = Uri.tryParse(reference ?? '');
    if (uri == null ||
        uri.scheme != 'aeon-avatar' ||
        uri.host != kind ||
        uri.pathSegments.length != 1 ||
        uri.hasQuery ||
        uri.hasFragment) {
      return null;
    }
    return uri.pathSegments.single;
  }
}
