import 'package:aura_radio/core/ai/deepseek_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeepseekRadioClient.extractDeltaContentFromChunk', () {
    test('reads choices[0].delta.content string', () {
      expect(
        DeepseekRadioClient.extractDeltaContentFromChunk(<String, dynamic>{
          'choices': <dynamic>[
            <String, dynamic>{
              'delta': <String, dynamic>{'content': '你好'},
            },
          ],
        }),
        '你好',
      );
    });

    test('returns null when content missing or empty', () {
      expect(
        DeepseekRadioClient.extractDeltaContentFromChunk(<String, dynamic>{
          'choices': <dynamic>[
            <String, dynamic>{
              'delta': <String, dynamic>{'content': ''},
            },
          ],
        }),
        isNull,
      );
      expect(
        DeepseekRadioClient.extractDeltaContentFromChunk(<String, dynamic>{
          'choices': <dynamic>[],
        }),
        isNull,
      );
      expect(
        DeepseekRadioClient.extractDeltaContentFromChunk(<String, dynamic>{}),
        isNull,
      );
    });
  });
}
