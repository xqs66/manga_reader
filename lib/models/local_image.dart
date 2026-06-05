class LocalImage {
  final String? path;
  final String? url;
  final Map<String, String>? headers;

  const LocalImage({this.path, this.url, this.headers});

  bool get isLocal => path != null;
  bool get isRemote => url != null;
}