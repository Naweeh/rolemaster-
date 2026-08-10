import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rolemaster_core/rolemaster_core.dart';

import 'visual_alpha_character_profile.dart';

Future<void> showVisualAlphaCharacterPanel(
  BuildContext context, {
  required Campaign campaign,
  required RulesetPackage rulesetPackage,
  required CampaignRepository campaignRepository,
  required CharacterRepository characterRepository,
  required VisualAlphaCharacterProfileRepository profileRepository,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => FractionallySizedBox(
      heightFactor: 0.92,
      child: _CharacterPanel(
        campaign: campaign,
        rulesetPackage: rulesetPackage,
        campaignRepository: campaignRepository,
        characterRepository: characterRepository,
        profileRepository: profileRepository,
      ),
    ),
  );
}

final class _CharacterPanel extends StatefulWidget {
  const _CharacterPanel({
    required this.campaign,
    required this.rulesetPackage,
    required this.campaignRepository,
    required this.characterRepository,
    required this.profileRepository,
  });

  final Campaign campaign;
  final RulesetPackage rulesetPackage;
  final CampaignRepository campaignRepository;
  final CharacterRepository characterRepository;
  final VisualAlphaCharacterProfileRepository profileRepository;

  @override
  State<_CharacterPanel> createState() => _CharacterPanelState();
}

final class _CharacterPanelState extends State<_CharacterPanel> {
  final _random = Random();
  final _nameController = TextEditingController();
  final Map<String, int> _abilities = <String, int>{};

  List<Character> _characters = const <Character>[];
  final Map<String, VisualAlphaCharacterProfile?> _profiles =
      <String, VisualAlphaCharacterProfile?>{};
  String? _selectedClass;
  String? _selectedAlignment;
  int? _startingGold;
  bool _creating = false;
  bool _saving = false;
  Object? _error;

  List<Map<String, Object?>> get _abilityDefinitions =>
      _objectList(widget.rulesetPackage.data['abilities']);

  List<Map<String, Object?>> get _classDefinitions =>
      _objectList(widget.rulesetPackage.data['classes']);

  List<String> get _alignments =>
      _stringList(widget.rulesetPackage.data['alignments']);

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    try {
      final characters =
          await widget.characterRepository.getForCampaign(widget.campaign.id);
      final profiles = <String, VisualAlphaCharacterProfile?>{};
      for (final character in characters) {
        profiles[character.id] =
            await widget.profileRepository.getForCharacter(character.id);
      }
      if (!mounted) return;
      setState(() {
        _characters = characters;
        _profiles
          ..clear()
          ..addAll(profiles);
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    }
  }

  int _rollDie(int sides) => _random.nextInt(sides) + 1;

  int _roll3d6() => _rollDie(6) + _rollDie(6) + _rollDie(6);

  void _rollAbilities() {
    setState(() {
      _abilities.clear();
      for (final definition in _abilityDefinitions) {
        final key = (definition['abbr'] ?? definition['name'] ?? '?').toString();
        _abilities[key] = _roll3d6();
      }
    });
  }

  void _rollGold() {
    setState(() => _startingGold = _roll3d6() * 10);
  }

  void _startCreating() {
    setState(() {
      _creating = true;
      _selectedClass = _classDefinitions.isEmpty
          ? null
          : _classDefinitions.first['name']?.toString();
      _selectedAlignment = _alignments.isEmpty ? null : _alignments.first;
      _startingGold = null;
      _abilities.clear();
      _error = null;
    });
  }

  void _cancelCreating() {
    setState(() {
      _creating = false;
      _nameController.clear();
      _abilities.clear();
      _startingGold = null;
      _error = null;
    });
  }

  Future<void> _saveCharacter() async {
    final name = _nameController.text.trim();
    final className = _selectedClass;
    final alignment = _selectedAlignment;
    final gold = _startingGold;
    if (name.isEmpty ||
        className == null ||
        alignment == null ||
        gold == null ||
        _abilities.length != _abilityDefinitions.length ||
        _saving) {
      setState(() {
        _error = StateError(
          'Completá nombre, atributos, clase, alineamiento y oro inicial.',
        );
      });
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final createCharacter = CreateCharacter(
        repository: widget.characterRepository,
        campaignRepository: widget.campaignRepository,
        idGenerator: () =>
            'pc-${DateTime.now().microsecondsSinceEpoch.toString()}',
        clock: DateTime.now,
      );
      final character = await createCharacter(
        campaignId: widget.campaign.id,
        name: name,
        metadata: CharacterMetadata(
          description: 'Personaje creado en Visual Alpha 0.1.',
          tags: <String>[className, alignment],
        ),
      );
      await widget.profileRepository.save(
        VisualAlphaCharacterProfile(
          characterId: character.id,
          rulesetId: widget.rulesetPackage.manifest.id,
          rulesetVersion: widget.rulesetPackage.manifest.version,
          className: className,
          alignment: alignment,
          abilities: _abilities,
          startingGold: gold,
        ),
      );
      _nameController.clear();
      if (!mounted) return;
      setState(() {
        _creating = false;
        _abilities.clear();
        _startingGold = null;
      });
      await _reload();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.groups_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Personajes · ${widget.campaign.name}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (!_creating)
                  FilledButton.icon(
                    onPressed: _startCreating,
                    icon: const Icon(Icons.person_add_alt_1_outlined),
                    label: const Text('Nuevo'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Prueba funcional: creación y reapertura dentro de la sesión actual.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 10),
              Text(
                _error.toString(),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 14),
            Expanded(
              child: _creating ? _buildCreationForm() : _buildCharacterList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterList() {
    if (_characters.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.person_outline, size: 48),
            const SizedBox(height: 12),
            const Text('Todavía no hay personajes en esta campaña.'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _startCreating,
              icon: const Icon(Icons.add),
              label: const Text('Crear primer personaje'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _characters.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final character = _characters[index];
        final profile = _profiles[character.id];
        return ExpansionTile(
          leading: const CircleAvatar(child: Icon(Icons.person_outline)),
          title: Text(character.name),
          subtitle: profile == null
              ? const Text('Sin perfil de ruleset')
              : Text('${profile.className} · ${profile.alignment}'),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: <Widget>[
            if (profile != null) ...<Widget>[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: profile.abilities.entries
                    .map(
                      (entry) => Chip(
                        label: Text('${entry.key} ${entry.value}'),
                      ),
                    )
                    .toList(growable: false),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Oro inicial: ${profile.startingGold} gp'),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Ruleset: ${profile.rulesetId} · v${profile.rulesetVersion}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildCreationForm() {
    return ListView(
      children: <Widget>[
        TextField(
          controller: _nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nombre del personaje',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Atributos · 3d6',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            OutlinedButton.icon(
              onPressed: _rollAbilities,
              icon: const Icon(Icons.casino_outlined),
              label: Text(_abilities.isEmpty ? 'Tirar' : 'Repetir'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _abilityDefinitions.map((definition) {
            final key =
                (definition['abbr'] ?? definition['name'] ?? '?').toString();
            return Chip(label: Text('$key ${_abilities[key] ?? '—'}'));
          }).toList(growable: false),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _selectedClass,
          decoration: const InputDecoration(
            labelText: 'Clase',
            border: OutlineInputBorder(),
          ),
          items: _classDefinitions
              .map(
                (definition) => DropdownMenuItem<String>(
                  value: definition['name'].toString(),
                  child: Text(definition['name'].toString()),
                ),
              )
              .toList(growable: false),
          onChanged: (value) => setState(() => _selectedClass = value),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: _selectedAlignment,
          decoration: const InputDecoration(
            labelText: 'Alineamiento',
            border: OutlineInputBorder(),
          ),
          items: _alignments
              .map(
                (alignment) => DropdownMenuItem<String>(
                  value: alignment,
                  child: Text(alignment),
                ),
              )
              .toList(growable: false),
          onChanged: (value) => setState(() => _selectedAlignment = value),
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                _startingGold == null
                    ? 'Oro inicial: pendiente'
                    : 'Oro inicial: $_startingGold gp',
              ),
            ),
            OutlinedButton.icon(
              onPressed: _rollGold,
              icon: const Icon(Icons.casino_outlined),
              label: const Text('3d6 × 10'),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Row(
          children: <Widget>[
            TextButton(onPressed: _saving ? null : _cancelCreating, child: const Text('Cancelar')),
            const Spacer(),
            FilledButton.icon(
              onPressed: _saving ? null : _saveCharacter,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Guardando…' : 'Guardar personaje'),
            ),
          ],
        ),
      ],
    );
  }
}

List<Map<String, Object?>> _objectList(Object? value) {
  if (value is! List) return const <Map<String, Object?>>[];
  return value
      .whereType<Map>()
      .map(
        (entry) => entry.map<String, Object?>(
          (key, item) => MapEntry(key.toString(), item),
        ),
      )
      .toList(growable: false);
}

List<String> _stringList(Object? value) {
  if (value is! List) return const <String>[];
  return value.map((item) => item.toString()).toList(growable: false);
}
