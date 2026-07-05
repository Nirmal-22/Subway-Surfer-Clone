import 'dart:math';
import 'dart:ui';

class Particle {
  Particle({
    required this.pos,
    required this.vel,
    required this.life,
    required this.size,
    required this.color,
    this.gravity = 0,
  }) : maxLife = life;

  Offset pos;
  Offset vel;
  double life;
  final double maxLife;
  final double size;
  final Color color;
  final double gravity;
}

/// Lightweight screen-space particle pool: coin sparkles, crash debris,
/// dust, confetti.
class ParticleSystem {
  final List<Particle> _particles = [];
  final _rng = Random();

  void clear() => _particles.clear();

  void burst(
    Offset at, {
    int count = 10,
    required Color color,
    double speed = 120,
    double life = 0.5,
    double size = 4,
    double gravity = 0,
    double spread = 2 * pi,
    double baseAngle = -pi / 2,
  }) {
    for (var i = 0; i < count; i++) {
      final a = baseAngle + ((_rng.nextDouble() - 0.5) * spread);
      final v = speed * (0.4 + _rng.nextDouble() * 0.8);
      _particles.add(Particle(
        pos: at,
        vel: Offset(cos(a) * v, sin(a) * v),
        life: life * (0.6 + _rng.nextDouble() * 0.6),
        size: size * (0.6 + _rng.nextDouble() * 0.8),
        color: color,
        gravity: gravity,
      ));
    }
  }

  void update(double dt) {
    for (final pt in _particles) {
      pt.pos += pt.vel * dt;
      pt.vel = Offset(pt.vel.dx, pt.vel.dy + pt.gravity * dt);
      pt.life -= dt;
    }
    _particles.removeWhere((pt) => pt.life <= 0);
  }

  void render(Canvas canvas) {
    final paint = Paint();
    for (final pt in _particles) {
      final t = (pt.life / pt.maxLife).clamp(0.0, 1.0);
      paint.color = pt.color.withValues(alpha: t);
      canvas.drawCircle(pt.pos, pt.size * (0.5 + t * 0.5), paint);
    }
  }
}
