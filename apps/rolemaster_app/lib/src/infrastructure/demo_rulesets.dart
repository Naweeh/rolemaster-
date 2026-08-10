import 'package:rolemaster_core/rolemaster_core.dart';

List<RulesetPackage> buildDemoRulesets() {
  return <RulesetPackage>[
    _demoPackage(version: '0.1.0', includeMagic: false),
    _demoPackage(version: '0.2.0', includeMagic: true),
  ];
}

RulesetPackage _demoPackage({
  required String version,
  required bool includeMagic,
}) {
  return RulesetPackage(
    manifest: RulesetManifest(
      id: 'rolemaster-demo',
      systemId: 'rolemaster',
      edition: 'Demo técnico',
      version: version,
      displayName: 'Rolemaster · Demo técnico',
      modules: <RulesetModuleDefinition>[
        RulesetModuleDefinition(
          id: 'core-demo',
          name: 'Núcleo de demostración',
          required: true,
        ),
        RulesetModuleDefinition(
          id: 'combat-demo',
          name: 'Combate de demostración',
          enabledByDefault: true,
        ),
        if (includeMagic)
          RulesetModuleDefinition(
            id: 'magic-demo',
            name: 'Magia de demostración',
          ),
      ],
      sourceReferences: const <String>[
        'Paquete técnico; no contiene datos de manuales reales.',
      ],
    ),
    data: <String, Object?>{
      'technicalDemo': true,
      'version': version,
    },
  );
}
