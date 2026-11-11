import 'package:http/http.dart' as http;
import 'package:primo_secreto_app/models/exchange_model.dart';
import 'package:primo_secreto_app/services/api_client.dart';

class ExchangeService {
  final ApiClient _api = ApiClient.instance;

  Future<List<ExchangeModel>> list() async {
    final List data = await _api.get("/exchanges");
    return data.map((exchange) => ExchangeModel.fromJson(exchange)).toList();
  }

  Future<ExchangeModel> get(String uuid) async {
    return ExchangeModel.fromJson(await _api.get("/exchanges/$uuid"));
  }

  Future<ExchangeModel> create({
    required String title,
    required String description,
    required List<String> members,
    required bool includeMe,
    required String budgetAmount,
    required String budgetCurrency,
    required String eventDate,
    required String location,
    double? latitude,
    double? longitude,
    String? imagePath,
  }) async {
    final optional = {
      "description": description,
      "budget_amount": budgetAmount,
      "budget_currency": budgetCurrency,
      "event_date": eventDate,
      "location": location,
      "latitude": latitude?.toString() ?? "",
      "longitude": longitude?.toString() ?? "",
    };
    final data = await _api.postForm(
      "/exchanges",
      fields: [
        MapEntry("title", title.trim()),
        MapEntry("include_me", includeMe ? "1" : "0"),
        for (final email in members) MapEntry("members[]", email),
        for (final field in optional.entries)
          if (field.value.trim().isNotEmpty)
            MapEntry(field.key, field.value.trim()),
      ],
      files: [
        if (imagePath != null)
          await http.MultipartFile.fromPath("image", imagePath),
      ],
    );
    return ExchangeModel.fromJson(data);
  }

  Future<ExchangeModel> update(
    String uuid, {
    required String title,
    required String description,
    required String budgetAmount,
    required String budgetCurrency,
    required String eventDate,
    required String location,
    double? latitude,
    double? longitude,
    String? imagePath,
    bool removeImage = false,
  }) async {
    final data = await _api.postForm(
      "/exchanges/$uuid",
      fields: [
        MapEntry("_method", "PATCH"),
        MapEntry("title", title.trim()),
        MapEntry("description", description.trim()),
        MapEntry("budget_amount", budgetAmount.trim()),
        MapEntry("budget_currency", budgetCurrency),
        MapEntry("event_date", eventDate),
        MapEntry("location", location.trim()),
        MapEntry("latitude", latitude?.toString() ?? ""),
        MapEntry("longitude", longitude?.toString() ?? ""),
        if (imagePath == null && removeImage) MapEntry("remove_image", "1"),
      ],
      files: [
        if (imagePath != null)
          await http.MultipartFile.fromPath("image", imagePath),
      ],
    );
    return ExchangeModel.fromJson(data);
  }

  Future<ExchangeModel> addMembers(String uuid, List<String> emails) async {
    return ExchangeModel.fromJson(
      await _api.post("/exchanges/$uuid/members", body: {"emails": emails}),
    );
  }

  Future<ExchangeModel> updateMember(
    String uuid,
    String memberUuid, {
    bool? isAdmin,
    bool? participates,
  }) async {
    final data = await _api.patch(
      "/exchanges/$uuid/members/$memberUuid",
      body: {"is_admin": ?isAdmin, "participates": ?participates},
    );
    return ExchangeModel.fromJson(data);
  }

  Future<ExchangeModel?> removeMember(String uuid, String memberUuid) async {
    final data = await _api.delete("/exchanges/$uuid/members/$memberUuid");
    return data == null ? null : ExchangeModel.fromJson(data);
  }

  Future<ExchangeModel> startDraw(String uuid, String method) async {
    return ExchangeModel.fromJson(
      await _api.post("/exchanges/$uuid/draw", body: {"method": method}),
    );
  }

  Future<ExchangeModel> undoDraw(String uuid) async {
    return ExchangeModel.fromJson(
      await _api.post("/exchanges/$uuid/draw/undo"),
    );
  }

  Future<ExchangeModel> lockAssignments(String uuid) async {
    return ExchangeModel.fromJson(
      await _api.post("/exchanges/$uuid/draw/lock"),
    );
  }

  Future<ExchangeModel> setGiftee(
    String uuid,
    String memberUuid,
    String? gifteeUuid,
  ) async {
    final data = await _api.put(
      "/exchanges/$uuid/members/$memberUuid/giftee",
      body: {"giftee": gifteeUuid},
    );
    return ExchangeModel.fromJson(data);
  }

  Future<ExchangeModel> updateWishlistSettings(
    String uuid, {
    String? deadline,
    required bool locked,
  }) async {
    final data = await _api.put(
      "/exchanges/$uuid/wishlist-settings",
      body: {"deadline": deadline, "locked": locked},
    );
    return ExchangeModel.fromJson(data);
  }

  Future<ExchangeModel> updateNominationsSettings(
    String uuid, {
    String? deadline,
    required bool locked,
  }) async {
    final data = await _api.put(
      "/exchanges/$uuid/nominations-settings",
      body: {"deadline": deadline, "locked": locked},
    );
    return ExchangeModel.fromJson(data);
  }

  Future<ExchangeModel> startVoting(String uuid) async {
    return ExchangeModel.fromJson(
      await _api.post("/exchanges/$uuid/voting/start"),
    );
  }

  Future<ExchangeModel> closeVoting(String uuid) async {
    return ExchangeModel.fromJson(
      await _api.post("/exchanges/$uuid/voting/close"),
    );
  }
}
