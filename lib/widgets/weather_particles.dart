import 'dart:math' as math;
import 'package:flutter/material.dart';

class WeatherParticles extends StatefulWidget {
  final int weatherCode;
  final Widget child;

  const WeatherParticles({
    super.key,
    required this.weatherCode,
    required this.child,
  });

  @override
  State<WeatherParticles> createState() => _WeatherParticlesState();
}

class _WeatherParticlesState extends State<WeatherParticles> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _generateParticles();
  }

  void _generateParticles() {
    _particles.clear();
    final random = math.Random();
    
    // Mưa (code 61-65, 80-82)
    if (widget.weatherCode >= 61 && widget.weatherCode <= 65 || 
        widget.weatherCode >= 80 && widget.weatherCode <= 82) {
      for (int i = 0; i < 50; i++) {
        _particles.add(RainParticle(
          x: random.nextDouble(),
          y: random.nextDouble(),
          speed: 0.3 + random.nextDouble() * 0.4,
        ));
      }
    }
    // Tuyết (code 71-77)
    else if (widget.weatherCode >= 71 && widget.weatherCode <= 77) {
      for (int i = 0; i < 30; i++) {
        _particles.add(SnowParticle(
          x: random.nextDouble(),
          y: random.nextDouble(),
          speed: 0.1 + random.nextDouble() * 0.2,
          size: 2 + random.nextDouble() * 3,
        ));
      }
    }
    // Giông (code >= 95)
    else if (widget.weatherCode >= 95) {
      for (int i = 0; i < 80; i++) {
        _particles.add(RainParticle(
          x: random.nextDouble(),
          y: random.nextDouble(),
          speed: 0.5 + random.nextDouble() * 0.6,
        ));
      }
    }
  }

  @override
  void didUpdateWidget(WeatherParticles oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weatherCode != widget.weatherCode) {
      _generateParticles();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlePainter(
            particles: _particles,
            progress: _controller.value,
            weatherCode: widget.weatherCode,
          ),
          child: widget.child,
        );
      },
    );
  }
}

abstract class Particle {
  double x;
  double y;
  double speed;

  Particle({required this.x, required this.y, required this.speed});

  void update(double delta);
  void paint(Canvas canvas, Size size, int weatherCode);
}

class RainParticle extends Particle {
  RainParticle({required super.x, required super.y, required super.speed});

  @override
  void update(double delta) {
    y += speed * delta;
    if (y > 1.0) {
      y = -0.1;
      x = math.Random().nextDouble();
    }
  }

  @override
  void paint(Canvas canvas, Size size, int weatherCode) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final startX = x * size.width;
    final startY = y * size.height;
    final endX = startX - 5;
    final endY = startY + 15;

    canvas.drawLine(
      Offset(startX, startY),
      Offset(endX, endY),
      paint,
    );
  }
}

class SnowParticle extends Particle {
  final double size;

  SnowParticle({
    required super.x,
    required super.y,
    required super.speed,
    required this.size,
  });

  @override
  void update(double delta) {
    y += speed * delta;
    x += math.sin(y * 10) * 0.01 * delta;
    if (y > 1.0) {
      y = -0.1;
      x = math.Random().nextDouble();
    }
  }

  @override
  void paint(Canvas canvas, Size size, int weatherCode) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(x * size.width, y * size.height),
      this.size,
      paint,
    );
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;
  final int weatherCode;

  ParticlePainter({
    required this.particles,
    required this.progress,
    required this.weatherCode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      particle.update(0.016); // ~60fps
      particle.paint(canvas, size, weatherCode);
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.weatherCode != weatherCode;
  }
}

