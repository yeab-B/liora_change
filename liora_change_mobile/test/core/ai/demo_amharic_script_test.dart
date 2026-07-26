import 'package:flutter_test/flutter_test.dart';
import 'package:liora_change_mobile/core/ai/demo_amharic_script.dart';

void main() {
  test('greeting matches hello / selam', () {
    expect(DemoAmharicScript.match('ሰላም'), DemoAmharicScript.greeting);
    expect(DemoAmharicScript.match('hello'), DemoAmharicScript.greeting);
  });

  test('what-is-app matches Amharic and English', () {
    expect(
      DemoAmharicScript.match('ይህ መተግበሪያ ምንድን ነው?'),
      DemoAmharicScript.whatIsApp,
    );
    expect(
      DemoAmharicScript.match('What is this app?'),
      DemoAmharicScript.whatIsApp,
    );
  });

  test('reading-demo matches challenge walkthrough cues', () {
    expect(
      DemoAmharicScript.match('የማንበብ ልማድ እንዴት እንገነባለን?'),
      DemoAmharicScript.readingDemo,
    );
    expect(
      DemoAmharicScript.match('How do we start the reading challenge?'),
      DemoAmharicScript.readingDemo,
    );
  });
}
