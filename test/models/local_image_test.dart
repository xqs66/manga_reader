import 'package:flutter_test/flutter_test.dart';
import 'package:manga_reader/models/local_image.dart';

void main() {
  group('LocalImage', () {
    test('isLocal is true when path is set', () {
      const image = LocalImage(path: '/some/path.jpg');
      expect(image.isLocal, isTrue);
      expect(image.isRemote, isFalse);
    });

    test('isRemote is true when url is set', () {
      const image = LocalImage(url: 'http://example.com/img.jpg');
      expect(image.isRemote, isTrue);
      expect(image.isLocal, isFalse);
    });

    test('isLocal is false when path is null', () {
      const image = LocalImage();
      expect(image.isLocal, isFalse);
      expect(image.isRemote, isFalse);
    });

    test('both isLocal and isRemote can be false for empty construction', () {
      const image = LocalImage();
      expect(image.path, isNull);
      expect(image.url, isNull);
      expect(image.headers, isNull);
    });

    test('url and headers are set correctly for remote images', () {
      const headers = {'X-Auth-Token': 'abc123'};
      const image = LocalImage(
        url: 'http://192.168.1.100:9090/api/v1/mangas/abc/pages/0',
        headers: headers,
      );
      expect(image.url, 'http://192.168.1.100:9090/api/v1/mangas/abc/pages/0');
      expect(image.headers, headers);
      expect(image.isRemote, isTrue);
      expect(image.isLocal, isFalse);
    });

    test('local image with path set', () {
      const image = LocalImage(path: '/data/manga/page_001.jpg');
      expect(image.path, '/data/manga/page_001.jpg');
      expect(image.isLocal, isTrue);
    });

    test('const constructor works for both local and remote', () {
      const local = LocalImage(path: '/local.jpg');
      const remote = LocalImage(url: 'http://remote.jpg', headers: {'k': 'v'});

      expect(local.isLocal, isTrue);
      expect(remote.isRemote, isTrue);
    });
  });
}
