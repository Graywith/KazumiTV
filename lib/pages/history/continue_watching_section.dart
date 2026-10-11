import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/pages/history/history_page.dart';
import 'package:kazumi/repositories/history_repository.dart';

/// Uses the history page's cards and playback path, including source recovery.
class ContinueWatchingSection extends StatefulWidget {
  const ContinueWatchingSection({super.key});

  @override
  State<ContinueWatchingSection> createState() =>
      _ContinueWatchingSectionState();
}

class _ContinueWatchingSectionState extends State<ContinueWatchingSection> {
  final _repository = inject<IHistoryRepository>();
  late final _changes = _repository.changes;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: _changes,
      builder: (context, _) {
        final entries = _repository.getAllHistories().take(6).toList();
        if (entries.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '继续观看',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.pushNamed('/settings/history/'),
                      child: const Text('全部历史'),
                    ),
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                child: Row(
                  children: [
                    for (final history in entries)
                      Padding(
                        key: ValueKey(history.key),
                        padding: const EdgeInsets.only(right: 12),
                        child: SizedBox(
                          width: 340,
                          child: HistoryCard(
                            history: history,
                            continueWatching: true,
                            editing: false,
                            busy: false,
                            borderRadius: BorderRadius.circular(16),
                            onDelete: () async {},
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
