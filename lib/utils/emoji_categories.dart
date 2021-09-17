import 'package:flutter/material.dart';

enum EmojiCategory {
  RECOMMENDED,
  RECENT,
  SMILEYS,
  ANIMALS,
  FOODS,
  TRAVEL,
  ACTIVITIES,
  OBJECTS,
  SYMBOLS,
  FLAGS
}

/// Class that defines the icon representing a [EmojiCategory]
class CategoryIcon {
  /// The icon to represent the category
  final IconData icon;

  /// The default color of the icon
  final Color? color;

  /// The color of the icon once the category is selected
  final Color? selectedColor;

  const CategoryIcon({
    required this.icon,
    this.color,
    this.selectedColor,
  });
}

/// Class used to define all the [CategoryIcon] shown for each [EmojiCategory]
///
/// This allows the keyboard to be personalized by changing icons shown.
/// If a [CategoryIcon] is set as null or not defined during initialization, the default icons will be used instead
class CategoryIcons {
  /// Icon for [EmojiCategory.RECOMMENDED]
  final CategoryIcon recommendationIcon;

  /// Icon for [EmojiCategory.RECENT]
  final CategoryIcon recentIcon;

  /// Icon for [EmojiCategory.SMILEYS]
  final CategoryIcon smileyIcon;

  /// Icon for [EmojiCategory.ANIMALS]
  final CategoryIcon animalIcon;

  /// Icon for [EmojiCategory.FOODS]
  final CategoryIcon foodIcon;

  /// Icon for [EmojiCategory.TRAVEL]
  final CategoryIcon travelIcon;

  /// Icon for [EmojiCategory.ACTIVITIES]
  final CategoryIcon activityIcon;

  /// Icon for [EmojiCategory.OBJECTS]
  final CategoryIcon objectIcon;

  /// Icon for [EmojiCategory.SYMBOLS]
  final CategoryIcon symbolIcon;

  /// Icon for [EmojiCategory.FLAGS]
  final CategoryIcon flagIcon;

  CategoryIcon fromCategory(EmojiCategory category) {
    switch (category) {
      case EmojiCategory.RECOMMENDED:
        return recommendationIcon;
      case EmojiCategory.RECENT:
        return recentIcon;
      case EmojiCategory.SMILEYS:
        return smileyIcon;
      case EmojiCategory.ANIMALS:
        return animalIcon;
      case EmojiCategory.FOODS:
        return foodIcon;
      case EmojiCategory.TRAVEL:
        return travelIcon;
      case EmojiCategory.ACTIVITIES:
        return activityIcon;
      case EmojiCategory.OBJECTS:
        return objectIcon;
      case EmojiCategory.SYMBOLS:
        return symbolIcon;
      case EmojiCategory.FLAGS:
        return flagIcon;
    }
  }

  const CategoryIcons({
    this.recommendationIcon = const CategoryIcon(icon: Icons.search),
    this.recentIcon = const CategoryIcon(icon: Icons.access_time),
    this.smileyIcon = const CategoryIcon(icon: Icons.tag_faces),
    this.animalIcon = const CategoryIcon(icon: Icons.pets),
    this.foodIcon = const CategoryIcon(icon: Icons.fastfood),
    this.travelIcon = const CategoryIcon(icon: Icons.location_city),
    this.activityIcon = const CategoryIcon(icon: Icons.directions_run),
    this.objectIcon = const CategoryIcon(icon: Icons.lightbulb_outline),
    this.symbolIcon = const CategoryIcon(icon: Icons.euro_symbol),
    this.flagIcon = const CategoryIcon(icon: Icons.flag),
  });
}
