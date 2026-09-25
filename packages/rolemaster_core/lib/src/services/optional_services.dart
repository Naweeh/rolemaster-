/// Optional services stay outside campaign persistence and rule execution.
enum AiCapability { npcDialogue, summarization, narration }

final class AiRequest {
  AiRequest({
    required this.capability,
    required String prompt,
    Map<String, String> context = const <String, String>{},
  })  : prompt = prompt.trim(),
        context = Map<String, String>.unmodifiable(context) {
    if (this.prompt.isEmpty) {
      throw ArgumentError('AI prompt cannot be empty.');
    }
  }

  final AiCapability capability;
  final String prompt;
  final Map<String, String> context;
}

abstract interface class AiService {
  /// Returns null when this capability is unavailable.
  Future<String?> generate(AiRequest request);
}

final class DisabledAiService implements AiService {
  const DisabledAiService();

  @override
  Future<String?> generate(AiRequest request) async => null;
}

final class NpcDialogueRequest {
  NpcDialogueRequest({
    required String campaignId,
    required String npcId,
    required String playerUtterance,
    Iterable<String> recentDialogue = const <String>[],
  })  : campaignId = campaignId.trim(),
        npcId = npcId.trim(),
        playerUtterance = playerUtterance.trim(),
        recentDialogue = List<String>.unmodifiable(recentDialogue) {
    if (this.campaignId.isEmpty ||
        this.npcId.isEmpty ||
        this.playerUtterance.isEmpty) {
      throw ArgumentError('NPC dialogue requires campaign, NPC and utterance.');
    }
  }

  final String campaignId;
  final String npcId;
  final String playerUtterance;
  final List<String> recentDialogue;
}

abstract interface class NpcIntelligence {
  /// A suggestion for the GM; never mutates a campaign or speaks to players.
  Future<String?> suggestReply(NpcDialogueRequest request);
}

final class DisabledNpcIntelligence implements NpcIntelligence {
  const DisabledNpcIntelligence();

  @override
  Future<String?> suggestReply(NpcDialogueRequest request) async => null;
}

abstract interface class SpeechToTextService {
  /// Audio format is declared by the caller, for example audio/wav.
  Future<String?> transcribe({
    required List<int> audioBytes,
    required String mediaType,
    required String language,
  });
}

abstract interface class TextToSpeechService {
  /// Produces audio bytes only when a provider is configured.
  Future<List<int>?> synthesize({
    required String text,
    required String language,
    String? voiceId,
  });
}

final class DisabledSpeechService
    implements SpeechToTextService, TextToSpeechService {
  const DisabledSpeechService();

  @override
  Future<String?> transcribe({
    required List<int> audioBytes,
    required String mediaType,
    required String language,
  }) async =>
      null;

  @override
  Future<List<int>?> synthesize({
    required String text,
    required String language,
    String? voiceId,
  }) async =>
      null;
}

enum AudioCueKind { music, ambience, soundEffect, npcVoice }

final class AudioCue {
  AudioCue({
    required String id,
    required this.kind,
    required String source,
  })  : id = id.trim(),
        source = source.trim() {
    if (this.id.isEmpty || this.source.isEmpty) {
      throw ArgumentError('Audio cue requires an ID and source.');
    }
  }

  final String id;
  final AudioCueKind kind;
  final String source;
}

abstract interface class AudioDirector {
  /// Queues a cue for a GM-controlled output device.
  Future<void> play(AudioCue cue);

  Future<void> stop(String cueId);

  Future<void> stopAll();
}

final class DisabledAudioDirector implements AudioDirector {
  const DisabledAudioDirector();

  @override
  Future<void> play(AudioCue cue) async {}

  @override
  Future<void> stop(String cueId) async {}

  @override
  Future<void> stopAll() async {}
}
