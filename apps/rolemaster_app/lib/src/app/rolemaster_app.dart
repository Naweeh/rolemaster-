import 'package:flutter/material.dart';
import 'package:rolemaster_core/rolemaster_core.dart';

import '../features/visual_alpha/visual_alpha_landing_page.dart';

final class RolemasterApp extends StatelessWidget {
  const RolemasterApp({
    required this.campaignRepository,
    required this.rulesetRepository,
    required this.campaignRulesetRepository,
    super.key,
  });

  final CampaignRepository campaignRepository;
  final RulesetRepository rulesetRepository;
  final CampaignRulesetRepository campaignRulesetRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rolemaster',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF59452F),
          brightness: Brightness.dark,
        ),
      ),
      home: VisualAlphaLandingPage(
        campaignRepository: campaignRepository,
        rulesetRepository: rulesetRepository,
        campaignRulesetRepository: campaignRulesetRepository,
      ),
    );
  }
}
