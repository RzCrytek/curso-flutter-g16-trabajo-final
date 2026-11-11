const int maxWishImages = 5;
const int maxWishLinks = 5;

class WishImageModel {
  String uuid;
  String url;

  WishImageModel({required this.uuid, required this.url});

  factory WishImageModel.fromJson(Map<String, dynamic> image) =>
      WishImageModel(uuid: image["uuid"], url: image["url"]!);
}

class WishLinkModel {
  String url;
  String? videoUrl;

  WishLinkModel({required this.url, this.videoUrl});

  factory WishLinkModel.fromJson(Map<String, dynamic> link) =>
      WishLinkModel(url: link["url"], videoUrl: link["video_url"]);
}

class WishItemModel {
  String uuid;
  String title;
  String? description;
  List<WishLinkModel> links;
  List<WishImageModel> images;

  WishItemModel({
    required this.uuid,
    required this.title,
    this.description,
    required this.links,
    required this.images,
  });

  factory WishItemModel.fromJson(Map<String, dynamic> item) => WishItemModel(
    uuid: item["uuid"],
    title: item["title"],
    description: item["description"],
    links: (item["links"] as List? ?? [])
        .map((link) => WishLinkModel.fromJson(link))
        .toList(),
    images: (item["images"] as List? ?? [])
        .map((image) => WishImageModel.fromJson(image))
        .toList(),
  );
}

class WishlistModel {
  String? dislikes;
  List<WishItemModel> items;

  WishlistModel({this.dislikes, required this.items});

  factory WishlistModel.fromJson(Map<String, dynamic> wishlist) =>
      WishlistModel(
        dislikes: wishlist["dislikes"],
        items: (wishlist["items"] as List? ?? [])
            .map((item) => WishItemModel.fromJson(item))
            .toList(),
      );
}
