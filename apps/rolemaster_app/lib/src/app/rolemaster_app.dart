import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rolemaster_core/rolemaster_core.dart';

import '../features/visual_alpha/visual_alpha_character_profile.dart';
import '../features/visual_alpha/visual_alpha_landing_page.dart';

final class RolemasterApp extends StatelessWidget {
  const RolemasterApp({
    required this.campaignRepository,
    required this.characterRepository,
    required this.characterProfileRepository,
    required this.rulesetRepository,
    required this.campaignRulesetRepository,
    super.key,
  });

  final CampaignRepository campaignRepository;
  final CharacterRepository characterRepository;
  final VisualAlphaCharacterProfileRepository characterProfileRepository;
  final RulesetRepository rulesetRepository;
  final CampaignRulesetRepository campaignRulesetRepository;

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF59452F),
        brightness: Brightness.dark,
      ),
    );

    return MaterialApp(
      title: 'Rolemaster',
      debugShowCheckedModeBanner: false,
      theme: baseTheme.copyWith(
        textTheme: GoogleFonts.alegreyaTextTheme(baseTheme.textTheme),
      ),
      home: VisualAlphaLandingPage(
        campaignRepository: campaignRepository,
        characterRepository: characterRepository,
        characterProfileRepository: characterProfileRepository,
        rulesetRepository: rulesetRepository,
        campaignRulesetRepository: campaignRulesetRepository,
      ),
    );
  }
}
