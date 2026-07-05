import 'dart:ui';

/// Maps world coordinates to screen space with a simple perspective
/// projection, giving the pseudo-3D "behind the runner" camera.
///
/// World space:
///  - `lane`: horizontal position in lane units (-1 = left, 0 = center,
///    1 = right lane center). Fractional values are valid (lane changes).
///  - `d`: depth in meters ahead of the player plane. 0 is where the player
///    runs, positive is toward the horizon, small negatives pass the camera.
///  - `h`: height above the ground in meters.
class Projection {
  Projection(Size size)
      : screenW = size.width,
        screenH = size.height;

  final double screenW;
  final double screenH;

  /// How far ahead (meters) entities are spawned / culled.
  static const double maxDepth = 70.0;

  /// Virtual distance between the camera and the player plane.
  static const double camDist = 6.0;

  /// Physical width of one lane in meters (used to convert heights).
  static const double laneWidthMeters = 2.2;

  double get horizonY => screenH * 0.30;
  double get playerPlaneY => screenH * 0.84;
  double get centerX => screenW / 2;

  /// Pixels between adjacent lane centers at the player plane. Capped so
  /// very wide (desktop) windows don't stretch the track.
  double get laneSpacing {
    final byWidth = screenW * 0.27;
    final byHeight = screenH * 0.24;
    return byWidth < byHeight ? byWidth : byHeight;
  }

  double get pxPerMeter => laneSpacing / laneWidthMeters;

  /// Perspective factor: 1.0 at the player plane, approaches 0 toward the
  /// horizon, grows above 1 for things passing behind the player.
  double f(double d) {
    final clamped = d < -4.5 ? -4.5 : d;
    return camDist / (camDist + clamped);
  }

  double screenY(double d, {double h = 0}) {
    final k = f(d);
    return horizonY + (playerPlaneY - horizonY) * k - h * pxPerMeter * k;
  }

  double screenX(double d, double lane) => centerX + lane * laneSpacing * f(d);

  Offset project(double d, double lane, {double h = 0}) =>
      Offset(screenX(d, lane), screenY(d, h: h));

  /// Sprite scale at depth [d] (1.0 at the player plane).
  double scale(double d) => f(d);
}
