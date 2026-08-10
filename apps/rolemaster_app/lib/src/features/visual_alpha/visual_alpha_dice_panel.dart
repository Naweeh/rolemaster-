import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rolemaster_core/rolemaster_core.dart';

Future<void> showVisualAlphaDicePanel(
  BuildContext context, {
  required RulesetPackage rulesetPackage,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => _DicePanelDialog(rulesetPackage: rulesetPackage),
  );
}

final class _DicePanelDialog extends StatefulWidget {
  const _DicePanelDialog({required this.rulesetPackage});

  final RulesetPackage rulesetPackage;

  @override
  State<_DicePanelDialog> createState() => _DicePanelDialogState();
}

final class _DicePanelDialogState extends State<_DicePanelDialog> {
  final Random _random = Random();
  final List<String> _history = <String>[];
  Map<String, int>? _abilities;
  int? _startingGold;

  int _die(int sides) => _random.nextInt(sides) + 1;

  int _roll(int count, int sides) {
    var total = 0;
    for (var index = 0; index < count; index++) {
      total += _die(sides);
    }
    return total;
  }

  void _record(String label, int result) {
    setState(() {
      _history.insert(0, '$label → $result');
      if (_history.length > 10) {
        _history.removeLast();
      }
    });
  }

  void _rollAbilitySet() {
    final abilityEntries = _objectList(widget.rulesetPackage.data['abilities']);
    final rolled = <String, int>{};
    for (final ability in abilityEntries) {
      final abbreviation = (ability['abbr'] ?? ability['name'] ?? '?').toString();
      rolled[abbreviation] = _roll(3, 6);
    }
    setState(() {
      _abilities = rolled;
      _history.insert(0, 'Atributos → ${rolled.entries.map((entry) => '${entry.key} ${entry.value}').join(', ')}');
      if (_history.length > 10) {
        _history.removeLast();
      }
    });
  }

  void _rollStartingGold() {
    final gold = _roll(3, 6) * 10;
    setState(() {
      _startingGold = gold;
      _history.insert(0, 'Oro inicial (3d6 × 10) → $gold gp');
      if (_history.length > 10) {
        _history.removeLast();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: <Widget>[
          Icon(Icons.casino_outlined),
          SizedBox(width: 8),
          Text('Tiradas · Visual Alpha'),
        ],
      ),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Primera función interactiva conectada al ruleset de prueba.',
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  FilledButton.tonal(
                    onPressed: () => _record('d20', _die(20)),
                    child: const Text('Tirar d20'),
                  ),
                  FilledButton.tonal(
                    onPressed: () => _record('d6', _die(6)),
                    child: const Text('Tirar d6'),
                  ),
                  FilledButton.tonal(
                    onPressed: () => _record('3d6', _roll(3, 6)),
                    child: const Text('Tirar 3d6'),
                  ),
                  FilledButton.icon(
                    onPressed: _rollAbilitySet,
                    icon: const Icon(Icons.person_add_alt_1_outlined),
                    label: const Text('Generar atributos'),
                  ),
                  FilledButton.icon(
                    onPressed: _rollStartingGold,
                    icon: const Icon(Icons.monetization_on_outlined),
                    label: const Text('Generar oro inicial'),
                  ),
                ],
              ),
              if (_abilities != null) ...<Widget>[
                const SizedBox(height: 20),
                Text('Atributos 3d6', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _abilities!.entries
                      .map(
                        (entry) => Chip(
                          avatar: CircleAvatar(child: Text(entry.value.toString())),
                          label: Text(entry.key),
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
              if (_startingGold != null) ...<Widget>[
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.monetization_on_outlined),
                  title: const Text('Oro inicial'),
                  subtitle: const Text('Regla de prueba: 3d6 × 10 gp'),
                  trailing: Text(
                    '$_startingGold gp',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
              const Divider(height: 28),
              Text('Historial', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (_history.isEmpty)
                const Text('Todavía no hiciste ninguna tirada.')
              else
                for (final entry in _history)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(entry),
                  ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
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
