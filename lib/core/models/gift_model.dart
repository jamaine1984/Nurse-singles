import 'package:nightingale_heart/core/config/app_constants.dart';

/// A virtual gift that users can collect by watching ads and send to each other.
class GiftModel {
  const GiftModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.price,
    required this.category,
  });

  final String id;
  final String name;
  final String emoji;
  final int price; // cost in gift points (legacy, kept for sending)
  final GiftCategory category;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'price': price,
        'category': category.value,
      };

  factory GiftModel.fromMap(Map<String, dynamic> map) {
    return GiftModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      emoji: map['emoji'] as String? ?? '',
      price: (map['price'] as num?)?.toInt() ?? 0,
      category: GiftCategory.fromString(map['category'] as String?),
    );
  }

  /// Look up a gift by its ID; returns `null` if not found.
  static GiftModel? findById(String id) {
    try {
      return allGifts.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  /// All gifts filtered by category.
  static List<GiftModel> byCategory(GiftCategory category) {
    return allGifts.where((g) => g.category == category).toList();
  }

  // =====================================================================
  //  FULL GIFT CATALOGUE -- 100 gifts across 8 categories
  // =====================================================================

  static const List<GiftModel> allGifts = [
    // ─── Medical (15) ──────────────────────────────────────────────────
    GiftModel(
      id: 'med_stethoscope',
      name: 'Stethoscope',
      emoji: '\u{1FA7A}',
      price: 100,
      category: GiftCategory.medical,
    ),
    GiftModel(
      id: 'med_syringe',
      name: 'Syringe',
      emoji: '\u{1F489}',
      price: 40,
      category: GiftCategory.medical,
    ),
    GiftModel(
      id: 'med_pill',
      name: 'Pill',
      emoji: '\u{1F48A}',
      price: 30,
      category: GiftCategory.medical,
    ),
    GiftModel(
      id: 'med_heart_monitor',
      name: 'Heart Monitor',
      emoji: '\u{1F493}',
      price: 90,
      category: GiftCategory.medical,
    ),
    GiftModel(
      id: 'med_bandage',
      name: 'Bandage',
      emoji: '\u{1FA79}',
      price: 30,
      category: GiftCategory.medical,
    ),
    GiftModel(
      id: 'med_ambulance',
      name: 'Ambulance',
      emoji: '\u{1F691}',
      price: 120,
      category: GiftCategory.medical,
    ),
    GiftModel(
      id: 'med_hospital',
      name: 'Hospital',
      emoji: '\u{1F3E5}',
      price: 150,
      category: GiftCategory.medical,
    ),
    GiftModel(
      id: 'med_dna',
      name: 'DNA',
      emoji: '\u{1F9EC}',
      price: 80,
      category: GiftCategory.medical,
    ),
    GiftModel(
      id: 'med_microscope',
      name: 'Microscope',
      emoji: '\u{1F52C}',
      price: 110,
      category: GiftCategory.medical,
    ),
    GiftModel(
      id: 'med_thermometer',
      name: 'Thermometer',
      emoji: '\u{1F321}\u{FE0F}',
      price: 35,
      category: GiftCategory.medical,
    ),
    GiftModel(
      id: 'med_blood_drop',
      name: 'Blood Drop',
      emoji: '\u{1FA78}',
      price: 50,
      category: GiftCategory.medical,
    ),
    GiftModel(
      id: 'med_tooth',
      name: 'Tooth',
      emoji: '\u{1F9B7}',
      price: 45,
      category: GiftCategory.medical,
    ),
    GiftModel(
      id: 'med_brain',
      name: 'Brain',
      emoji: '\u{1F9E0}',
      price: 130,
      category: GiftCategory.medical,
    ),
    GiftModel(
      id: 'med_bone',
      name: 'Bone',
      emoji: '\u{1F9B4}',
      price: 55,
      category: GiftCategory.medical,
    ),
    GiftModel(
      id: 'med_lungs',
      name: 'Lungs',
      emoji: '\u{1FAC1}',
      price: 70,
      category: GiftCategory.medical,
    ),

    // ─── Romantic (15) ─────────────────────────────────────────────────
    GiftModel(
      id: 'rom_red_rose',
      name: 'Red Rose',
      emoji: '\u{1F339}',
      price: 25,
      category: GiftCategory.romantic,
    ),
    GiftModel(
      id: 'rom_heart',
      name: 'Heart',
      emoji: '\u{1F496}',
      price: 20,
      category: GiftCategory.romantic,
    ),
    GiftModel(
      id: 'rom_love_letter',
      name: 'Love Letter',
      emoji: '\u{1F48C}',
      price: 35,
      category: GiftCategory.romantic,
    ),
    GiftModel(
      id: 'rom_ring',
      name: 'Ring',
      emoji: '\u{1F48D}',
      price: 200,
      category: GiftCategory.romantic,
    ),
    GiftModel(
      id: 'rom_chocolate',
      name: 'Chocolate',
      emoji: '\u{1F36B}',
      price: 40,
      category: GiftCategory.romantic,
    ),
    GiftModel(
      id: 'rom_teddy_bear',
      name: 'Teddy Bear',
      emoji: '\u{1F9F8}',
      price: 70,
      category: GiftCategory.romantic,
    ),
    GiftModel(
      id: 'rom_kiss',
      name: 'Kiss',
      emoji: '\u{1F48B}',
      price: 15,
      category: GiftCategory.romantic,
    ),
    GiftModel(
      id: 'rom_cupid',
      name: 'Cupid',
      emoji: '\u{1F498}',
      price: 60,
      category: GiftCategory.romantic,
    ),
    GiftModel(
      id: 'rom_bouquet',
      name: 'Bouquet',
      emoji: '\u{1F490}',
      price: 55,
      category: GiftCategory.romantic,
    ),
    GiftModel(
      id: 'rom_candle',
      name: 'Candle',
      emoji: '\u{1F56F}\u{FE0F}',
      price: 45,
      category: GiftCategory.romantic,
    ),
    GiftModel(
      id: 'rom_wine_glass',
      name: 'Wine Glass',
      emoji: '\u{1F377}',
      price: 50,
      category: GiftCategory.romantic,
    ),
    GiftModel(
      id: 'rom_sparkles',
      name: 'Sparkles',
      emoji: '\u{2728}',
      price: 30,
      category: GiftCategory.romantic,
    ),
    GiftModel(
      id: 'rom_heart_eyes',
      name: 'Heart Eyes',
      emoji: '\u{1F60D}',
      price: 25,
      category: GiftCategory.romantic,
    ),
    GiftModel(
      id: 'rom_two_hearts',
      name: 'Two Hearts',
      emoji: '\u{1F495}',
      price: 35,
      category: GiftCategory.romantic,
    ),
    GiftModel(
      id: 'rom_heartbeat',
      name: 'Heartbeat',
      emoji: '\u{1F497}',
      price: 40,
      category: GiftCategory.romantic,
    ),

    // ─── Luxury (15) ───────────────────────────────────────────────────
    GiftModel(
      id: 'lux_crown',
      name: 'Crown',
      emoji: '\u{1F451}',
      price: 350,
      category: GiftCategory.luxury,
    ),
    GiftModel(
      id: 'lux_diamond',
      name: 'Diamond',
      emoji: '\u{1F48E}',
      price: 500,
      category: GiftCategory.luxury,
    ),
    GiftModel(
      id: 'lux_watch',
      name: 'Watch',
      emoji: '\u{231A}',
      price: 400,
      category: GiftCategory.luxury,
    ),
    GiftModel(
      id: 'lux_perfume',
      name: 'Perfume',
      emoji: '\u{1F9F4}',
      price: 180,
      category: GiftCategory.luxury,
    ),
    GiftModel(
      id: 'lux_high_heel',
      name: 'High Heel',
      emoji: '\u{1F460}',
      price: 220,
      category: GiftCategory.luxury,
    ),
    GiftModel(
      id: 'lux_sunglasses',
      name: 'Sunglasses',
      emoji: '\u{1F576}\u{FE0F}',
      price: 160,
      category: GiftCategory.luxury,
    ),
    GiftModel(
      id: 'lux_handbag',
      name: 'Handbag',
      emoji: '\u{1F45C}',
      price: 300,
      category: GiftCategory.luxury,
    ),
    GiftModel(
      id: 'lux_sports_car',
      name: 'Sports Car',
      emoji: '\u{1F3CE}\u{FE0F}',
      price: 1000,
      category: GiftCategory.luxury,
    ),
    GiftModel(
      id: 'lux_yacht',
      name: 'Yacht',
      emoji: '\u{1F6E5}\u{FE0F}',
      price: 1500,
      category: GiftCategory.luxury,
    ),
    GiftModel(
      id: 'lux_gem_stone',
      name: 'Gem Stone',
      emoji: '\u{1F4A0}',
      price: 250,
      category: GiftCategory.luxury,
    ),
    GiftModel(
      id: 'lux_crystal_ball',
      name: 'Crystal Ball',
      emoji: '\u{1F52E}',
      price: 200,
      category: GiftCategory.luxury,
    ),
    GiftModel(
      id: 'lux_trophy',
      name: 'Trophy',
      emoji: '\u{1F3C6}',
      price: 300,
      category: GiftCategory.luxury,
    ),
    GiftModel(
      id: 'lux_gold_medal',
      name: 'Gold Medal',
      emoji: '\u{1F947}',
      price: 280,
      category: GiftCategory.luxury,
    ),
    GiftModel(
      id: 'lux_star',
      name: 'Star',
      emoji: '\u{1F31F}',
      price: 150,
      category: GiftCategory.luxury,
    ),
    GiftModel(
      id: 'lux_castle',
      name: 'Castle',
      emoji: '\u{1F3F0}',
      price: 2000,
      category: GiftCategory.luxury,
    ),

    // ─── Food & Drink (15) ─────────────────────────────────────────────
    GiftModel(
      id: 'food_pizza',
      name: 'Pizza',
      emoji: '\u{1F355}',
      price: 30,
      category: GiftCategory.foodDrink,
    ),
    GiftModel(
      id: 'food_sushi',
      name: 'Sushi',
      emoji: '\u{1F363}',
      price: 65,
      category: GiftCategory.foodDrink,
    ),
    GiftModel(
      id: 'food_coffee',
      name: 'Coffee',
      emoji: '\u{2615}',
      price: 15,
      category: GiftCategory.foodDrink,
    ),
    GiftModel(
      id: 'food_cake',
      name: 'Cake',
      emoji: '\u{1F382}',
      price: 50,
      category: GiftCategory.foodDrink,
    ),
    GiftModel(
      id: 'food_ice_cream',
      name: 'Ice Cream',
      emoji: '\u{1F366}',
      price: 25,
      category: GiftCategory.foodDrink,
    ),
    GiftModel(
      id: 'food_donut',
      name: 'Donut',
      emoji: '\u{1F369}',
      price: 20,
      category: GiftCategory.foodDrink,
    ),
    GiftModel(
      id: 'food_bubble_tea',
      name: 'Bubble Tea',
      emoji: '\u{1F9CB}',
      price: 35,
      category: GiftCategory.foodDrink,
    ),
    GiftModel(
      id: 'food_cocktail',
      name: 'Cocktail',
      emoji: '\u{1F379}',
      price: 45,
      category: GiftCategory.foodDrink,
    ),
    GiftModel(
      id: 'food_beer',
      name: 'Beer',
      emoji: '\u{1F37A}',
      price: 30,
      category: GiftCategory.foodDrink,
    ),
    GiftModel(
      id: 'food_taco',
      name: 'Taco',
      emoji: '\u{1F32E}',
      price: 25,
      category: GiftCategory.foodDrink,
    ),
    GiftModel(
      id: 'food_ramen',
      name: 'Ramen',
      emoji: '\u{1F35C}',
      price: 40,
      category: GiftCategory.foodDrink,
    ),
    GiftModel(
      id: 'food_cookie',
      name: 'Cookie',
      emoji: '\u{1F36A}',
      price: 15,
      category: GiftCategory.foodDrink,
    ),
    GiftModel(
      id: 'food_cupcake',
      name: 'Cupcake',
      emoji: '\u{1F9C1}',
      price: 30,
      category: GiftCategory.foodDrink,
    ),
    GiftModel(
      id: 'food_grapes',
      name: 'Grapes',
      emoji: '\u{1F347}',
      price: 20,
      category: GiftCategory.foodDrink,
    ),
    GiftModel(
      id: 'food_avocado',
      name: 'Avocado',
      emoji: '\u{1F951}',
      price: 25,
      category: GiftCategory.foodDrink,
    ),

    // ─── Tech (10) ─────────────────────────────────────────────────────
    GiftModel(
      id: 'tech_laptop',
      name: 'Laptop',
      emoji: '\u{1F4BB}',
      price: 400,
      category: GiftCategory.tech,
    ),
    GiftModel(
      id: 'tech_phone',
      name: 'Phone',
      emoji: '\u{1F4F1}',
      price: 250,
      category: GiftCategory.tech,
    ),
    GiftModel(
      id: 'tech_robot',
      name: 'Robot',
      emoji: '\u{1F916}',
      price: 180,
      category: GiftCategory.tech,
    ),
    GiftModel(
      id: 'tech_game_controller',
      name: 'Game Controller',
      emoji: '\u{1F3AE}',
      price: 150,
      category: GiftCategory.tech,
    ),
    GiftModel(
      id: 'tech_headphones',
      name: 'Headphones',
      emoji: '\u{1F3A7}',
      price: 120,
      category: GiftCategory.tech,
    ),
    GiftModel(
      id: 'tech_camera',
      name: 'Camera',
      emoji: '\u{1F4F8}',
      price: 180,
      category: GiftCategory.tech,
    ),
    GiftModel(
      id: 'tech_rocket',
      name: 'Rocket',
      emoji: '\u{1F680}',
      price: 300,
      category: GiftCategory.tech,
    ),
    GiftModel(
      id: 'tech_satellite',
      name: 'Satellite',
      emoji: '\u{1F6F0}\u{FE0F}',
      price: 350,
      category: GiftCategory.tech,
    ),
    GiftModel(
      id: 'tech_electric_bolt',
      name: 'Electric Bolt',
      emoji: '\u{26A1}',
      price: 80,
      category: GiftCategory.tech,
    ),
    GiftModel(
      id: 'tech_alien',
      name: 'Alien',
      emoji: '\u{1F47D}',
      price: 200,
      category: GiftCategory.tech,
    ),

    // ─── Nature (10) ───────────────────────────────────────────────────
    GiftModel(
      id: 'nat_sunflower',
      name: 'Sunflower',
      emoji: '\u{1F33B}',
      price: 30,
      category: GiftCategory.nature,
    ),
    GiftModel(
      id: 'nat_cherry_blossom',
      name: 'Cherry Blossom',
      emoji: '\u{1F338}',
      price: 35,
      category: GiftCategory.nature,
    ),
    GiftModel(
      id: 'nat_rainbow',
      name: 'Rainbow',
      emoji: '\u{1F308}',
      price: 60,
      category: GiftCategory.nature,
    ),
    GiftModel(
      id: 'nat_butterfly',
      name: 'Butterfly',
      emoji: '\u{1F98B}',
      price: 45,
      category: GiftCategory.nature,
    ),
    GiftModel(
      id: 'nat_dolphin',
      name: 'Dolphin',
      emoji: '\u{1F42C}',
      price: 70,
      category: GiftCategory.nature,
    ),
    GiftModel(
      id: 'nat_panda',
      name: 'Panda',
      emoji: '\u{1F43C}',
      price: 80,
      category: GiftCategory.nature,
    ),
    GiftModel(
      id: 'nat_unicorn',
      name: 'Unicorn',
      emoji: '\u{1F984}',
      price: 100,
      category: GiftCategory.nature,
    ),
    GiftModel(
      id: 'nat_palm_tree',
      name: 'Palm Tree',
      emoji: '\u{1F334}',
      price: 40,
      category: GiftCategory.nature,
    ),
    GiftModel(
      id: 'nat_mountain',
      name: 'Mountain',
      emoji: '\u{1F3D4}\u{FE0F}',
      price: 55,
      category: GiftCategory.nature,
    ),
    GiftModel(
      id: 'nat_ocean_wave',
      name: 'Ocean Wave',
      emoji: '\u{1F30A}',
      price: 50,
      category: GiftCategory.nature,
    ),

    // ─── Fun (10) ──────────────────────────────────────────────────────
    GiftModel(
      id: 'fun_balloon',
      name: 'Balloon',
      emoji: '\u{1F388}',
      price: 20,
      category: GiftCategory.fun,
    ),
    GiftModel(
      id: 'fun_party_popper',
      name: 'Party Popper',
      emoji: '\u{1F389}',
      price: 35,
      category: GiftCategory.fun,
    ),
    GiftModel(
      id: 'fun_disco_ball',
      name: 'Disco Ball',
      emoji: '\u{1FAA9}',
      price: 60,
      category: GiftCategory.fun,
    ),
    GiftModel(
      id: 'fun_fireworks',
      name: 'Fireworks',
      emoji: '\u{1F386}',
      price: 80,
      category: GiftCategory.fun,
    ),
    GiftModel(
      id: 'fun_clown',
      name: 'Clown',
      emoji: '\u{1F921}',
      price: 25,
      category: GiftCategory.fun,
    ),
    GiftModel(
      id: 'fun_magic_wand',
      name: 'Magic Wand',
      emoji: '\u{1FA84}',
      price: 75,
      category: GiftCategory.fun,
    ),
    GiftModel(
      id: 'fun_dice',
      name: 'Dice',
      emoji: '\u{1F3B2}',
      price: 30,
      category: GiftCategory.fun,
    ),
    GiftModel(
      id: 'fun_puzzle',
      name: 'Puzzle',
      emoji: '\u{1F9E9}',
      price: 40,
      category: GiftCategory.fun,
    ),
    GiftModel(
      id: 'fun_kite',
      name: 'Kite',
      emoji: '\u{1FA81}',
      price: 35,
      category: GiftCategory.fun,
    ),
    GiftModel(
      id: 'fun_snowman',
      name: 'Snowman',
      emoji: '\u{26C4}',
      price: 45,
      category: GiftCategory.fun,
    ),

    // ─── Special (10) ──────────────────────────────────────────────────
    GiftModel(
      id: 'spc_angel',
      name: 'Angel',
      emoji: '\u{1F607}',
      price: 100,
      category: GiftCategory.special,
    ),
    GiftModel(
      id: 'spc_phoenix',
      name: 'Phoenix',
      emoji: '\u{1F525}',
      price: 150,
      category: GiftCategory.special,
    ),
    GiftModel(
      id: 'spc_lucky_clover',
      name: 'Lucky Clover',
      emoji: '\u{1F340}',
      price: 35,
      category: GiftCategory.special,
    ),
    GiftModel(
      id: 'spc_shooting_star',
      name: 'Shooting Star',
      emoji: '\u{1F320}',
      price: 80,
      category: GiftCategory.special,
    ),
    GiftModel(
      id: 'spc_infinite',
      name: 'Infinite',
      emoji: '\u{267E}\u{FE0F}',
      price: 120,
      category: GiftCategory.special,
    ),
    GiftModel(
      id: 'spc_yin_yang',
      name: 'Yin Yang',
      emoji: '\u{262F}\u{FE0F}',
      price: 90,
      category: GiftCategory.special,
    ),
    GiftModel(
      id: 'spc_peace',
      name: 'Peace',
      emoji: '\u{262E}\u{FE0F}',
      price: 60,
      category: GiftCategory.special,
    ),
    GiftModel(
      id: 'spc_hamsa',
      name: 'Hamsa',
      emoji: '\u{1FAAC}',
      price: 110,
      category: GiftCategory.special,
    ),
    GiftModel(
      id: 'spc_dragon',
      name: 'Dragon',
      emoji: '\u{1F409}',
      price: 200,
      category: GiftCategory.special,
    ),
    GiftModel(
      id: 'spc_lightning',
      name: 'Lightning',
      emoji: '\u{1F329}\u{FE0F}',
      price: 70,
      category: GiftCategory.special,
    ),
  ];

  @override
  String toString() => 'GiftModel(id: $id, name: $name, price: $price)';
}
