import 'dart:io';

import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:rolemaster_storage_sqlite/rolemaster_storage_sqlite.dart';
import 'package:test/test.dart';

void main() {
  group('SqliteCampaignRepository', () {
    test('saves and loads a campaign preserving its lifecycle fields', () async {
      final repository = SqliteCampaignRepository.inMemory();
      addTearDown(repository.close);

      final campaign = Campaign(
        id: 'campaign-1',
        name: 'La Corona Perdida',
        createdAt: DateTime.utc(2026, 8, 10, 10),
        updatedAt: DateTime.utc(2026, 8, 10, 11),
      ).archive(at: DateTime.utc(2026, 8, 10, 12));

      await repository.save(campaign);
      final loaded = await repository.getById(campaign.id);

      expect(loaded, isNotNull);
      expect(loaded!.id, campaign.id);
      expect(loaded.name, campaign.name);
      expect(loaded.createdAt, campaign.createdAt);
      expect(loaded.updatedAt, campaign.updatedAt);
      expect(loaded.archivedAt, campaign.archivedAt);
    });

    test('hides archived campaigns unless explicitly requested', () async {
      final repository = SqliteCampaignRepository.inMemory();
      addTearDown(repository.close);

      final active = Campaign(
        id: 'active',
        name: 'Activa',
        createdAt: DateTime.utc(2026, 8, 10, 10),
      );
      final archived = Campaign(
        id: 'archived',
        name: 'Archivada',
        createdAt: DateTime.utc(2026, 8, 10, 10),
      ).archive(at: DateTime.utc(2026, 8, 10, 12));

      await repository.save(active);
      await repository.save(archived);

      final visible = await repository.getAll();
      final all = await repository.getAll(includeArchived: true);

      expect(visible.map((campaign) => campaign.id), <String>['active']);
      expect(
        all.map((campaign) => campaign.id),
        containsAll(<String>['active', 'archived']),
      );
    });

    test('upserts campaign updates by id', () async {
      final repository = SqliteCampaignRepository.inMemory();
      addTearDown(repository.close);

      final campaign = Campaign(
        id: 'campaign-1',
        name: 'Original',
        createdAt: DateTime.utc(2026, 8, 10, 10),
      );
      final renamed = campaign.rename(
        name: 'Renombrada',
        at: DateTime.utc(2026, 8, 10, 11),
      );

      await repository.save(campaign);
      await repository.save(renamed);

      final loaded = await repository.getById(campaign.id);
      expect(loaded?.name, 'Renombrada');
      expect((await repository.getAll(includeArchived: true)), hasLength(1));
    });

    test('persists a campaign after closing and reopening the database', () async {
      final directory = await Directory.systemTemp.createTemp('rolemaster_sqlite_');
      final databasePath =
          '${directory.path}${Platform.pathSeparator}campaign.db';
      addTearDown(() => directory.delete(recursive: true));

      final campaign = Campaign(
        id: 'campaign-1',
        name: 'Persistente',
        createdAt: DateTime.utc(2026, 8, 10, 10),
      );

      final writer = SqliteCampaignRepository.open(databasePath);
      await writer.save(campaign);
      writer.close();

      final reader = SqliteCampaignRepository.open(databasePath);
      final loaded = await reader.getById(campaign.id);
      reader.close();

      expect(loaded, isNotNull);
      expect(loaded!.id, campaign.id);
      expect(loaded.name, campaign.name);
      expect(loaded.createdAt, campaign.createdAt);
    });
  });
}
