import 'package:flutter/material.dart';
import 'package:rolemaster_core/rolemaster_core.dart';

final class CampaignHomePage extends StatefulWidget {
  const CampaignHomePage({
    required this.campaignRepository,
    super.key,
  });

  final CampaignRepository campaignRepository;

  @override
  State<CampaignHomePage> createState() => _CampaignHomePageState();
}

final class _CampaignHomePageState extends State<CampaignHomePage> {
  final TextEditingController _nameController = TextEditingController();
  late final CreateCampaign _createCampaign;

  List<Campaign> _campaigns = const <Campaign>[];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _createCampaign = CreateCampaign(
      repository: widget.campaignRepository,
      idGenerator: () => DateTime.now().microsecondsSinceEpoch.toString(),
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
    if (!mounted) return;
    setState(() {
      _campaigns = campaigns;
      _isLoading = false;
    });
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    await _createCampaign(name);
    _nameController.clear();
    await _reload();
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
          final isWide = constraints.maxWidth >= 900;
          final list = _CampaignList(
            campaigns: _campaigns,
            isLoading: _isLoading,
          );
          final creator = _CampaignCreator(
            controller: _nameController,
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
                  SizedBox(width: 360, child: creator),
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
    required this.onCreate,
  });

  final TextEditingController controller;
  final Future<void> Function() onCreate;

  @override
  Widget build(BuildContext context) {
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
              'Primer vertical slice del Core. La persistencia SQLite se agrega en el siguiente paso.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Nombre de la campaña',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => onCreate(),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Crear campaña'),
            ),
          ],
        ),
      ),
    );
  }
}

final class _CampaignList extends StatelessWidget {
  const _CampaignList({
    required this.campaigns,
    required this.isLoading,
  });

  final List<Campaign> campaigns;
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
                  'Todavía no hay campañas. Creá la primera para validar el flujo base.',
                  textAlign: TextAlign.center,
                ),
              )
            else
              for (final campaign in campaigns)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.auto_stories_outlined),
                  title: Text(campaign.name),
                  subtitle: Text('ID ${campaign.id}'),
                ),
          ],
        ),
      ),
    );
  }
}
