import 'package:http/http.dart' as http;
import 'package:primo_secreto_app/models/nomination_model.dart';
import 'package:primo_secreto_app/services/api_client.dart';

class NominationsService {
  final ApiClient _api = ApiClient.instance;

  Future<List<NominationModel>> list(String exchangeUuid) async {
    final List data = await _api.get("/exchanges/$exchangeUuid/nominations");
    return data
        .map((nomination) => NominationModel.fromJson(nomination))
        .toList();
  }

  Future<NominationModel> create(
    String exchangeUuid,
    String title,
    String selection,
    String type,
  ) async {
    final data = await _api.post(
      "/exchanges/$exchangeUuid/nominations",
      body: {"title": title, "selection": selection, "type": type},
    );
    return NominationModel.fromJson(data);
  }

  Future<NominationModel> update(
    String exchangeUuid,
    String uuid,
    String title,
    String selection,
    String type,
  ) async {
    final data = await _api.patch(
      "/exchanges/$exchangeUuid/nominations/$uuid",
      body: {"title": title, "selection": selection, "type": type},
    );
    return NominationModel.fromJson(data);
  }

  Future<void> remove(String exchangeUuid, String uuid) async {
    await _api.delete("/exchanges/$exchangeUuid/nominations/$uuid");
  }

  Future<NominationModel> addNominee(
    String exchangeUuid,
    String uuid, {
    String? member,
    String? text,
    String? imagePath,
  }) async {
    final data = await _api.postForm(
      "/exchanges/$exchangeUuid/nominations/$uuid/nominees",
      fields: [
        if (member != null && member.isNotEmpty) MapEntry("member", member),
        if (text != null && text.isNotEmpty) MapEntry("text", text),
      ],
      files: [
        if (imagePath != null)
          await http.MultipartFile.fromPath("image", imagePath),
      ],
    );
    return NominationModel.fromJson(data);
  }

  Future<void> removeNominee(
    String exchangeUuid,
    String uuid,
    String nomineeUuid,
  ) async {
    await _api.delete(
      "/exchanges/$exchangeUuid/nominations/$uuid/nominees/$nomineeUuid",
    );
  }

  Future<NominationModel> vote(
    String exchangeUuid,
    String uuid,
    List<String> nominees,
  ) async {
    final data = await _api.put(
      "/exchanges/$exchangeUuid/nominations/$uuid/votes",
      body: {"nominees": nominees},
    );
    return NominationModel.fromJson(data);
  }
}
