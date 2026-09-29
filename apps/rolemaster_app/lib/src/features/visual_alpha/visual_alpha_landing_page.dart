import 'package:flutter/material.dart';
import 'package:rolemaster_core/rolemaster_core.dart';

import '../../app/error_logging.dart';
import '../campaign/campaign_home_page.dart';
import 'visual_alpha_character_panel.dart';
import 'visual_alpha_character_profile.dart';
import 'visual_alpha_dice_panel.dart';
import 'visual_alpha_workspace.dart';

final class VisualAlphaLandingPage extends StatefulWidget {
  const VisualAlphaLandingPage({
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
  State<VisualAlphaLandingPage> createState() => _VisualAlphaLandingPageState();
}

final class _VisualAlphaLandingPageState extends State<VisualAlphaLandingPage> {
  Campaign? _campaign;
  CampaignRulesetState? _state;
  RulesetPackage? _package;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final campaigns = await widget.campaignRepository.getAll();
      if (campaigns.isEmpty) {
        if (!mounted) return;
        setState(() => _loading = false);
        return;
      }

      final campaign = campaigns.first;
      final state =
          await widget.campaignRulesetRepository.getForCampaign(campaign.id);
      RulesetPackage? package;
      if (state != null) {
        package = await widget.rulesetRepository.getPackage(
          rulesetId: state.binding.rulesetId,
          version: state.binding.rulesetVersion,
        );
      }

      if (!mounted) return;
      setState(() {
        _campaign = campaign;
        _state = state;
        _package = package;
        _loading = false;
      });
    } catch (error) {
      recordHandledRolemasterError('ui.campaign.load.failed', error);
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  void _openCampaigns() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => CampaignHomePage(
          campaignRepository: widget.campaignRepository,
          rulesetRepository: widget.rulesetRepository,
          campaignRulesetRepository: widget.campaignRulesetRepository,
        ),
      ),
    );
  }

  Future<void> _openDicePanel() async {
    final package = _package;
    if (package == null) return;
    await showVisualAlphaDicePanel(context, rulesetPackage: package);
  }

  Future<void> _openCharacterPanel() async {
    final campaign = _campaign;
    final package = _package;
    if (campaign == null || package == null) return;
    await showVisualAlphaCharacterPanel(
      context,
      campaign: campaign,
      rulesetPackage: package,
      campaignRepository: widget.campaignRepository,
      characterRepository: widget.characterRepository,
      profileRepository: widget.characterProfileRepository,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rolemaster'),
        actions: <Widget>[
          TextButton.icon(
            onPressed: _openCampaigns,
            icon: const Icon(Icons.auto_stories_outlined),
            label: const Text('Campañas'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(context),
      floatingActionButton: _package == null
          ? null
          : Wrap(
              spacing: 10,
              children: <Widget>[
                FloatingActionButton.extended(
                  heroTag: 'characters',
                  onPressed: _openCharacterPanel,
                  icon: const Icon(Icons.groups_outlined),
                  label: const Text('Personajes'),
                ),
                FloatingActionButton.extended(
                  heroTag: 'dice',
                  onPressed: _openDicePanel,
                  icon: const Icon(Icons.casino_outlined),
                  label: const Text('Tiradas'),
                ),
              ],
            ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('No se pudo cargar la Visual Alpha: $_error'),
        ),
      );
    }

    final campaign = _campaign;
    final state = _state;
    final package = _package;
    if (campaign == null || state == null || package == null) {
      return Center(
        child: FilledButton.icon(
          onPressed: _openCampaigns,
          icon: const Icon(Icons.add),
          label: const Text('Crear primera campaña'),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Mesa del GM',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Primera validación visual con datos estructurados del manual DUNGEONS & DRAGONS.pdf.',
                  ),
                ],
              ),
            ),
            if (MediaQuery.sizeOf(context).width >= 720)
              const Chip(
                avatar: Icon(Icons.cloud_off_outlined, size: 18),
                label: Text('Local-first'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        VisualAlphaWorkspace(
          campaign: campaign,
          rulesetState: state,
          rulesetPackage: package,
        ),
        const SizedBox(height: 72),
      ],
    );
  }
}
