const Map<String, String> statusLabels = {
  "created": "Creado",
  "in_progress": "En curso",
  "closed": "Cerrado",
  "finished": "Terminado",
};

const int minParticipants = 3;
const List<String> currencies = ["PEN", "USD"];
const String defaultCurrency = "PEN";

class BudgetModel {
  String amount;
  String currency;

  BudgetModel({required this.amount, required this.currency});

  factory BudgetModel.fromJson(Map<String, dynamic> budget) => BudgetModel(
    amount: budget["amount"].toString(),
    currency: budget["currency"],
  );
}

class MemberModel {
  String uuid;
  String? name;
  String? lastName;
  String? avatar;
  String? email;
  bool isPending;
  bool isAdmin;
  bool participates;
  bool isMe;
  bool hasGiftee;
  bool hasDuplicateGiftee;

  MemberModel({
    required this.uuid,
    this.name,
    this.lastName,
    this.avatar,
    this.email,
    required this.isPending,
    required this.isAdmin,
    required this.participates,
    required this.isMe,
    required this.hasGiftee,
    required this.hasDuplicateGiftee,
  });

  String get fullName => "${name ?? ''} ${lastName ?? ''}".trim();

  String get label =>
      fullName.isNotEmpty ? fullName : (email ?? "Participante");

  factory MemberModel.fromJson(Map<String, dynamic> member) => MemberModel(
    uuid: member["uuid"],
    name: member["name"],
    lastName: member["last_name"],
    avatar: member["avatar"],
    email: member["email"],
    isPending: member["is_pending"] ?? false,
    isAdmin: member["is_admin"] ?? false,
    participates: member["participates"] ?? true,
    isMe: member["is_me"] ?? false,
    hasGiftee: member["has_giftee"] ?? false,
    hasDuplicateGiftee: member["has_duplicate_giftee"] ?? false,
  );
}

class GifteeModel {
  String uuid;
  String? name;
  String? lastName;
  String? avatar;

  GifteeModel({required this.uuid, this.name, this.lastName, this.avatar});

  String get fullName {
    final full = "${name ?? ''} ${lastName ?? ''}".trim();
    return full.isEmpty ? "Participante" : full;
  }

  factory GifteeModel.fromJson(Map<String, dynamic> giftee) => GifteeModel(
    uuid: giftee["uuid"],
    name: giftee["name"],
    lastName: giftee["last_name"],
    avatar: giftee["avatar"],
  );
}

class ExchangeModel {
  String uuid;
  String code;
  String title;
  String? description;
  String? image;
  BudgetModel? budget;
  String? eventDate;
  String? location;
  double? latitude;
  double? longitude;
  String status;
  String? drawMethod;
  bool isAdmin;
  bool canEdit;
  bool canManageMembers;
  bool canStartDraw;
  bool canUndoDraw;
  bool assignmentsLocked;
  bool canLockAssignments;
  String? wishlistDeadline;
  bool wishlistLocked;
  bool wishlistClosed;
  String? nominationsDeadline;
  bool nominationsLocked;
  bool nominationsClosed;
  bool votingStarted;
  bool votingClosed;
  bool canStartVoting;
  bool canCloseVoting;
  bool canAssignGiftees;
  bool canChooseGiftee;
  GifteeModel? myGiftee;
  String? creatorName;
  List<String> adminNames;
  int membersCount;
  bool isParticipant;
  List<MemberModel> members;

  ExchangeModel({
    required this.uuid,
    required this.code,
    required this.title,
    this.description,
    this.image,
    this.budget,
    this.eventDate,
    this.location,
    this.latitude,
    this.longitude,
    required this.status,
    this.drawMethod,
    required this.isAdmin,
    required this.canEdit,
    required this.canManageMembers,
    required this.canStartDraw,
    required this.canUndoDraw,
    required this.assignmentsLocked,
    required this.canLockAssignments,
    this.wishlistDeadline,
    required this.wishlistLocked,
    required this.wishlistClosed,
    this.nominationsDeadline,
    required this.nominationsLocked,
    required this.nominationsClosed,
    required this.votingStarted,
    required this.votingClosed,
    required this.canStartVoting,
    required this.canCloseVoting,
    required this.canAssignGiftees,
    required this.canChooseGiftee,
    this.myGiftee,
    this.creatorName,
    required this.adminNames,
    required this.membersCount,
    required this.isParticipant,
    required this.members,
  });

  String get statusLabel => statusLabels[status] ?? status;

  String get initial =>
      title.trim().isEmpty ? "?" : title.trim()[0].toUpperCase();

  List<MemberModel> get participants =>
      members.where((member) => member.participates).toList();

  factory ExchangeModel.fromJson(Map<String, dynamic> exchange) =>
      ExchangeModel(
        uuid: exchange["uuid"],
        code: exchange["code"] ?? "",
        title: exchange["title"],
        description: exchange["description"],
        image: exchange["image"],
        budget: exchange["budget"] == null
            ? null
            : BudgetModel.fromJson(exchange["budget"]),
        eventDate: exchange["event_date"]?.toString().substring(0, 10),
        location: exchange["location"],
        latitude: (exchange["latitude"] as num?)?.toDouble(),
        longitude: (exchange["longitude"] as num?)?.toDouble(),
        status: exchange["status"],
        drawMethod: exchange["draw_method"],
        isAdmin: exchange["is_admin"] ?? false,
        canEdit: exchange["can_edit"] ?? false,
        canManageMembers: exchange["can_manage_members"] ?? false,
        canStartDraw: exchange["can_start_draw"] ?? false,
        canUndoDraw: exchange["can_undo_draw"] ?? false,
        assignmentsLocked: exchange["assignments_locked"] ?? false,
        canLockAssignments: exchange["can_lock_assignments"] ?? false,
        wishlistDeadline: exchange["wishlist_deadline"],
        wishlistLocked: exchange["wishlist_locked"] ?? false,
        wishlistClosed: exchange["wishlist_closed"] ?? false,
        nominationsDeadline: exchange["nominations_deadline"],
        nominationsLocked: exchange["nominations_locked"] ?? false,
        nominationsClosed: exchange["nominations_closed"] ?? false,
        votingStarted: exchange["voting_started"] ?? false,
        votingClosed: exchange["voting_closed"] ?? false,
        canStartVoting: exchange["can_start_voting"] ?? false,
        canCloseVoting: exchange["can_close_voting"] ?? false,
        canAssignGiftees: exchange["can_assign_giftees"] ?? false,
        canChooseGiftee: exchange["can_choose_giftee"] ?? false,
        myGiftee: exchange["my_giftee"] == null
            ? null
            : GifteeModel.fromJson(exchange["my_giftee"]),
        creatorName: exchange["creator_name"],
        adminNames: List<String>.from(exchange["admin_names"] ?? []),
        membersCount: exchange["members_count"] ?? 0,
        isParticipant: exchange["is_participant"] ?? false,
        members: (exchange["members"] as List? ?? [])
            .map((member) => MemberModel.fromJson(member))
            .toList(),
      );
}
