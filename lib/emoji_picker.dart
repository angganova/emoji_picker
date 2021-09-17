library emoji_picker;

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:emoji_picker/categories.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'emoji_lists.dart' as emojiList;

/// All the possible categories that [Emoji] can be put into
///
/// All [Category] are shown in the keyboard bottombar with the exception of [Category.RECOMMENDED]
/// which only displays when keywords are given

/// Enum to alter the keyboard button style
enum ButtonMode {
  /// Android button style - gives the button a splash color with ripple effect
  MATERIAL,

  /// iOS button style - gives the button a fade out effect when pressed
  CUPERTINO
}

/// Callback function for when emoji is selected
///
/// The function returns the selected [Emoji] as well as the [Category] from which it originated
typedef void OnEmojiSelected(Emoji emoji, Category category);

class _Recommended {
  final String name;
  final String emoji;
  final int tier;
  final int numSplitEqualKeyword;
  final int numSplitPartialKeyword;

  const _Recommended(
      {required this.name,
      required this.emoji,
      required this.tier,
      this.numSplitEqualKeyword = 0,
      this.numSplitPartialKeyword = 0});
}

/// Class that defines the icon representing a [Category]
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

/// Class used to define all the [CategoryIcon] shown for each [Category]
///
/// This allows the keyboard to be personalized by changing icons shown.
/// If a [CategoryIcon] is set as null or not defined during initialization, the default icons will be used instead
class CategoryIcons {
  /// Icon for [Category.RECOMMENDED]
  final CategoryIcon recommendationIcon;

  /// Icon for [Category.RECENT]
  final CategoryIcon recentIcon;

  /// Icon for [Category.SMILEYS]
  final CategoryIcon smileyIcon;

  /// Icon for [Category.ANIMALS]
  final CategoryIcon animalIcon;

  /// Icon for [Category.FOODS]
  final CategoryIcon foodIcon;

  /// Icon for [Category.TRAVEL]
  final CategoryIcon travelIcon;

  /// Icon for [Category.ACTIVITIES]
  final CategoryIcon activityIcon;

  /// Icon for [Category.OBJECTS]
  final CategoryIcon objectIcon;

  /// Icon for [Category.SYMBOLS]
  final CategoryIcon symbolIcon;

  /// Icon for [Category.FLAGS]
  final CategoryIcon flagIcon;

  CategoryIcon fromCategory(Category category) {
    switch (category) {
      case Category.RECOMMENDED:
        return recommendationIcon;
      case Category.RECENT:
        return recentIcon;
      case Category.SMILEYS:
        return smileyIcon;
      case Category.ANIMALS:
        return animalIcon;
      case Category.FOODS:
        return foodIcon;
      case Category.TRAVEL:
        return travelIcon;
      case Category.ACTIVITIES:
        return activityIcon;
      case Category.OBJECTS:
        return objectIcon;
      case Category.SYMBOLS:
        return symbolIcon;
      case Category.FLAGS:
        return flagIcon;
    }
  }

  const CategoryIcons(
      {this.recommendationIcon = const CategoryIcon(icon: Icons.search),
      this.recentIcon = const CategoryIcon(icon: Icons.access_time),
      this.smileyIcon = const CategoryIcon(icon: Icons.tag_faces),
      this.animalIcon = const CategoryIcon(icon: Icons.pets),
      this.foodIcon = const CategoryIcon(icon: Icons.fastfood),
      this.travelIcon = const CategoryIcon(icon: Icons.location_city),
      this.activityIcon = const CategoryIcon(icon: Icons.directions_run),
      this.objectIcon = const CategoryIcon(icon: Icons.lightbulb_outline),
      this.symbolIcon = const CategoryIcon(icon: Icons.euro_symbol),
      this.flagIcon = const CategoryIcon(icon: Icons.flag)});
}

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

/// The Emoji Keyboard widget
///
/// This widget displays a grid of [Emoji] sorted by [Category] which the user can horizontally scroll through.
///
/// There is also a bottombar which displays all the possible [Category] and allow the user to quickly switch to that [Category]
class EmojiPicker extends StatefulWidget {
  @override
  _EmojiPickerState createState() => new _EmojiPickerState();

  /// Number of columns in keyboard grid
  final int columns;

  /// Number of rows in keyboard grid
  final int rows;

  /// The currently selected [Category]
  ///
  /// This [Category] will have its button in the bottombar darkened
  final Category selectedCategory;

  /// The function called when the emoji is selected
  final OnEmojiSelected onEmojiSelected;

  /// The background color of the keyboard
  final Color? bgColor;

  /// The color of the keyboard page indicator
  final Color indicatorColor;

  final Color progressIndicatorColor;

  /// A list of keywords that are used to provide the user with recommended emojis in [Category.RECOMMENDED]
  final List<String>? recommendKeywords;

  /// The maximum number of emojis to be recommended
  final int numRecommended;

  /// The string to be displayed if no recommendations found
  final String noRecommendationsText;

  /// The text style for the [noRecommendationsText]
  final TextStyle noRecommendationsStyle;

  /// The string to be displayed if no recent emojis to display
  final String noRecentsText;

  /// The text style for the [noRecentsText]
  final TextStyle noRecentsStyle;

  /// Determines the icon to display for each [Category]
  final CategoryIcons categoryIcons;

  /// Determines the style given to the keyboard keys
  final ButtonMode buttonMode;

  final Color defaultCategoryColor;
  final Color defaultCategorySelectedColor;

  final Color defaultCategoryIconColor;
  final Color defaultCategoryIconSelectedColor;

  final BoxDecoration? decoration;

  const EmojiPicker({
    Key? key,
    required this.onEmojiSelected,
    this.columns = 15,
    this.rows = 5,
    this.recommendKeywords = null,
    this.selectedCategory = Category.RECOMMENDED,
    this.bgColor = const Color.fromRGBO(242, 242, 242, 1),
    this.indicatorColor = Colors.blue,
    this.progressIndicatorColor = Colors.blue,
    this.numRecommended = 10,
    this.decoration,
    this.defaultCategoryIconColor = const Color.fromRGBO(211, 211, 211, 1),
    this.defaultCategoryIconSelectedColor =
        const Color.fromRGBO(178, 178, 178, 1),
    this.defaultCategoryColor = Colors.transparent,
    this.defaultCategorySelectedColor = Colors.black12,
    this.noRecommendationsText = "No Recommendations",
    this.noRecommendationsStyle =
        const TextStyle(fontSize: 20, color: Colors.black26),
    this.noRecentsText = "No Recents",
    this.noRecentsStyle = const TextStyle(fontSize: 20, color: Colors.black26),
    this.categoryIcons = const CategoryIcons(),
    this.buttonMode = ButtonMode.MATERIAL,
    //this.unavailableEmojiIcon,
  }) : super(key: key);
}

class _EmojiPickerState extends State<EmojiPicker> {
  static const platform = const MethodChannel("emoji_picker");

  List<Widget> pages = [];
  late int recommendedPagesNum;
  late int recentPagesNum = 0;
  late int smileyPagesNum;
  late int animalPagesNum;
  late int foodPagesNum;
  late int travelPagesNum;
  late int activityPagesNum;
  late int objectPagesNum;
  late int symbolPagesNum;
  late int flagPagesNum;

  bool pageIsScrolling = false;

  late Category selectedCategory;

  List<String> allNames = [];
  List<String> allEmojis = [];
  List<String> recentEmojis = [];

  Map<String, String> smileyMap = new Map();
  Map<String, String> animalMap = new Map();
  Map<String, String> foodMap = new Map();
  Map<String, String> travelMap = new Map();
  Map<String, String> activityMap = new Map();
  Map<String, String> objectMap = new Map();
  Map<String, String> symbolMap = new Map();
  Map<String, String> flagMap = new Map();

  bool loaded = false;

  @override
  void initState() {
    super.initState();

    selectedCategory = widget.selectedCategory;

    updateEmojis().then((_) {
      loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    double fontSize = 24.0;
    double buttonPadding = 4;
    double marginBetweenRows = 12;
    double height = MediaQuery.of(context).size.height / 9 +
        ((fontSize + buttonPadding) * widget.rows) +
        ((widget.rows - 1) * marginBetweenRows);

    if (loaded) {
      pages.removeAt(recommendedPagesNum);
      pages.insert(recommendedPagesNum, recentPages()[0]);

      PageController pageController = getPageController();

      pageController.addListener(() {
        setState(() {});
      });

      return Container(
        decoration: widget.decoration,
        child: Column(
          children: <Widget>[
            GestureDetector(
              onPanUpdate: (details) {
                _onScroll(pageController, details.delta.dy * -1);
              },
              child: Listener(
                onPointerSignal: (event) {
                  if (event is PointerScrollEvent) {
                    _onScroll(pageController, event.scrollDelta.dy);
                  }
                },
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: height,
                    maxHeight: height,
                  ),
                  child: PageView.builder(
                      itemBuilder: (builder, index) => pages[index],
                      physics: NeverScrollableScrollPhysics(),
                      controller: pageController,
                      onPageChanged: onPageChanged),
                ),
              ),
            ),
            Container(
                color: widget.bgColor,
                height: 6,
                padding:
                    EdgeInsets.only(top: 4, bottom: 0, right: 2, left: 2),
                child: CustomPaint(
                  painter: _ProgressPainter(
                      context,
                      pageController,
                      new Map.fromIterables([
                        Category.RECOMMENDED,
                        Category.RECENT,
                        Category.SMILEYS,
                        Category.ANIMALS,
                        Category.FOODS,
                        Category.TRAVEL,
                        Category.ACTIVITIES,
                        Category.OBJECTS,
                        Category.SYMBOLS,
                        Category.FLAGS
                      ], [
                        recommendedPagesNum,
                        recentPagesNum,
                        smileyPagesNum,
                        animalPagesNum,
                        foodPagesNum,
                        travelPagesNum,
                        activityPagesNum,
                        objectPagesNum,
                        symbolPagesNum,
                        flagPagesNum
                      ]),
                      selectedCategory,
                      widget.indicatorColor),
                )),
            listOfCategories(pageController),
          ],
        ),
      );
    } else {
      return Container(
        child: Column(
          children: <Widget>[
            Expanded(
              child: Container(
                color: widget.bgColor,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: height,
                    maxHeight: height,
                  ),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        widget.progressIndicatorColor),
                  ),
                ),
              ),
            ),
            Container(
              height: 6,
              color: widget.bgColor,
              padding: EdgeInsets.only(top: 4, left: 2, right: 2),
              child: Container(
                color: widget.indicatorColor,
              ),
            ),
            Container(
              height: 50,
              child: Row(
                children: <Widget>[
                  widget.recommendKeywords != null
                      ? defaultButton(widget.categoryIcons.recommendationIcon)
                      : Container(),
                  defaultButton(widget.categoryIcons.recentIcon),
                  defaultButton(widget.categoryIcons.smileyIcon),
                  defaultButton(widget.categoryIcons.animalIcon),
                  defaultButton(widget.categoryIcons.foodIcon),
                  defaultButton(widget.categoryIcons.travelIcon),
                  defaultButton(widget.categoryIcons.activityIcon),
                  defaultButton(widget.categoryIcons.objectIcon),
                  defaultButton(widget.categoryIcons.symbolIcon),
                  defaultButton(widget.categoryIcons.flagIcon),
                ],
              ),
            )
          ],
        ),
      );
    }
  }

  List<Widget> emojiPages(int numberOfPages, Map<String, String> emojiMap) {
    List<Widget> pages = [];
    for (var i = 0; i < numberOfPages; i++) {
      int index = -1;
      Container container = Container(
          color: widget.bgColor,
          child: Column(
              children: List.generate(widget.rows, (indexRow) {
            return Row(
                children: List.generate(widget.columns, (indexColumn) {
              index++;
              if (index + (widget.columns * widget.rows * i) <
                  emojiMap.values.toList().length) {
                return buttons(emojiMap, index, i);
              } else {
                return emptyButton();
              }
            }));
          })));
      pages.add(container);
    }
    return pages;
  }

  Widget buttons(Map<String, String> emojis, int index, int pageIndex) {
    MapEntry<String, String> keyValue = emojis.entries
        .toList()[index + (widget.columns * widget.rows * pageIndex)];
    Emoji emoji = Emoji(name: keyValue.key, emoji: keyValue.value);

    VoidCallback? onPressed = () {
      widget.onEmojiSelected(emoji, selectedCategory);
      addRecentEmoji(emoji);
    };

    Center buttonContent = Center(
      child: Text(
        emoji.emoji,
        style: TextStyle(
            fontFamilyFallback: ['NotoColorEmoji', 'Roboto Mono', 'Roboto'],
            fontSize: 24),
      ),
    );

    switch (widget.buttonMode) {
      case ButtonMode.MATERIAL:
        return Expanded(
            child: Center(
                child: FlatButton(
          padding: EdgeInsets.all(0),
          child: buttonContent,
          onPressed: onPressed,
        )));
      case ButtonMode.CUPERTINO:
        return Center(
            child: CupertinoButton(
          pressedOpacity: 0.4,
          padding: EdgeInsets.all(0),
          child: buttonContent,
          onPressed: onPressed,
        ));
      default:
        return Container();
    }
  }

  Widget emptyButton() {
    return Expanded(
        child: Center(
            child: Container(
      padding: EdgeInsets.all(0),
      child: Center(
        child: Text(
          "",
          style: TextStyle(
              fontFamilyFallback: ['NotoColorEmoji', 'Roboto Mono', 'Roboto'],
              fontSize: 24),
        ),
      ),
    )));
  }

  List<Widget> recentPages() {
    if (recentEmojis.length != 0) {
      recentPagesNum =
          (smileyMap.values.toList().length / (widget.rows * widget.columns))
              .ceil();
      Map<String, String> emojisMap = Map.fromIterable(recentEmojis,
          key: (e) => e.name, value: (e) => e.emoji);
      return emojiPages(recentPagesNum, emojisMap);
    } else {
      recentPagesNum = 1;
      return [
        Container(
            color: widget.bgColor,
            child: Center(
                child: Text(
              widget.noRecentsText,
              style: widget.noRecentsStyle,
            )))
      ];
    }
  }

  Widget defaultButton(CategoryIcon categoryIcon) {
    return Expanded(
      child: Container(
        color: widget.bgColor,
        child: Center(
          child: Icon(
            categoryIcon.icon,
            size: 22,
            color: categoryIcon.color,
          ),
        ),
      ),
    );
  }

  Widget singleCategory(
      PageController pageController, Category category, int jumpToPage) {
    Color iconNotSelectedColor =
        widget.categoryIcons.fromCategory(category).color ??
            widget.defaultCategoryColor;
    Color selectedIconColor =
        widget.categoryIcons.fromCategory(category).selectedColor ??
            widget.defaultCategorySelectedColor;

    Color color =
        selectedCategory == category ? selectedIconColor : iconNotSelectedColor;

    Color? iconColor = selectedCategory == category
        ? widget.defaultCategoryIconSelectedColor
        : widget.defaultCategoryIconColor;

    VoidCallback? onPressed = () {
      if (selectedCategory == category) {
        return;
      }

      pageController.jumpToPage(jumpToPage);
    };

    return Expanded(
      child: widget.buttonMode == ButtonMode.MATERIAL
          ? FlatButton(
              padding: EdgeInsets.all(0),
              color: color,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(0))),
              child: Center(
                child: Icon(
                  widget.categoryIcons.fromCategory(category).icon,
                  size: 22,
                  color: iconColor,
                ),
              ),
              onPressed: onPressed,
            )
          : CupertinoButton(
              pressedOpacity: 0.4,
              padding: EdgeInsets.all(0),
              color: color,
              borderRadius: BorderRadius.all(Radius.circular(0)),
              child: Center(
                child: Icon(
                  widget.categoryIcons.fromCategory(category).icon,
                  size: 22,
                  color: iconColor,
                ),
              ),
              onPressed: onPressed,
            ),
    );
  }

  Widget listOfCategories(PageController pageController) {
    int pages = 0;
    return Container(
        height: 50,
        color: widget.bgColor,
        child: Row(
          children: <Widget>[
            widget.recommendKeywords != null
                ? singleCategory(pageController, Category.RECOMMENDED, pages)
                : Container(),
            singleCategory(
                pageController, Category.RECENT, pages += recommendedPagesNum),
            singleCategory(
                pageController, Category.SMILEYS, pages += recentPagesNum),
            singleCategory(
                pageController, Category.ANIMALS, pages += smileyPagesNum),
            singleCategory(
                pageController, Category.FOODS, pages += animalPagesNum),
            singleCategory(
                pageController, Category.TRAVEL, pages += foodPagesNum),
            singleCategory(
                pageController, Category.ACTIVITIES, pages += travelPagesNum),
            singleCategory(
                pageController, Category.OBJECTS, pages += activityPagesNum),
            singleCategory(
                pageController, Category.SYMBOLS, pages += objectPagesNum),
            singleCategory(
                pageController, Category.FLAGS, pages += symbolPagesNum),
          ],
        ));
  }

  Future<bool> _isEmojiAvailable(String emoji) async {
    if (Platform.isAndroid) {
      bool isAvailable;
      try {
        isAvailable =
            await platform.invokeMethod("isAvailable", {"emoji": emoji});
      } on PlatformException catch (_) {
        isAvailable = false;
      }
      return isAvailable;
    } else {
      return true;
    }
  }

  Future<Map<String, String>?> _getFiltered(Map<String, String> emoji) async {
    bool isAndroid = false;

    try {
      isAndroid = Platform.isAndroid;
    } catch (e) {}

    if (isAndroid) {
      Map<String, String>? filtered;
      try {
        var temp =
            await platform.invokeMethod("checkAvailability", {'emoji': emoji});
        filtered = Map<String, String>.from(temp);
      } on PlatformException catch (_) {
        filtered = null;
      }
      return filtered;
    } else {
      return emoji;
    }
  }

  Future<List<String>> getRecentEmojis() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final key = "recents";
    recentEmojis = prefs.getStringList(key) ?? new List.empty();
    return recentEmojis;
  }

  PageController getPageController() {
    if (selectedCategory == Category.RECOMMENDED) {
      return PageController(initialPage: 0);
    } else if (selectedCategory == Category.RECENT) {
      return PageController(initialPage: recommendedPagesNum);
    } else if (selectedCategory == Category.SMILEYS) {
      return PageController(initialPage: recentPagesNum + recommendedPagesNum);
    } else if (selectedCategory == Category.ANIMALS) {
      return PageController(
          initialPage: smileyPagesNum + recentPagesNum + recommendedPagesNum);
    } else if (selectedCategory == Category.FOODS) {
      return PageController(
          initialPage: smileyPagesNum +
              animalPagesNum +
              recentPagesNum +
              recommendedPagesNum);
    } else if (selectedCategory == Category.TRAVEL) {
      return PageController(
          initialPage: smileyPagesNum +
              animalPagesNum +
              foodPagesNum +
              recentPagesNum +
              recommendedPagesNum);
    } else if (selectedCategory == Category.ACTIVITIES) {
      return PageController(
          initialPage: smileyPagesNum +
              animalPagesNum +
              foodPagesNum +
              travelPagesNum +
              recentPagesNum +
              recommendedPagesNum);
    } else if (selectedCategory == Category.OBJECTS) {
      return PageController(
          initialPage: smileyPagesNum +
              animalPagesNum +
              foodPagesNum +
              travelPagesNum +
              activityPagesNum +
              recentPagesNum +
              recommendedPagesNum);
    } else if (selectedCategory == Category.SYMBOLS) {
      return PageController(
          initialPage: smileyPagesNum +
              animalPagesNum +
              foodPagesNum +
              travelPagesNum +
              activityPagesNum +
              objectPagesNum +
              recentPagesNum +
              recommendedPagesNum);
    } else {
      return PageController(
          initialPage: smileyPagesNum +
              animalPagesNum +
              foodPagesNum +
              travelPagesNum +
              activityPagesNum +
              objectPagesNum +
              symbolPagesNum +
              recentPagesNum +
              recommendedPagesNum);
    }
  }

  void onPageChanged(index) {
    if (widget.recommendKeywords != null && index < recommendedPagesNum) {
      selectedCategory = Category.RECOMMENDED;
    } else if (index < recentPagesNum + recommendedPagesNum) {
      selectedCategory = Category.RECENT;
    } else if (index < recentPagesNum + smileyPagesNum + recommendedPagesNum) {
      selectedCategory = Category.SMILEYS;
    } else if (index <
        recentPagesNum +
            smileyPagesNum +
            animalPagesNum +
            recommendedPagesNum) {
      selectedCategory = Category.ANIMALS;
    } else if (index <
        recentPagesNum +
            smileyPagesNum +
            animalPagesNum +
            foodPagesNum +
            recommendedPagesNum) {
      selectedCategory = Category.FOODS;
    } else if (index <
        recentPagesNum +
            smileyPagesNum +
            animalPagesNum +
            foodPagesNum +
            travelPagesNum +
            recommendedPagesNum) {
      selectedCategory = Category.TRAVEL;
    } else if (index <
        recentPagesNum +
            smileyPagesNum +
            animalPagesNum +
            foodPagesNum +
            travelPagesNum +
            activityPagesNum +
            recommendedPagesNum) {
      selectedCategory = Category.ACTIVITIES;
    } else if (index <
        recentPagesNum +
            smileyPagesNum +
            animalPagesNum +
            foodPagesNum +
            travelPagesNum +
            activityPagesNum +
            objectPagesNum +
            recommendedPagesNum) {
      selectedCategory = Category.OBJECTS;
    } else if (index <
        recentPagesNum +
            smileyPagesNum +
            animalPagesNum +
            foodPagesNum +
            travelPagesNum +
            activityPagesNum +
            objectPagesNum +
            symbolPagesNum +
            recommendedPagesNum) {
      selectedCategory = Category.SYMBOLS;
    } else {
      selectedCategory = Category.FLAGS;
    }
  }

  void addRecentEmoji(Emoji emoji) async {
    final prefs = await SharedPreferences.getInstance();
    final key = "recents";
    getRecentEmojis().then((_) {
      setState(() {
        recentEmojis.insert(0, emoji.name);
        prefs.setStringList(key, recentEmojis);
      });
    });
  }

  Future<Map<String, String>> getAvailableEmojis(Map<String, String> map,
      {required String title}) async {
    Map<String, String>? newMap;

    newMap = await restoreFilteredEmojis(title);

    if (newMap != null) {
      return newMap;
    }

    newMap = await _getFiltered(map);

    await cacheFilteredEmojis(title, newMap);

    return newMap ?? {};
  }

  Future<void> cacheFilteredEmojis(
      String title, Map<String, String>? emojis) async {
    final prefs = await SharedPreferences.getInstance();
    String emojiJson = jsonEncode(emojis);
    prefs.setString(title, emojiJson);
    return;
  }

  Future<Map<String, String>?> restoreFilteredEmojis(String title) async {
    final prefs = await SharedPreferences.getInstance();
    String? emojiJson = prefs.getString(title);
    if (emojiJson == null) {
      return null;
    }
    Map<String, String> emojis =
        Map<String, String>.from(jsonDecode(emojiJson));
    return emojis;
  }

  Future updateEmojis() async {
    smileyMap = await getAvailableEmojis(emojiList.smileys, title: 'smileys');
    animalMap = await getAvailableEmojis(emojiList.animals, title: 'animals');
    foodMap = await getAvailableEmojis(emojiList.foods, title: 'foods');
    travelMap = await getAvailableEmojis(emojiList.travel, title: 'travel');
    activityMap =
        await getAvailableEmojis(emojiList.activities, title: 'activities');
    objectMap = await getAvailableEmojis(emojiList.objects, title: 'objects');
    symbolMap = await getAvailableEmojis(emojiList.symbols, title: 'symbols');
    flagMap = await getAvailableEmojis(emojiList.flags, title: 'flags');

    allNames.addAll(smileyMap.keys);
    allNames.addAll(animalMap.keys);
    allNames.addAll(foodMap.keys);
    allNames.addAll(travelMap.keys);
    allNames.addAll(activityMap.keys);
    allNames.addAll(objectMap.keys);
    allNames.addAll(symbolMap.keys);
    allNames.addAll(flagMap.keys);

    allEmojis.addAll(smileyMap.values);
    allEmojis.addAll(animalMap.values);
    allEmojis.addAll(foodMap.values);
    allEmojis.addAll(travelMap.values);
    allEmojis.addAll(activityMap.values);
    allEmojis.addAll(objectMap.values);
    allEmojis.addAll(symbolMap.values);
    allEmojis.addAll(flagMap.values);

    recommendedPagesNum = 0;
    List<_Recommended> recommendedEmojis = [];
    List<Widget> recommendedPages = [];

    if (widget.recommendKeywords != null) {
      allNames.forEach((name) {
        int numSplitEqualKeyword = 0;
        int numSplitPartialKeyword = 0;

        widget.recommendKeywords ??
            [].forEach((keyword) {
              if (name.toLowerCase() == keyword.toLowerCase()) {
                recommendedEmojis.add(_Recommended(
                    name: name,
                    emoji: allEmojis[allNames.indexOf(name)],
                    tier: 1));
              } else {
                List<String> splitName = name.split(" ");

                splitName.forEach((splitName) {
                  if (splitName.replaceAll(":", "").toLowerCase() ==
                      keyword.toLowerCase()) {
                    numSplitEqualKeyword += 1;
                  } else if (splitName
                      .replaceAll(":", "")
                      .toLowerCase()
                      .contains(keyword.toLowerCase())) {
                    numSplitPartialKeyword += 1;
                  }
                });
              }
            });

        if (numSplitEqualKeyword > 0) {
          if (numSplitEqualKeyword == name.split(" ").length) {
            recommendedEmojis.add(_Recommended(
                name: name, emoji: allEmojis[allNames.indexOf(name)], tier: 1));
          } else {
            recommendedEmojis.add(_Recommended(
                name: name,
                emoji: allEmojis[allNames.indexOf(name)],
                tier: 2,
                numSplitEqualKeyword: numSplitEqualKeyword,
                numSplitPartialKeyword: numSplitPartialKeyword));
          }
        } else if (numSplitPartialKeyword > 0) {
          recommendedEmojis.add(_Recommended(
              name: name,
              emoji: allEmojis[allNames.indexOf(name)],
              tier: 3,
              numSplitPartialKeyword: numSplitPartialKeyword));
        }
      });

      recommendedEmojis.sort((a, b) {
        if (a.tier < b.tier) {
          return -1;
        } else if (a.tier > b.tier) {
          return 1;
        } else {
          if (a.tier == 1) {
            if (a.name.split(" ").length > b.name.split(" ").length) {
              return -1;
            } else if (a.name.split(" ").length < b.name.split(" ").length) {
              return 1;
            } else {
              return 0;
            }
          } else if (a.tier == 2) {
            if (a.numSplitEqualKeyword > b.numSplitEqualKeyword) {
              return -1;
            } else if (a.numSplitEqualKeyword < b.numSplitEqualKeyword) {
              return 1;
            } else {
              if (a.numSplitPartialKeyword > b.numSplitPartialKeyword) {
                return -1;
              } else if (a.numSplitPartialKeyword < b.numSplitPartialKeyword) {
                return 1;
              } else {
                if (a.name.split(" ").length < b.name.split(" ").length) {
                  return -1;
                } else if (a.name.split(" ").length >
                    b.name.split(" ").length) {
                  return 1;
                } else {
                  return 0;
                }
              }
            }
          } else if (a.tier == 3) {
            if (a.numSplitPartialKeyword > b.numSplitPartialKeyword) {
              return -1;
            } else if (a.numSplitPartialKeyword < b.numSplitPartialKeyword) {
              return 1;
            } else {
              return 0;
            }
          }
        }

        return 0;
      });

      if (recommendedEmojis.length > widget.numRecommended) {
        recommendedEmojis =
            recommendedEmojis.getRange(0, widget.numRecommended).toList();
      }

      if (recommendedEmojis.length != 0) {
        recommendedPagesNum =
            (recommendedEmojis.length / (widget.rows * widget.columns)).ceil();
        Map<String, String> emojisMap = Map.fromIterable(recommendedEmojis,
            key: (e) => e.name, value: (e) => e.emoji);
        recommendedPages = emojiPages(smileyPagesNum, emojisMap);
      } else {
        recommendedPagesNum = 1;
        recommendedPages.add(Container(
            color: widget.bgColor,
            child: Center(
                child: Text(
              widget.noRecommendationsText,
              style: widget.noRecommendationsStyle,
            ))));
      }
    } else {
      selectedCategory = Category.RECENT;
    }

    smileyPagesNum =
        (smileyMap.values.toList().length / (widget.rows * widget.columns))
            .ceil();
    List<Widget> smileyPages = emojiPages(smileyPagesNum, smileyMap);

    animalPagesNum =
        (animalMap.values.toList().length / (widget.rows * widget.columns))
            .ceil();
    List<Widget> animalPages = emojiPages(animalPagesNum, animalMap);

    foodPagesNum =
        (foodMap.values.toList().length / (widget.rows * widget.columns))
            .ceil();
    List<Widget> foodPages = emojiPages(foodPagesNum, foodMap);

    travelPagesNum =
        (travelMap.values.toList().length / (widget.rows * widget.columns))
            .ceil();
    List<Widget> travelPages = emojiPages(travelPagesNum, travelMap);

    activityPagesNum =
        (activityMap.values.toList().length / (widget.rows * widget.columns))
            .ceil();
    List<Widget> activityPages = emojiPages(activityPagesNum, activityMap);

    objectPagesNum =
        (objectMap.values.toList().length / (widget.rows * widget.columns))
            .ceil();
    List<Widget> objectPages = emojiPages(objectPagesNum, objectMap);

    symbolPagesNum =
        (symbolMap.values.toList().length / (widget.rows * widget.columns))
            .ceil();
    List<Widget> symbolPages = emojiPages(symbolPagesNum, symbolMap);

    flagPagesNum =
        (flagMap.values.toList().length / (widget.rows * widget.columns))
            .ceil();
    List<Widget> flagPages = emojiPages(flagPagesNum, flagMap);

    pages.addAll(recommendedPages);
    pages.addAll(recentPages());
    pages.addAll(smileyPages);
    pages.addAll(animalPages);
    pages.addAll(foodPages);
    pages.addAll(travelPages);
    pages.addAll(activityPages);
    pages.addAll(objectPages);
    pages.addAll(symbolPages);
    pages.addAll(flagPages);

    if (mounted) setState(() {});

    getRecentEmojis().then((_) {
      pages.removeAt(recommendedPagesNum);
      if (mounted) setState(() {});
    });
  }

  void _onScroll(PageController pageController, double offset) {
    if (pageIsScrolling == false) {
      pageIsScrolling = true;
      if (offset > 0) {
        pageController
            .nextPage(
                duration: Duration(milliseconds: 300), curve: Curves.easeInOut)
            .then((value) => pageIsScrolling = false);
      } else {
        pageController
            .previousPage(
                duration: Duration(milliseconds: 300), curve: Curves.easeInOut)
            .then((value) => pageIsScrolling = false);
      }
    }
  }
}

class _ProgressPainter extends CustomPainter {
  final BuildContext context;
  final PageController pageController;
  final Map<Category, int> pages;
  final Category selectedCategory;
  final Color indicatorColor;

  _ProgressPainter(this.context, this.pageController, this.pages,
      this.selectedCategory, this.indicatorColor);

  @override
  void paint(Canvas canvas, Size size) {
    double actualPageWidth = size.width;
    double offsetInPages = 0;
    if (selectedCategory == Category.RECOMMENDED) {
      offsetInPages = pageController.offset / actualPageWidth;
    } else if (selectedCategory == Category.RECENT) {
      offsetInPages = (pageController.offset -
              (pages[Category.RECOMMENDED] ?? 0 * actualPageWidth)) /
          actualPageWidth;
    } else if (selectedCategory == Category.SMILEYS) {
      offsetInPages = (pageController.offset -
              ((pages[Category.RECOMMENDED] ??
                      0 + (pages[Category.RECENT] ?? 0)) *
                  actualPageWidth)) /
          actualPageWidth;
    } else if (selectedCategory == Category.ANIMALS) {
      offsetInPages = (pageController.offset -
              (((pages[Category.RECOMMENDED] ?? 0) +
                      (pages[Category.RECENT] ?? 0) +
                      (pages[Category.SMILEYS] ?? 0)) *
                  actualPageWidth)) /
          actualPageWidth;
    } else if (selectedCategory == Category.FOODS) {
      offsetInPages = (pageController.offset -
              (((pages[Category.RECOMMENDED] ?? 0) +
                      (pages[Category.RECENT] ?? 0) +
                      (pages[Category.SMILEYS] ?? 0) +
                      (pages[Category.ANIMALS] ?? 0)) *
                  actualPageWidth)) /
          actualPageWidth;
    } else if (selectedCategory == Category.TRAVEL) {
      offsetInPages = (pageController.offset -
              (((pages[Category.RECOMMENDED] ?? 0) +
                      (pages[Category.RECENT] ?? 0) +
                      (pages[Category.SMILEYS] ?? 0) +
                      (pages[Category.ANIMALS] ?? 0) +
                      (pages[Category.FOODS] ?? 0)) *
                  actualPageWidth)) /
          actualPageWidth;
    } else if (selectedCategory == Category.ACTIVITIES) {
      offsetInPages = (pageController.offset -
              (((pages[Category.RECOMMENDED] ?? 0) +
                      (pages[Category.RECENT] ?? 0) +
                      (pages[Category.SMILEYS] ?? 0) +
                      (pages[Category.ANIMALS] ?? 0) +
                      (pages[Category.FOODS] ?? 0) +
                      (pages[Category.TRAVEL] ?? 0)) *
                  actualPageWidth)) /
          actualPageWidth;
    } else if (selectedCategory == Category.OBJECTS) {
      offsetInPages = (pageController.offset -
              (((pages[Category.RECOMMENDED] ?? 0) +
                      (pages[Category.RECENT] ?? 0) +
                      (pages[Category.SMILEYS] ?? 0) +
                      (pages[Category.ANIMALS] ?? 0) +
                      (pages[Category.FOODS] ?? 0) +
                      (pages[Category.TRAVEL] ?? 0) +
                      (pages[Category.ACTIVITIES] ?? 0)) *
                  actualPageWidth)) /
          actualPageWidth;
    } else if (selectedCategory == Category.SYMBOLS) {
      offsetInPages = (pageController.offset -
              (((pages[Category.RECOMMENDED] ?? 0) +
                      (pages[Category.RECENT] ?? 0) +
                      (pages[Category.SMILEYS] ?? 0) +
                      (pages[Category.ANIMALS] ?? 0) +
                      (pages[Category.FOODS] ?? 0) +
                      (pages[Category.TRAVEL] ?? 0) +
                      (pages[Category.ACTIVITIES] ?? 0) +
                      (pages[Category.OBJECTS] ?? 0)) *
                  actualPageWidth)) /
          actualPageWidth;
    } else if (selectedCategory == Category.FLAGS) {
      offsetInPages = (pageController.offset -
              (((pages[Category.RECOMMENDED] ?? 0) +
                      (pages[Category.RECENT] ?? 0) +
                      (pages[Category.SMILEYS] ?? 0) +
                      (pages[Category.ANIMALS] ?? 0) +
                      (pages[Category.FOODS] ?? 0) +
                      (pages[Category.TRAVEL] ?? 0) +
                      (pages[Category.ACTIVITIES] ?? 0) +
                      (pages[Category.OBJECTS] ?? 0) +
                      (pages[Category.SYMBOLS] ?? 0)) *
                  actualPageWidth)) /
          actualPageWidth;
    }
    double indicatorPageWidth = size.width / (pages[selectedCategory] ?? 0);

    Rect bgRect = Offset(0, 0) & size;

    Rect indicator = Offset(max(0, offsetInPages * indicatorPageWidth), 0) &
        Size(
            indicatorPageWidth -
                max(
                    0,
                    (indicatorPageWidth +
                            (offsetInPages * indicatorPageWidth)) -
                        size.width) +
                min(0, offsetInPages * indicatorPageWidth),
            size.height);

    canvas.drawRect(bgRect, Paint()..color = Colors.black12);
    canvas.drawRect(indicator, Paint()..color = indicatorColor);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
