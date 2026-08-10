import 'package:flutter/material.dart';
import 'package:rolemaster_core/rolemaster_core.dart';

final class CampaignHomePage extends StatefulWidget {
  const CampaignHomePage({
    required this.campaignRepository,
    required this.rulesetRepository,
    required this.campaignRulesetRepository,
    super.key,
  });

  final CampaignRepository campaignRepository;
  final RulesetRepository rulesetRepository;
  final CampaignRulesetRepository campaignRulesetRepository;

  @override
  State<CampaignHomePage> createState() => _CampaignHomePageState();
}

final class _CampaignHomePageState extends State<CampaignHomePage> {
  final TextEditingController _nameController = TextEditingController();
  late final CreateCampaign _createCampaign;
  late final InitializeCampaignRuleset _initializeCampaignRuleset;

  List<Campaign> _campaigns = const <Campaign>[];
  List<RulesetPackage> _rulesets = const <RulesetPackage>[];
  Map<String, CampaignRulesetState?> _campaignRulesets =
      const <String, CampaignRulesetState?>{};
  RulesetPackage? _selectedRuleset;
  Set<String> _selectedModuleIds = <String>{};
  String? _errorMessage;
  bool _isLoading = true;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _createCampaign = CreateCampaign(
      repository: widget.campaignRepository,
      idGenerator: () => DateTime.now().microsecondsSinceEpoch.toString(),
      clock: DateTime.now,
    );
    _initializeCampaignRuleset = InitializeCampaignRuleset(
      campaignRepository: widget.campaignRepository,
      rulesetRepository: widget.rulesetRepository,
      campaignRulesetRepository: widget.campaignRulesetRepository,
      clock: DateTime.now,
    );
    _reload();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final campaigns = await widget.campaignRepository.getAll();
    final rulesets = await widget.rulesetRepository.getAvailablePackages();
    final states = <String, CampaignRulesetState?>{};
    for (final campaign in campaigns) {
      states[campaign.id] =
          await widget.campaignRulesetRepository.getForCampaign(campaign.id);
    }

    if (!mounted) return;
    final selected = _resolveSelection(rulesets);
    setState(() {
      _campaigns = campaigns;
      _rulesets = rulesets;
      _campaignRulesets = states;
      _selectedRuleset = selected;
      if (selected != null && _selectedModuleIds.isEmpty) {
        _selectedModuleIds = selected.manifest.defaultModuleIds.toSet();
      }
      _isLoading = false;
    });
  }

  RulesetPackage? _resolveSelection(List<RulesetPackage> rulesets) {
    final current = _selectedRuleset;
    if (current != null) {
      for (final package in rulesets) {
        if (package.manifest.id == current.manifest.id &&
            package.manifest.version == current.manifest.version) {
          return package;
        }
      }
    }
    return rulesets.isEmpty ? null : rulesets.last;
  }

  void _selectRuleset(RulesetPackage? package) {
    setState(() {
      _selectedRuleset = package;
      _selectedModuleIds =
          package?.manifest.defaultModuleIds.toSet() ?? <String>{};
      _errorMessage = null;
    });
  }

  void _setModule(RulesetModuleDefinition module, bool selected) {
    if (module.required) return;
    setState(() {
      if (selected) {
        _selectedModuleIds.add(module.id);
      } else {
        _selectedModuleIds.remove(module.id);
      }
    });
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    final package = _selectedRuleset;
    if (name.isEmpty || package == null || _isCreating) return;

    setState(() {
      _isCreating = true;
      _errorMessage = null;
    });

    try {
      final campaign = await _createCampaign(name);
      await _initializeCampaignRuleset(
        campaignId: campaign.id,
        rulesetId: package.manifest.id,
        rulesetVersion: package.manifest.version,
        activeModuleIds: _selectedModuleIds,
      );
      _nameController.clear();
      await _reload();
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rolemaster'),
        actions: const <Widget>[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Center(child: Text('Mesa presencial · GM')),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 960;
          final list = _CampaignList(
            campaigns: _campaigns,
            campaignRulesets: _campaignRulesets,
            isLoading: _isLoading,
          );
          final creator = _CampaignCreator(
            controller: _nameController,
            rulesets: _rulesets,
            selectedRuleset: _selectedRuleset,
            selectedModuleIds: _selectedModuleIds,
            isCreating: _isCreating,
            errorMessage: _errorMessage,
            onRulesetChanged: _selectRuleset,
            onModuleChanged: _setModule,
            onCreate: _create,
          );

          if (isWide) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(flex: 2, child: list),
                  const SizedBox(width: 24),
                  SizedBox(width: 420, child: creator),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              creator,
              const SizedBox(height: 24),
              list,
            ],
          );
        },
      ),
    );
  }
}

final class _CampaignCreator extends StatelessWidget {
  const _CampaignCreator({
    required this.controller,
    required this.rulesets,
    required this.selectedRuleset,
    required this.selectedModuleIds,
    required this.isCreating,
    required this.errorMessage,
    required this.onRulesetChanged,
    required this.onModuleChanged,
    required this.onCreate,
  });

  final TextEditingController controller;
  final List<RulesetPackage> rulesets;
  final RulesetPackage? selectedRuleset;
  final Set<String> selectedModuleIds;
  final bool isCreating;
  final String? errorMessage;
  final ValueChanged<RulesetPackage?> onRulesetChanged;
  final void Function(RulesetModuleDefinition module, bool selected)
      onModuleChanged;
  final Future<void> Function() onCreate;

  @override
  Widget build(BuildContext context) {
    final manifest = selectedRuleset?.manifest;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Nueva campaña',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'UI técnica provisional conectada al Core. Cada campaña empieza con un ruleset limpio.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nombre de la campaña',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (rulesets.isEmpty)
              const _RulesetEmptyState()
            else ...<Widget>[
              DropdownButtonFormField<RulesetPackage>(
                key: ValueKey<String?>(
                  manifest == null
                      ? null
                      : '${manifest.id}@${manifest.version}',
                ),
                initialValue: selectedRuleset,
                decoration: const InputDecoration(
                  labelText: 'Set / edición / versión',
                  border: OutlineInputBorder(),
                ),
                items: rulesets
                    .map(
                      (package) => DropdownMenuItem<RulesetPackage>(
                        value: package,
                        child: Text(
                          '${package.manifest.displayName} · ${package.manifest.edition} · v${package.manifest.version}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: isCreating ? null : onRulesetChanged,
              ),
              const SizedBox(height: 12),
              const _CleanRulesetBanner(),
              if (manifest != null && manifest.modules.isNotEmpty) ...<Widget>[
                const SizedBox(height: 16),
                Text(
                  'Módulos',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                for (final module in manifest.modules)
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: module.required || selectedModuleIds.contains(module.id),
                    onChanged: module.required || isCreating
                        ? null
                        : (value) => onModuleChanged(module, value ?? false),
                    title: Text(module.name),
                    subtitle: module.required
                        ? const Text('Obligatorio')
                        : module.enabledByDefault
                            ? const Text('Activo por defecto')
                            : null,
                  ),
              ],
            ],
            if (errorMessage != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: selectedRuleset == null || isCreating ? null : onCreate,
              icon: isCreating
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: Text(isCreating ? 'Creando…' : 'Crear campaña'),
            ),
          ],
        ),
      ),
    );
  }
}

final class _CleanRulesetBanner extends StatelessWidget {
  const _CleanRulesetBanner();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(Icons.restart_alt),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Ruleset limpio: no hereda house rules ni cambios de otras campañas.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _RulesetEmptyState extends StatelessWidget {
  const _RulesetEmptyState();

  @override
  Widget build(BuildContext context) {
    return const ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.menu_book_outlined),
      title: Text('No hay rulesets cargados'),
      subtitle: Text(
        'Más adelante el importador de manuales publicará aquí versiones inmutables.',
      ),
    );
  }
}

final class _CampaignList extends StatelessWidget {
  const _CampaignList({
    required this.campaigns,
    required this.campaignRulesets,
    required this.isLoading,
  });

  final List<Campaign> campaigns;
  final Map<String, CampaignRulesetState?> campaignRulesets;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Campañas',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (campaigns.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  'Todavía no hay campañas. Creá la primera y elegí su ruleset.',
                  textAlign: TextAlign.center,
                ),
              )
            else
              for (final campaign in campaigns)
                _CampaignTile(
                  campaign: campaign,
                  rulesetState: campaignRulesets[campaign.id],
                ),
          ],
        ),
      ),
    );
  }
}

final class _CampaignTile extends StatelessWidget {
  const _CampaignTile({required this.campaign, required this.rulesetState});

  final Campaign campaign;
  final CampaignRulesetState? rulesetState;

  @override
  Widget build(BuildContext context) {
    final binding = rulesetState?.binding;
    final overlay = rulesetState?.overlay;
    final subtitle = binding == null
        ? 'Sin ruleset asignado'
        : '${binding.rulesetId} · v${binding.rulesetVersion} · '
            '${binding.activeModuleIds.length} módulos · '
            '${overlay?.isClean ?? true ? 'Limpio' : 'Modificado'}';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.auto_stories_outlined),
      title: Text(campaign.name),
      subtitle: Text(subtitle),
      trailing: overlay?.isClean ?? true
          ? const Chip(label: Text('Base'))
          : const Chip(label: Text('House rules')),
    );
  }
}
