import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

class ZipEntryMeta {
  final String name;
  final int localHeaderOffset;
  final int compressedSize;
  final int uncompressedSize;
  final int compressionMethod; // 0=stored, 8=deflated

  const ZipEntryMeta({
    required this.name,
    required this.localHeaderOffset,
    required this.compressedSize,
    required this.uncompressedSize,
    required this.compressionMethod,
  });
}

/// Lightweight ZIP reader that reads only the central directory and
/// decompresses individual entries on demand — avoids reading the
/// entire file into memory.
class ZipReader {
  RandomAccessFile? _raf;
  List<ZipEntryMeta>? _entries;

  ZipReader._();

  static Future<ZipReader> open(File file) async {
    final reader = ZipReader._();
    reader._raf = await file.open(mode: FileMode.read);
    return reader;
  }

  void close() {
    _raf?.closeSync();
    _raf = null;
  }

  List<ZipEntryMeta> readEntries() {
    if (_entries != null) return _entries!;

    final fileSize = _raf!.lengthSync();
    final tailSize = min(65536, fileSize).toInt();
    _raf!.setPositionSync(fileSize - tailSize);
    final tail = _raf!.readSync(tailSize);

    var eocdPos = -1;
    for (var i = tail.length - 22; i >= 0; i--) {
      if (tail[i] == 0x50 && tail[i + 1] == 0x4b &&
          tail[i + 2] == 0x05 && tail[i + 3] == 0x06) {
        eocdPos = i;
        break;
      }
    }
    if (eocdPos == -1) throw const FormatException('EOCD record not found');

    final eocd = ByteData.sublistView(tail, eocdPos);
    final cdOffset = eocd.getUint32(16, Endian.little);
    final cdSize = eocd.getUint32(12, Endian.little);

    _raf!.setPositionSync(cdOffset);
    final cdBytes = _raf!.readSync(cdSize);
    final cd = ByteData.sublistView(Uint8List.fromList(cdBytes));

    final entries = <ZipEntryMeta>[];
    var pos = 0;
    while (pos + 46 <= cd.lengthInBytes) {
      final sig = cd.getUint32(pos, Endian.little);
      if (sig != 0x02014b50) break;

      final compressionMethod = cd.getUint16(pos + 10, Endian.little);
      final compressedSize = cd.getUint32(pos + 20, Endian.little);
      final uncompressedSize = cd.getUint32(pos + 24, Endian.little);
      final filenameLen = cd.getUint16(pos + 28, Endian.little);
      final extraLen = cd.getUint16(pos + 30, Endian.little);
      final commentLen = cd.getUint16(pos + 32, Endian.little);
      final localHeaderOffset = cd.getUint32(pos + 42, Endian.little);

      final nameBytes = cdBytes.sublist(pos + 46, pos + 46 + filenameLen);
      final name = String.fromCharCodes(nameBytes);

      entries.add(ZipEntryMeta(
        name: name,
        localHeaderOffset: localHeaderOffset,
        compressedSize: compressedSize,
        uncompressedSize: uncompressedSize,
        compressionMethod: compressionMethod,
      ));

      pos += 46 + filenameLen + extraLen + commentLen;
    }

    _entries = entries;
    return entries;
  }

  ZipEntryMeta? findEntry(String name) {
    final entries = readEntries();
    for (final e in entries) {
      if (e.name == name) return e;
    }
    return null;
  }

  /// Reads and decompresses a single entry. Returns raw bytes.
  Uint8List readEntryContent(ZipEntryMeta entry) {
    _raf!.setPositionSync(entry.localHeaderOffset);
    final header = _raf!.readSync(30);
    final headerData = ByteData.sublistView(Uint8List.fromList(header));

    final filenameLen = headerData.getUint16(26, Endian.little);
    final extraLen = headerData.getUint16(28, Endian.little);
    final dataOffset = entry.localHeaderOffset + 30 + filenameLen + extraLen;

    _raf!.setPositionSync(dataOffset);
    final compressed = _raf!.readSync(entry.compressedSize);

    if (entry.compressionMethod == 0) {
      return Uint8List.fromList(compressed);
    }
    if (entry.compressionMethod == 8) {
      return Uint8List.fromList(
        ZLibDecoder(raw: true).convert(compressed),
      );
    }
    throw UnsupportedError(
      'Unsupported compression method: ${entry.compressionMethod}',
    );
  }
}
