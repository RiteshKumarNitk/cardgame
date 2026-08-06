// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:typed_data';

void main() async {
  final targetDir = Directory('assets/images/collections');
  if (!await targetDir.exists()) {
    await targetDir.create(recursive: true);
  }

  final client = HttpClient();

  print('Downloading 300 images. This may take a moment...');

  // We can download concurrently, but let's batch them to avoid overwhelming the server.
  const batchSize = 20;
  for (int i = 1; i <= 300; i += batchSize) {
    final futures = <Future<void>>[];
    for (int j = i; j < i + batchSize && j <= 300; j++) {
      futures.add(_downloadImage(client, j, targetDir));
    }
    await Future.wait(futures);
    print('Completed batch ${i ~/ batchSize + 1} / ${300 ~/ batchSize}');
  }

  client.close();
  print('Successfully downloaded all 300 level images!');
}

Future<void> _downloadImage(HttpClient client, int level, Directory targetDir) async {
  final file = File('${targetDir.path}/level_$level.jpg');
  if (await file.exists()) {
    return; // Skip if already downloaded
  }

  try {
    final request = await client.getUrl(Uri.parse('https://picsum.photos/seed/puzzle-cards-$level/600/800'));
    final response = await request.close();
    
    if (response.statusCode == 200) {
      final bytes = await consolidateHttpClientResponseBytes(response);
      await file.writeAsBytes(bytes);
    } else {
      print('Failed to download level $level (Status ${response.statusCode})');
    }
  } catch (e) {
    print('Error downloading level $level: $e');
  }
}

Future<Uint8List> consolidateHttpClientResponseBytes(HttpClientResponse response) async {
  final builder = BytesBuilder();
  await for (var chunk in response) {
    builder.add(chunk);
  }
  return builder.takeBytes();
}
