import 'package:kazumi/bean/tv/tv_support.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:kazumi/bean/widget/loading_indicator.dart';
import 'package:kazumi/bean/widget/tonal_card.dart';
import 'package:kazumi/pages/onboarding/onboarding_step_layout.dart';
import 'package:kazumi/services/logging/logger.dart';

class DisclaimerStep extends StatefulWidget {
  const DisclaimerStep({super.key});

  @override
  State<DisclaimerStep> createState() => _DisclaimerStepState();
}

class _DisclaimerStepState extends State<DisclaimerStep> {
  String? _statementsText;

  @override
  void initState() {
    super.initState();
    _loadStatements();
  }

  Future<void> _loadStatements() async {
    String text;
    try {
      text = await rootBundle.loadString('assets/statements/statements.txt');
    } catch (error, stackTrace) {
      KazumiLogger().e(
        'Onboarding: failed to load statements',
        error: error,
        stackTrace: stackTrace,
      );
      text = '免责声明加载失败，请退出后重试。';
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _statementsText = text;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return OnboardingStepLayout(
      leading: const OnboardingStepIcon(icon: Icons.waving_hand_rounded),
      title: '欢迎来到 Kazumi',
      child: TonalCard(
        padding: EdgeInsets.all(isTv ? 12 : 24),
        child: _statementsText == null
            ? const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: LoadingIndicator()),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.description_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '免责声明',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isTv ? 10 : 20),
                  for (final paragraph in _statementsText!.trim().split('\n'))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        paragraph.trim(),
                        style: textTheme.bodyMedium?.copyWith(
                          height: isTv ? 1.3 : 1.7,
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
