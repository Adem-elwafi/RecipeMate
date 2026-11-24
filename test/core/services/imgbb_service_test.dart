import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:recipemate/core/services/imgbb_service.dart';

void main() {
  XFile imageFile() => XFile.fromData(
    Uint8List.fromList(<int>[1, 2, 3, 4]),
    name: 'plat.jpg',
    mimeType: 'image/jpeg',
  );

  test('sans clé, le service est désactivé et refuse l’envoi', () async {
    final service = ImgBBService(apiKey: '');

    expect(service.isConfigured, isFalse);
    expect(
      service.uploadImage(file: imageFile()),
      throwsA(
        isA<ImgBBException>().having(
          (error) => error.message,
          'message',
          contains('Clé API ImgBB absente'),
        ),
      ),
    );
  });

  test('renvoie l’URL ImgBB et transmet la clé dans la requête', () async {
    Uri? capturedUri;
    final client = MockClient((request) async {
      capturedUri = request.url;
      return http.Response(
        '{"success":true,"status":200,"data":{"url":"https://i.imgbb.com/test.jpg"}}',
        200,
      );
    });
    final service = ImgBBService(client: client, apiKey: 'cle-de-test');

    final url = await service.uploadImage(file: imageFile(), name: 'plat');

    expect(url, 'https://i.imgbb.com/test.jpg');
    expect(capturedUri!.host, 'api.imgbb.com');
    expect(capturedUri!.path, '/1/upload');
    expect(capturedUri!.queryParameters['key'], 'cle-de-test');
    expect(capturedUri!.queryParameters['name'], 'plat');
  });

  test('rejette une réponse ImgBB invalide', () async {
    final client = MockClient(
      (_) async => http.Response('{"success":false}', 400),
    );
    final service = ImgBBService(client: client, apiKey: 'cle-de-test');

    expect(
      service.uploadImage(file: imageFile()),
      throwsA(isA<ImgBBException>()),
    );
  });

  test('rejette une URL d’image invalide', () async {
    final client = MockClient(
      (_) async => http.Response(
        '{"success":true,"data":{"url":"ftp://invalide"}}',
        200,
      ),
    );
    final service = ImgBBService(client: client, apiKey: 'cle-de-test');

    expect(
      service.uploadImage(file: imageFile()),
      throwsA(
        isA<ImgBBException>().having(
          (error) => error.message,
          'message',
          contains('URL d’image invalide'),
        ),
      ),
    );
  });
}
