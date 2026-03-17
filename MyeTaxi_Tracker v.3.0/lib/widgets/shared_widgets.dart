import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/vehicle.dart';

// ─── STATUS BADGE ─────────────────────────────────────────────────────────────

class StatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.text,
    required this.color,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        border: Border.all(color: color.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─── STAT CARD ────────────────────────────────────────────────────────────────

class StatCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color? accentColor;
  final String? subLabel;

  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.accentColor,
    this.subLabel,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppTheme.accent;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.card,
          border: Border.all(color: AppTheme.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 6),
            Text(value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
              ),
            ),
            Text(label, style: AppTextStyles.label),
            if (subLabel != null) ...[
              const SizedBox(height: 2),
              Text(subLabel!, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── SECTION HEADER ───────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title.toUpperCase(), style: AppTextStyles.label),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ─── APP CARD ─────────────────────────────────────────────────────────────────

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? borderColor;
  final VoidCallback? onTap;
  final double borderWidth;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.borderColor,
    this.onTap,
    this.borderWidth = 1,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.card,
          border: Border.all(
            color: borderColor ?? AppTheme.border,
            width: borderWidth,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: child,
      ),
    );
  }
}

// ─── LIVE DOT ─────────────────────────────────────────────────────────────────

class LiveDot extends StatefulWidget {
  final Color color;
  final double size;

  const LiveDot({super.key, this.color = AppTheme.green, this.size = 8});

  @override
  State<LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<LiveDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withOpacity(_anim.value),
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(0.5 * _anim.value),
              blurRadius: 6,
              spreadRadius: 2,
            )
          ],
        ),
      ),
    );
  }
}

// ─── EXPIRY CHIP ──────────────────────────────────────────────────────────────

class ExpiryChip extends StatelessWidget {
  final DateTime expiry;
  final String label;

  const ExpiryChip({super.key, required this.expiry, required this.label});

  @override
  Widget build(BuildContext context) {
    final days = expiry.difference(DateTime.now()).inDays;
    final Color color;
    if (days < 0) {
      color = AppTheme.red;
    } else if (days <= 14) {
      color = AppTheme.red;
    } else if (days <= 42) {
      color = AppTheme.yellow;
    } else if (days <= 60) {
      color = AppTheme.orange;
    } else {
      color = AppTheme.green;
    }

    final text = days < 0
        ? '$label: EXPIRED'
        : days == 0
            ? '$label: TODAY!'
            : '$label: ${days}d left';

    return StatusBadge(text: text, color: color);
  }
}

// ─── SPEED GAUGE WIDGET ───────────────────────────────────────────────────────

class SpeedGaugeWidget extends StatelessWidget {
  final double speed;
  final double limit;
  final double size;

  const SpeedGaugeWidget({
    super.key,
    required this.speed,
    required this.limit,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    final over = speed > limit;
    final color = over
        ? AppTheme.red
        : speed > limit * 0.85
            ? AppTheme.orange
            : AppTheme.green;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: (speed / (limit * 1.5)).clamp(0, 1),
                backgroundColor: AppTheme.border,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                strokeWidth: 6,
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    speed.toInt().toString(),
                    style: TextStyle(
                      color: color,
                      fontSize: size * 0.25,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                    ),
                  ),
                  Text('km/h', style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: size * 0.12,
                  )),
                ],
              ),
            ],
          ),
        ),
        if (over)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text('⚠ OVER',
              style: TextStyle(
                color: AppTheme.red,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── DRIVER SCORE RING ────────────────────────────────────────────────────────

class DriverScoreRing extends StatelessWidget {
  final double score;
  final double size;

  const DriverScoreRing({super.key, required this.score, this.size = 64});

  @override
  Widget build(BuildContext context) {
    final color = score >= 80
        ? AppTheme.green
        : score >= 60
            ? AppTheme.orange
            : AppTheme.red;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: score / 100,
            backgroundColor: AppTheme.border,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            strokeWidth: 5,
          ),
          Text(
            score.toInt().toString(),
            style: TextStyle(
              color: color,
              fontSize: size * 0.28,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── VEHICLE STATUS COLOR ─────────────────────────────────────────────────────

Color vehicleStatusColor(VehicleStatus status) {
  switch (status) {
    case VehicleStatus.moving: return AppTheme.green;
    case VehicleStatus.idle: return AppTheme.yellow;
    case VehicleStatus.offline: return AppTheme.textMuted;
  }
}

// ─── FORM FIELD WRAPPER ───────────────────────────────────────────────────────

class LabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const LabeledField({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTextStyles.label),
        const SizedBox(height: 6),
        child,
        const SizedBox(height: 14),
      ],
    );
  }
}
