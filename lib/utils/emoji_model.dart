/// A class to store data for each individual emoji
class Emoji {
  /// The name or description for this emoji
  String? name;

  /// The unicode string for this emoji
  ///
  /// This is the string that should be displayed to view the emoji
  String? emoji;

  Emoji({required this.name, required this.emoji});

  @override
  String toString() {
    return "Name: " + name! + ", Emoji: " + emoji!;
  }

  Emoji.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    emoji = json['emoji'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['emoji'] = this.emoji;
    return data;
  }
}

class EmojiListModel {
  List<Emoji>? emojiList;

  EmojiListModel({required this.emojiList});

  EmojiListModel.fromJson(Map<String, dynamic> json) {
    if (json['emoji'] != null) {
      emojiList = [];
      json['emoji'].forEach((v) {
        emojiList!.add(new Emoji.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.emojiList != null) {
      data['emoji'] = this.emojiList!.map((v) => v.toJson()).toList();
    }
    return data;
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
