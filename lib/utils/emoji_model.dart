/// A class to store data for each individual emoji
class Emoji {
  /// The name or description for this emoji
  final String name;

  /// The unicode string for this emoji
  ///
  /// This is the string that should be displayed to view the emoji
  final String emoji;

  const Emoji({required this.name, required this.emoji});

  @override
  String toString() {
    return "Name: " + name + ", Emoji: " + emoji;
  }
}

class EmojiRecommendedModel {
  final String name;
  final String emoji;
  final int tier;
  final int numSplitEqualKeyword;
  final int numSplitPartialKeyword;

  const EmojiRecommendedModel(
      {required this.name,
        required this.emoji,
        required this.tier,
        this.numSplitEqualKeyword = 0,
        this.numSplitPartialKeyword = 0});
}
