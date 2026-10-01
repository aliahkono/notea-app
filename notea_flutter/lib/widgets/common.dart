import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../controllers/pet_controller.dart';
import '../theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Shadows (Figma effect styles "Notea/Soft shadow" & "Notea/Float shadow")
// ---------------------------------------------------------------------------
List<BoxShadow> softShadow([double opacity = 0.10, double blur = 18, Offset offset = const Offset(0, 6)]) =>
    [BoxShadow(color: Color.fromRGBO(107, 84, 61, opacity), blurRadius: blur, offset: offset)];

const List<BoxShadow> floatShadow = [
  BoxShadow(color: Color.fromRGBO(92, 64, 128, 0.16), blurRadius: 28, offset: Offset(0, 10)),
];

// ---------------------------------------------------------------------------
// Basic building blocks
// ---------------------------------------------------------------------------

/// Rounded surface card.
class NCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool shadow;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Gradient? gradient;
  final BoxBorder? border;

  const NCard({
    super.key,
    required this.child,
    this.color = NC.surface,
    this.padding = const EdgeInsets.all(16),
    this.radius = 24,
    this.shadow = true,
    this.onTap,
    this.onLongPress,
    this.gradient,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);
    return Container(
      decoration: BoxDecoration(
        color: gradient == null ? color : null,
        gradient: gradient,
        borderRadius: br,
        border: border,
        boxShadow: shadow ? softShadow() : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: br,
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Small square-ish icon bubble used on tiles and lists.
class IconBubble extends StatelessWidget {
  final IconData icon;
  final Accent accent;
  final double size;
  final double iconSize;
  final double radius;
  final Color? background;

  const IconBubble(this.icon, this.accent,
      {super.key, this.size = 42, this.iconSize = 24, this.radius = 14, this.background});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background ?? accent.soft, borderRadius: BorderRadius.circular(radius)),
      child: Icon(icon, color: accent.strong, size: iconSize),
    );
  }
}

class NChip extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback? onTap;
  final IconData? icon;

  const NChip(this.label,
      {super.key, this.background = NC.plumSoft, this.foreground = NC.plum, this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 14, color: foreground), const SizedBox(width: 4)],
              Text(label, style: NText.caption.copyWith(color: foreground)),
            ],
          ),
        ),
      ),
    );
  }
}

enum NButtonStyle { primary, soft, light }

class NButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final NButtonStyle style;
  final bool expand;
  final Color? color;

  const NButton(this.label,
      {super.key, this.onPressed, this.icon, this.style = NButtonStyle.primary, this.expand = true, this.color});

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final enabled = onPressed != null;
    Color bg, fg;
    switch (style) {
      case NButtonStyle.primary:
        bg = color ?? pal.primary;
        fg = NC.onPrimary;
        break;
      case NButtonStyle.soft:
        bg = color != null ? fade(color!, 0.15) : pal.primarySoft;
        fg = color ?? pal.primary;
        break;
      case NButtonStyle.light:
        bg = NC.surface;
        fg = NC.ink;
        break;
    }
    if (!enabled) {
      bg = NC.line;
      fg = NC.muted;
    }
    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[Icon(icon, color: fg, size: 22), const SizedBox(width: 8)],
        Flexible(
          child: Text(label,
              overflow: TextOverflow.ellipsis, style: NText.headline.copyWith(color: fg)),
        ),
      ],
    );
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: style == NButtonStyle.light ? Border.all(color: NC.line, width: 1.5) : null,
        boxShadow: style == NButtonStyle.primary && enabled
            ? [BoxShadow(color: fade(bg, 0.28), blurRadius: 16, offset: const Offset(0, 6))]
            : null,
      ),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(26),
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Round white icon button with soft shadow (settings, calendar, controls...).
class CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final Color background;
  final Color foreground;
  final bool shadow;

  const CircleIconButton(this.icon,
      {super.key,
      this.onTap,
      this.size = 44,
      this.iconSize = 22,
      this.background = NC.surface,
      this.foreground = NC.ink,
      this.shadow = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: shadow ? softShadow() : null),
      child: Material(
        color: background,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Icon(icon, size: iconSize, color: foreground),
        ),
      ),
    );
  }
}

class NProgress extends StatelessWidget {
  final double value;
  final Color color;
  final Color track;
  final double height;
  const NProgress(this.value, {super.key, this.color = NC.plum, this.track = NC.sand, this.height = 8});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: track)),
            FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0).toDouble(),
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(height / 2)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Title ........ action" row.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionHeader(this.title, {super.key, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: NText.headline)),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(action!, style: NText.caption.copyWith(color: context.pal.primary)),
          ),
      ],
    );
  }
}

/// Big screen title with optional subtitle and trailing widget.
class ScreenTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final String? overline;
  const ScreenTitle(this.title, {super.key, this.subtitle, this.trailing, this.overline});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (overline != null) Text(overline!, style: NText.caption),
              Text(title, style: NText.display),
              if (subtitle != null) Text(subtitle!, style: NText.muted),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Floating "+" button.
class AddFab extends StatelessWidget {
  final VoidCallback onPressed;
  final String heroTag;
  const AddFab({super.key, required this.onPressed, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(shape: BoxShape.circle, boxShadow: floatShadow),
      child: FloatingActionButton(
        heroTag: heroTag,
        elevation: 0,
        backgroundColor: context.pal.primary,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        onPressed: onPressed,
        child: const Icon(Icons.add_rounded, size: 30),
      ),
    );
  }
}

/// "‹ Study" style back header.
class BackHeader extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final double fontSize;
  final List<Widget> trailing;

  const BackHeader({
    super.key,
    this.label = 'Back',
    this.onTap,
    this.fontSize = 17,
    this.trailing = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap ?? () => Navigator.of(context).maybePop(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 10, 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.chevron_left_rounded, size: 28, color: NC.ink),
                  Text(label, style: NText.headline.copyWith(fontSize: fontSize)),
                ],
              ),
            ),
          ),
          const Spacer(),
          ...trailing,
        ],
      ),
    );
  }
}

/// Modal page with a title bar and "Cancel"/"Done" actions.
class SheetScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final String? leadingLabel;
  final VoidCallback? onLeading;
  final String? trailingLabel;
  final VoidCallback? onTrailing;
  final Color? background;

  const SheetScaffold({
    super.key,
    required this.title,
    required this.body,
    this.leadingLabel,
    this.onLeading,
    this.trailingLabel,
    this.onTrailing,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final bg = background ?? context.pal.bg;
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leadingWidth: 110,
        title: Text(title, style: NText.headline),
        leading: leadingLabel == null
            ? null
            : TextButton(
                onPressed: onLeading ?? () => Navigator.of(context).pop(),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.chevron_left_rounded, color: NC.ink),
                  Flexible(
                    child: Text(leadingLabel!,
                        overflow: TextOverflow.ellipsis, style: NText.body.copyWith(fontWeight: FontWeight.w700)),
                  ),
                ]),
              ),
        actions: [
          if (trailingLabel != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: onTrailing,
                child: Text(trailingLabel!,
                    style: NText.headline.copyWith(color: onTrailing == null ? NC.muted : context.pal.primary)),
              ),
            ),
        ],
      ),
      body: SafeArea(child: body),
    );
  }
}

/// Text field styled like the Figma inputs (white pill / sand box).
InputDecoration nInput(String hint, {IconData? icon, Color fill = NC.surface, double radius = 18}) =>
    InputDecoration(
      hintText: hint,
      hintStyle: NText.body.copyWith(color: NC.muted, fontWeight: FontWeight.w500),
      prefixIcon: icon == null ? null : Icon(icon, color: NC.muted, size: 22),
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(radius), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius), borderSide: const BorderSide(color: NC.line)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius), borderSide: const BorderSide(color: NC.plum, width: 1.5)),
    );

/// Push a full screen page.
Future<T?> pushPage<T>(BuildContext context, Widget page, {bool fullscreenDialog = false}) {
  return Navigator.of(context).push<T>(
    MaterialPageRoute(builder: (_) => page, fullscreenDialog: fullscreenDialog),
  );
}

/// Show the pet's reaction as a floating snackbar.
void celebrate(BuildContext context, PetEvent? event) {
  if (event == null) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(event.levelUp ? Icons.emoji_events_rounded : Icons.pets_rounded, color: NC.butter),
          const SizedBox(width: 10),
          Expanded(child: Text(event.message, style: NText.body.copyWith(color: Colors.white))),
        ],
      ),
      duration: const Duration(seconds: 2),
    ));
}

/// Heart shape from ProfileTabView.swift.
class HeartPath {
  static Path build(Size size) {
    final w = size.width;
    final h = size.height;
    final p = Path();
    p.moveTo(w / 2, h);
    p.cubicTo(w / 4, h, 0, h * 3 / 4, 0, h / 4);
    p.arcTo(Rect.fromCircle(center: Offset(w / 4, h / 4), radius: w / 4), math.pi, math.pi, false);
    p.arcTo(Rect.fromCircle(center: Offset(w * 3 / 4, h / 4), radius: w / 4), math.pi, math.pi, false);
    p.cubicTo(w, h * 3 / 4, w * 3 / 4, h, w / 2, h);
    p.close();
    return p;
  }
}

class HeartClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => HeartPath.build(size);
  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class HeartPainter extends CustomPainter {
  final Color fill;
  final Color stroke;
  final double strokeWidth;
  HeartPainter({required this.fill, required this.stroke, this.strokeWidth = 4});

  @override
  void paint(Canvas canvas, Size size) {
    final path = HeartPath.build(size);
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
        path,
        Paint()
          ..color = stroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth);
  }

  @override
  bool shouldRepaint(covariant HeartPainter old) => old.fill != fill || old.stroke != stroke;
}

/// Confirm dialog with Cancel + destructive action.
Future<bool> confirmDialog(BuildContext context,
    {required String title, required String message, String confirm = 'Delete'}) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: NC.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(title, style: NText.title),
      content: Text(message, style: NText.muted),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirm, style: const TextStyle(color: NC.red, fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
  return res ?? false;
}

/// "Coming soon" page.
class ComingSoonPage extends StatelessWidget {
  final String name;
  const ComingSoonPage({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    final clean = name.replaceAll('\n', ' ');
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const BackHeader(label: 'Back'),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/pet/cat_writing.png', height: 140),
                      const SizedBox(height: 20),
                      const Text('Coming soon!', style: NText.title),
                      const SizedBox(height: 8),
                      Text('$clean is still being built. Kenma is working on it 🐾',
                          textAlign: TextAlign.center, style: NText.muted),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
