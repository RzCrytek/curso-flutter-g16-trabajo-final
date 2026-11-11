import 'dart:async';

import 'package:flutter/material.dart';
import 'package:primo_secreto_app/widgets/common/broken_image_widget.dart';
import 'package:primo_secreto_app/models/nomination_model.dart';
import 'package:primo_secreto_app/utils/format_utils.dart';
import 'package:primo_secreto_app/utils/nomination_result.dart';
import 'package:primo_secreto_app/widgets/common/avatar_widget.dart';

const int _countdownStart = 3;

class CeremonyPage extends StatefulWidget {
  final String title;
  final List<NominationModel> nominations;

  const CeremonyPage({
    super.key,
    required this.title,
    required this.nominations,
  });

  @override
  State<CeremonyPage> createState() => _CeremonyPageState();
}

class _CeremonyPageState extends State<CeremonyPage> {
  final PageController _pageController = PageController();

  int _index = 0;
  int? _countdown;
  Timer? _timer;
  final Set<String> _revealed = {};

  int get _slides => widget.nominations.length + 1;

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _stopCountdown() {
    _timer?.cancel();
    _timer = null;
    _countdown = null;
  }

  void _reveal(NominationModel nomination) {
    if (_countdown != null) return;

    setState(() => _countdown = _countdownStart);
    _timer = Timer.periodic(Duration(milliseconds: 800), (timer) {
      final left = (_countdown ?? 1) - 1;
      setState(() {
        if (left <= 0) {
          _stopCountdown();
          _revealed.add(nomination.uuid);
        } else {
          _countdown = left;
        }
      });
    });
  }

  void _go(int index) {
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Widget _nomineeTile(NomineeModel nominee, bool isWinner) {
    final colors = Theme.of(context).colorScheme;
    final Widget leading = nominee.person != null
        ? AvatarWidget(
            src: nominee.person!.avatar,
            name: nominee.person!.name ?? "",
            lastName: nominee.person!.lastName,
            size: 48,
          )
        : nominee.image != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                nominee.image!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: brokenImageOf(48),
              ),
            )
          : CircleAvatar(radius: 24, child: Icon(Icons.format_quote));

    return Card(
      color: isWinner ? colors.primaryContainer : null,
      child: ListTile(
        leading: leading,
        title: Text(
          nominee.name,
          style: TextStyle(fontWeight: isWinner ? FontWeight.bold : null),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(pluralize(nominee.votesCount ?? 0, "voto", "votos")),
            if (isWinner)
              Padding(
                padding: EdgeInsets.only(left: 8),
                child: Text("🏆"),
              ),
          ],
        ),
      ),
    );
  }

  Widget _nominationSlide(NominationModel nomination) {
    final result = nominationResult(nomination);
    final revealed = _revealed.contains(nomination.uuid);
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: EdgeInsets.all(24),
      children: [
        Text(
          nomination.title,
          style: textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 24),
        if (!revealed && _countdown == null) ...[
          SizedBox(height: 48),
          Icon(Icons.emoji_events, size: 72),
          SizedBox(height: 24),
          Center(
            child: FilledButton(
              onPressed: () => _reveal(nomination),
              child: Text("Revelar al ganador"),
            ),
          ),
        ] else if (!revealed) ...[
          SizedBox(height: 64),
          Center(child: Text("$_countdown", style: textTheme.displayLarge)),
        ] else ...[
          Text(
            result.winnerLabel,
            style: textTheme.headlineMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          if (result.outcome == NominationOutcome.tie)
            Text("¡Empate!", textAlign: TextAlign.center),
          SizedBox(height: 16),
          for (final nominee in result.ranking)
            _nomineeTile(nominee, result.winners.contains(nominee)),
        ],
      ],
    );
  }

  Widget _summarySlide() {
    return ListView(
      padding: EdgeInsets.all(24),
      children: [
        Text(
          "Resumen",
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16),
        for (final nomination in widget.nominations)
          Card(
            child: ListTile(
              title: Text(nomination.title),
              subtitle: Text(nominationResult(nomination).winnerLabel),
              leading: Text("🏆", style: TextStyle(fontSize: 24)),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _slides - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(24),
          child: Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              isLast ? "Resumen" : "Nominación ${_index + 1} de ${_slides - 1}",
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() {
                  _stopCountdown();
                  _index = index;
                }),
                children: [
                  for (final nomination in widget.nominations)
                    _nominationSlide(nomination),
                  _summarySlide(),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: _index == 0 ? null : () => _go(_index - 1),
                    icon: Icon(Icons.chevron_left),
                    label: Text("Anterior"),
                  ),
                  isLast
                      ? FilledButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text("Terminar"),
                        )
                      : TextButton.icon(
                          onPressed: () => _go(_index + 1),
                          iconAlignment: IconAlignment.end,
                          icon: Icon(Icons.chevron_right),
                          label: Text("Siguiente"),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
