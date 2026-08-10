import 'package:flutter/material.dart';
import 'package:rolemaster_core/rolemaster_core.dart';

import 'src/app/rolemaster_app.dart';
import 'src/infrastructure/in_memory_campaign_repository.dart';

void main() {
  final CampaignRepository campaignRepository = InMemoryCampaignRepository();

  runApp(
    RolemasterApp(
      campaignRepository: campaignRepository,
    ),
  );
}
