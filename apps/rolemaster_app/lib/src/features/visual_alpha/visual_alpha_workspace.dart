import 'package:flutter/material.dart';
import 'package:rolemaster_core/rolemaster_core.dart';

final class VisualAlphaWorkspace extends StatelessWidget {
  const VisualAlphaWorkspace({
    required this.campaign,
    required this.rulesetState,
    required this.rulesetPackage,
    super.key,
  });

  final Campaign campaign;
  final CampaignRulesetState rulesetState;
  final RulesetPackage rulesetPackage;

  @override
  Widget build(BuildContext context) {
    final manifest = rulesetPackage.manifest;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Text(
                  campaign.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Chip(
                  avatar: Icon(Icons.science_outlined, size: 18),
                  label: Text('Visual Alpha 0.1'),
                ),
                Chip(label: Text(manifest.edition)),
                Chip(label: Text('v${manifest.version}')),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${manifest.displayName} · ${rulesetState.binding.activeModuleIds.length} módulos activos · '
              '${rulesetState.overlay.isClean ? 'Ruleset limpio' : 'House rules'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            const _SectionNavigation(),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 820;
                final scene = const _ScenePreview();
                final inspector = _RulesetInspector(package: rulesetPackage);

                if (!isWide) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      scene,
                      const SizedBox(height: 16),
                      inspector,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Expanded(child: _ScenePreview()),
                    const SizedBox(width: 16),
                    SizedBox(width: 340, child: inspector),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            const _BottomActions(),
          ],
        ),
      ),
    );
  }
}

final class _SectionNavigation extends StatelessWidget {
  const _SectionNavigation();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: const <Widget>[
        _NavChip(icon: Icons.groups_outlined, label: 'Personajes'),
        _NavChip(icon: Icons.record_voice_over_outlined, label: 'NPCs'),
        _NavChip(icon: Icons.pets_outlined, label: 'Criaturas'),
        _NavChip(icon: Icons.backpack_outlined, label: 'Inventario'),
        _NavChip(icon: Icons.place_outlined, label: 'Lugares'),
        _NavChip(icon: Icons.map_outlined, label: 'Mapas'),
      ],
    );
  }
}

final class _NavChip extends StatelessWidget {
  const _NavChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    );
  }
}

final class _ScenePreview extends StatelessWidget {
  const _ScenePreview();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      height: 470,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
        color: colors.surfaceContainerLow,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          CustomPaint(painter: _SceneGridPainter(colors.outlineVariant)),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.map_outlined,
                      size: 54,
                      color: colors.primary,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Mapa / Escena',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'El Core de Maps ya guarda coordenadas, capas GM/públicas y posiciones de entidades. '
                      'En esta alpha todavía no cargamos una imagen de mapa.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Positioned(
            left: 14,
            top: 14,
            child: _SceneBadge(icon: Icons.visibility_off_outlined, label: 'GM'),
          ),
          const Positioned(
            right: 14,
            top: 14,
            child: _SceneBadge(icon: Icons.layers_outlined, label: 'Capas: 0'),
          ),
          const Positioned(
            left: 14,
            bottom: 14,
            child: _SceneBadge(icon: Icons.place_outlined, label: 'Sin localización'),
          ),
        ],
      ),
    );
  }
}

final class _SceneBadge extends StatelessWidget {
  const _SceneBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 16),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
      ),
    );
  }
}

final class _RulesetInspector extends StatelessWidget {
  const _RulesetInspector({required this.package});

  final RulesetPackage package;

  @override
  Widget build(BuildContext context) {
    final abilities = _objectList(package.data['abilities']);
    final classes = _objectList(package.data['classes']);
    final alignments = _stringList(package.data['alignments']);
    final creation = _objectMap(package.data['characterCreation']);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surfaceContainer,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.menu_book_outlined),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Datos del manual',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Subconjunto estructurado para validar que el Ruleset cambia la campaña.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Text('Atributos', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: abilities
                .map(
                  (ability) => Chip(
                    label: Text(
                      (ability['abbr'] ?? ability['name'] ?? '?').toString(),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 14),
          Text('Clases', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          for (final characterClass in classes)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: <Widget>[
                  Expanded(child: Text(characterClass['name'].toString())),
                  Text(
                    '${_joinValues(characterClass['primeRequisites'])} · ${characterClass['hitDie']}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          const Divider(height: 24),
          Text('Alineamiento', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          Text(alignments.join(' · ')),
          const SizedBox(height: 14),
          Text(
            'Inicio',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 6),
          Text('Oro: ${creation['startingGold'] ?? '-'}'),
          Text('CA sin armadura: ${creation['unarmoredArmorClass'] ?? '-'}'),
          const Divider(height: 24),
          Row(
            children: <Widget>[
              Icon(
                Icons.verified_outlined,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text('Ruleset limpio · sin cambios heredados'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class _BottomActions extends StatelessWidget {
  const _BottomActions();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: const <Widget>[
        _FutureAction(icon: Icons.event_note_outlined, label: 'Eventos'),
        _FutureAction(icon: Icons.casino_outlined, label: 'Tiradas'),
        _FutureAction(icon: Icons.volume_up_outlined, label: 'Audio'),
        _FutureAction(icon: Icons.settings_outlined, label: 'Sistema'),
      ],
    );
  }
}

final class _FutureAction extends StatelessWidget {
  const _FutureAction({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 18),
          const SizedBox(width: 7),
          Text(label),
        ],
      ),
    );
  }
}

final class _SceneGridPainter extends CustomPainter {
  const _SceneGridPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.28)
      ..strokeWidth = 1;
    const spacing = 32.0;
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SceneGridPainter oldDelegate) {
    return oldDelegate.color != color;
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

Map<String, Object?> _objectMap(Object? value) {
  if (value is! Map) return const <String, Object?>{};
  return value.map<String, Object?>(
    (key, item) => MapEntry(key.toString(), item),
  );
}

List<String> _stringList(Object? value) {
  if (value is! List) return const <String>[];
  return value.map((item) => item.toString()).toList(growable: false);
}

String _joinValues(Object? value) {
  if (value is! List) return '-';
  return value.map((item) => item.toString()).join('/');
}
