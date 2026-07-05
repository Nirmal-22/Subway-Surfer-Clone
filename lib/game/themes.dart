import 'dart:ui';

/// World color themes. The run cycles day → dusk → night as distance grows,
/// blending smoothly between segments.
class WorldTheme {
  const WorldTheme({
    required this.skyTop,
    required this.skyBottom,
    required this.ground,
    required this.track,
    required this.rail,
    required this.tie,
    required this.building,
    required this.buildingFar,
    required this.sun,
    required this.nightness,
  });

  final Color skyTop;
  final Color skyBottom;
  final Color ground;
  final Color track;
  final Color rail;
  final Color tie;
  final Color building;
  final Color buildingFar;
  final Color sun;

  /// 0 = full day, 1 = full night. Drives stars / lit windows / headlights.
  final double nightness;

  static const day = WorldTheme(
    skyTop: Color(0xFF4FA9E8),
    skyBottom: Color(0xFFBFE3F7),
    ground: Color(0xFF8A9BA8),
    track: Color(0xFF6E7B86),
    rail: Color(0xFF3D464E),
    tie: Color(0xFF57636D),
    building: Color(0xFFB0885E),
    buildingFar: Color(0xFF9FB4C4),
    sun: Color(0xFFFFF3B0),
    nightness: 0,
  );

  static const dusk = WorldTheme(
    skyTop: Color(0xFF35386E),
    skyBottom: Color(0xFFF2905B),
    ground: Color(0xFF6E6675),
    track: Color(0xFF57505F),
    rail: Color(0xFF2E2A36),
    tie: Color(0xFF453F4E),
    building: Color(0xFF6F5566),
    buildingFar: Color(0xFF7A6E8A),
    sun: Color(0xFFFFB25E),
    nightness: 0.45,
  );

  static const night = WorldTheme(
    skyTop: Color(0xFF0A1030),
    skyBottom: Color(0xFF23315E),
    ground: Color(0xFF39415A),
    track: Color(0xFF2C3348),
    rail: Color(0xFF161B29),
    tie: Color(0xFF242B3D),
    building: Color(0xFF2E3450),
    buildingFar: Color(0xFF262C44),
    sun: Color(0xFFE8ECF7),
    nightness: 1,
  );

  static const cycle = [day, dusk, night];

  static WorldTheme lerp(WorldTheme a, WorldTheme b, double t) {
    Color c(Color x, Color y) => Color.lerp(x, y, t)!;
    return WorldTheme(
      skyTop: c(a.skyTop, b.skyTop),
      skyBottom: c(a.skyBottom, b.skyBottom),
      ground: c(a.ground, b.ground),
      track: c(a.track, b.track),
      rail: c(a.rail, b.rail),
      tie: c(a.tie, b.tie),
      building: c(a.building, b.building),
      buildingFar: c(a.buildingFar, b.buildingFar),
      sun: c(a.sun, b.sun),
      nightness: a.nightness + (b.nightness - a.nightness) * t,
    );
  }

  /// Theme for a given distance: 1200 m per segment, blending over the
  /// final 150 m of each segment.
  static WorldTheme forDistance(double distance) {
    const segment = 1200.0;
    const blend = 150.0;
    final idx = (distance / segment).floor();
    final cur = cycle[idx % cycle.length];
    final next = cycle[(idx + 1) % cycle.length];
    final into = distance - idx * segment;
    if (into < segment - blend) return cur;
    return lerp(cur, next, (into - (segment - blend)) / blend);
  }
}

/// Playable character color schemes, unlockable with coins in the shop.
class CharacterSkin {
  const CharacterSkin({
    required this.id,
    required this.name,
    required this.price,
    required this.hoodie,
    required this.hoodieDark,
    required this.pants,
    required this.skin,
    required this.hair,
    required this.accent,
  });

  final String id;
  final String name;
  final int price;
  final Color hoodie;
  final Color hoodieDark;
  final Color pants;
  final Color skin;
  final Color hair;
  final Color accent;

  static const all = [
    CharacterSkin(
      id: 'dash',
      name: 'Dash',
      price: 0,
      hoodie: Color(0xFFE53935),
      hoodieDark: Color(0xFFB71C1C),
      pants: Color(0xFF283593),
      skin: Color(0xFFE8B98A),
      hair: Color(0xFF4E342E),
      accent: Color(0xFFFFEB3B),
    ),
    CharacterSkin(
      id: 'frost',
      name: 'Frost',
      price: 500,
      hoodie: Color(0xFF29B6F6),
      hoodieDark: Color(0xFF0277BD),
      pants: Color(0xFF37474F),
      skin: Color(0xFFF2D0B3),
      hair: Color(0xFFECEFF1),
      accent: Color(0xFF80DEEA),
    ),
    CharacterSkin(
      id: 'neon',
      name: 'Neon',
      price: 1500,
      hoodie: Color(0xFF66BB6A),
      hoodieDark: Color(0xFF2E7D32),
      pants: Color(0xFF6A1B9A),
      skin: Color(0xFFC68958),
      hair: Color(0xFF1B5E20),
      accent: Color(0xFFEA80FC),
    ),
    CharacterSkin(
      id: 'blaze',
      name: 'Blaze',
      price: 3000,
      hoodie: Color(0xFFFF7043),
      hoodieDark: Color(0xFFBF360C),
      pants: Color(0xFF212121),
      skin: Color(0xFF9C6B44),
      hair: Color(0xFF111111),
      accent: Color(0xFFFFC400),
    ),
  ];

  static CharacterSkin byId(String id) =>
      all.firstWhere((s) => s.id == id, orElse: () => all.first);
}
