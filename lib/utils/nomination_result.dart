import 'package:primo_secreto_app/models/nomination_model.dart';

enum NominationOutcome { noNominees, noVotes, winner, tie }

class NominationResult {
  NominationOutcome outcome;
  List<NomineeModel> ranking;
  List<NomineeModel> winners;

  NominationResult({
    required this.outcome,
    required this.ranking,
    required this.winners,
  });

  String get winnerLabel {
    switch (outcome) {
      case NominationOutcome.noNominees:
        return "Sin nominados";
      case NominationOutcome.noVotes:
        return "Nadie recibió votos";
      default:
        return winners.map((winner) => winner.name).join(" y ");
    }
  }
}

NominationResult nominationResult(NominationModel nomination) {
  final ranking = [...nomination.nominees]
    ..sort((a, b) => (b.votesCount ?? 0).compareTo(a.votesCount ?? 0));
  final top = ranking.isEmpty ? 0 : (ranking.first.votesCount ?? 0);
  final winners = top > 0
      ? ranking.where((nominee) => nominee.votesCount == top).toList()
      : <NomineeModel>[];

  if (ranking.isEmpty) {
    return NominationResult(
      outcome: NominationOutcome.noNominees,
      ranking: ranking,
      winners: winners,
    );
  }
  if (winners.isEmpty) {
    return NominationResult(
      outcome: NominationOutcome.noVotes,
      ranking: ranking,
      winners: winners,
    );
  }
  return NominationResult(
    outcome: winners.length > 1
        ? NominationOutcome.tie
        : NominationOutcome.winner,
    ranking: ranking,
    winners: winners,
  );
}
