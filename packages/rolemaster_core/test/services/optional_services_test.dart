import 'package:rolemaster_core/rolemaster_core.dart';
import 'package:test/test.dart';

void main() {
  test('disabled optional services have no network or campaign side effects',
      () async {
    const ai = DisabledAiService();
    const npc = DisabledNpcIntelligence();
    const speech = DisabledSpeechService();
    const audio = DisabledAudioDirector();

    expect(
      await ai.generate(AiRequest(
        capability: AiCapability.narration,
        prompt: 'Describe this scene',
      )),
      isNull,
    );
    expect(
      await npc.suggestReply(NpcDialogueRequest(
        campaignId: 'campaign-1',
        npcId: 'npc-1',
        playerUtterance: 'Hello',
      )),
      isNull,
    );
    expect(
      await speech.transcribe(
        audioBytes: <int>[0, 1],
        mediaType: 'audio/wav',
        language: 'es',
      ),
      isNull,
    );
    expect(
      await speech.synthesize(text: 'Hello', language: 'en'),
      isNull,
    );
    await audio.play(AudioCue(
      id: 'rain',
      kind: AudioCueKind.ambience,
      source: 'local/rain.wav',
    ));
    await audio.stop('rain');
    await audio.stopAll();
  });

  test('requests defensively copy caller-owned context', () {
    final context = <String, String>{'place': 'forest'};
    final request = AiRequest(
      capability: AiCapability.npcDialogue,
      prompt: 'Speak',
      context: context,
    );
    context['place'] = 'city';
    expect(request.context['place'], 'forest');
    expect(() => request.context['place'] = 'castle', throwsUnsupportedError);

    final dialogue = <String>['GM: hello'];
    final npc = NpcDialogueRequest(
      campaignId: 'campaign-1',
      npcId: 'npc-1',
      playerUtterance: 'Hello',
      recentDialogue: dialogue,
    );
    dialogue.add('new');
    expect(npc.recentDialogue, <String>['GM: hello']);
    expect(() => AiRequest(capability: AiCapability.narration, prompt: ' '),
        throwsArgumentError);
  });
}
