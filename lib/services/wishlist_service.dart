import 'package:http/http.dart' as http;
import 'package:primo_secreto_app/models/wishlist_model.dart';
import 'package:primo_secreto_app/services/api_client.dart';

class WishlistService {
  final ApiClient _api = ApiClient.instance;

  Future<WishlistModel> mine(String exchangeUuid) async {
    return WishlistModel.fromJson(
      await _api.get("/exchanges/$exchangeUuid/wishlist"),
    );
  }

  Future<WishlistModel> giftee(String exchangeUuid) async {
    return WishlistModel.fromJson(
      await _api.get("/exchanges/$exchangeUuid/giftee-wishlist"),
    );
  }

  Future<WishlistModel> saveDislikes(
    String exchangeUuid,
    String dislikes,
  ) async {
    final data = await _api.put(
      "/exchanges/$exchangeUuid/wishlist/dislikes",
      body: {"dislikes": dislikes.trim().isEmpty ? null : dislikes.trim()},
    );
    return WishlistModel.fromJson(data);
  }

  Future<WishlistModel> addItem(
    String exchangeUuid, {
    required String title,
    required String description,
    required List<String> links,
    required List<String> newImagePaths,
  }) async {
    final data = await _api.postForm(
      "/exchanges/$exchangeUuid/wishlist/items",
      fields: _fields(title, description, links),
      files: await _images(newImagePaths),
    );
    return WishlistModel.fromJson(data);
  }

  Future<WishlistModel> updateItem(
    String exchangeUuid,
    String itemUuid, {
    required String title,
    required String description,
    required List<String> links,
    required List<String> newImagePaths,
    required List<String> removeImages,
  }) async {
    final data = await _api.postForm(
      "/exchanges/$exchangeUuid/wishlist/items/$itemUuid",
      fields: [
        MapEntry("_method", "PATCH"),
        ..._fields(title, description, links),
        for (final uuid in removeImages) MapEntry("remove_images[]", uuid),
      ],
      files: await _images(newImagePaths),
    );
    return WishlistModel.fromJson(data);
  }

  Future<void> removeItem(String exchangeUuid, String itemUuid) async {
    await _api.delete("/exchanges/$exchangeUuid/wishlist/items/$itemUuid");
  }

  List<MapEntry<String, String>> _fields(
    String title,
    String description,
    List<String> links,
  ) => [
    MapEntry("title", title.trim()),
    if (description.trim().isNotEmpty)
      MapEntry("description", description.trim()),
    for (final link in links) MapEntry("links[]", link),
  ];

  Future<List<http.MultipartFile>> _images(List<String> paths) async => [
    for (final path in paths)
      await http.MultipartFile.fromPath("images[]", path),
  ];
}
