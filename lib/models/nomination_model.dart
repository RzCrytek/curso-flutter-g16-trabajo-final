const int maxNominees = 3;

const Map<String, String> typeLabels = {
  "participants": "Participantes",
  "text": "Texto",
  "images": "Imágenes",
};

const Map<String, String> selectionLabels = {
  "single": "Un solo nominado",
  "multiple": "Varios nominados",
};

class NomineePersonModel {
  String uuid;
  String? name;
  String? lastName;
  String? avatar;
  bool isMe;

  NomineePersonModel({
    required this.uuid,
    this.name,
    this.lastName,
    this.avatar,
    required this.isMe,
  });

  factory NomineePersonModel.fromJson(Map<String, dynamic> person) =>
      NomineePersonModel(
        uuid: person["uuid"],
        name: person["name"],
        lastName: person["last_name"],
        avatar: person["avatar"],
        isMe: person["is_me"] ?? false,
      );
}

class NomineeModel {
  String uuid;
  String? text;
  String? image;
  NomineePersonModel? person;
  int? votesCount;
  bool voted;
  bool canRemove;

  NomineeModel({
    required this.uuid,
    this.text,
    this.image,
    this.person,
    this.votesCount,
    required this.voted,
    required this.canRemove,
  });

  String get name => person != null
      ? "${person!.name ?? ''} ${person!.lastName ?? ''}".trim()
      : (text ?? "");

  factory NomineeModel.fromJson(Map<String, dynamic> nominee) => NomineeModel(
    uuid: nominee["uuid"],
    text: nominee["text"],
    image: nominee["image"],
    person: nominee["person"] == null
        ? null
        : NomineePersonModel.fromJson(nominee["person"]),
    votesCount: nominee["votes_count"],
    voted: nominee["voted"] ?? false,
    canRemove: nominee["can_remove"] ?? false,
  );
}

class NominationModel {
  String uuid;
  String title;
  String selection;
  String type;
  String? creatorName;
  bool canEdit;
  bool canChangeType;
  int totalVotes;
  bool canVote;
  bool canContribute;
  List<NomineeModel> nominees;

  NominationModel({
    required this.uuid,
    required this.title,
    required this.selection,
    required this.type,
    this.creatorName,
    required this.canEdit,
    required this.canChangeType,
    required this.totalVotes,
    required this.canVote,
    required this.canContribute,
    required this.nominees,
  });

  factory NominationModel.fromJson(Map<String, dynamic> nomination) =>
      NominationModel(
        uuid: nomination["uuid"],
        title: nomination["title"],
        selection: nomination["selection"],
        type: nomination["type"],
        creatorName: nomination["creator_name"],
        canEdit: nomination["can_edit"] ?? false,
        canChangeType: nomination["can_change_type"] ?? false,
        totalVotes: nomination["total_votes"] ?? 0,
        canVote: nomination["can_vote"] ?? false,
        canContribute: nomination["can_contribute"] ?? false,
        nominees: (nomination["nominees"] as List? ?? [])
            .map((nominee) => NomineeModel.fromJson(nominee))
            .toList(),
      );
}
