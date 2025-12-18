/// Project Neo - Squircle Avatar
///
/// Squircle-shaped avatar widget for community logos.
library;

import 'package:flutter/material.dart';
import '../theme/neo_theme.dart';

/// Squircle clip path for smooth-cornered squares
class SquircleBorder extends ShapeBorder {
  final double radius;
  
  const SquircleBorder({this.radius = 0.22});
  
  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;
  
  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return getOuterPath(rect, textDirection: textDirection);
  }
  
  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return _getSquirclePath(rect, radius);
  }
  
  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}
  
  @override
  ShapeBorder scale(double t) => SquircleBorder(radius: radius * t);
  
  static Path _getSquirclePath(Rect rect, double radius) {
    final path = Path();
    final width = rect.width;
    final r = width * radius;
    
    path.moveTo(rect.left + r, rect.top);
    path.lineTo(rect.right - r, rect.top);
    path.cubicTo(
      rect.right, rect.top,
      rect.right, rect.top,
      rect.right, rect.top + r,
    );
    path.lineTo(rect.right, rect.bottom - r);
    path.cubicTo(
      rect.right, rect.bottom,
      rect.right, rect.bottom,
      rect.right - r, rect.bottom,
    );
    path.lineTo(rect.left + r, rect.bottom);
    path.cubicTo(
      rect.left, rect.bottom,
      rect.left, rect.bottom,
      rect.left, rect.bottom - r,
    );
    path.lineTo(rect.left, rect.top + r);
    path.cubicTo(
      rect.left, rect.top,
      rect.left, rect.top,
      rect.left + r, rect.top,
    );
    path.close();
    
    return path;
  }
}

/// Squircle avatar widget
class SquircleAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final Widget? child;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  
  const SquircleAvatar({
    super.key,
    this.imageUrl,
    this.size = 60,
    this.child,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: ShapeDecoration(
        shape: SquircleBorder(radius: 0.22),
        color: backgroundColor ?? NeoColors.card,
      ),
      child: ClipPath(
        clipper: _SquircleClipper(radius: 0.22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null)
              Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholder(),
              )
            else if (child != null)
              child!
            else
              _buildPlaceholder(),
            
            // Border
            if (borderWidth > 0)
              Container(
                decoration: ShapeDecoration(
                  shape: SquircleBorder(radius: 0.22),
                  color: Colors.transparent,
                ),
                foregroundDecoration: ShapeDecoration(
                  shape: SquircleBorder(radius: 0.22),
                  color: Colors.transparent,
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPlaceholder() {
    return Container(
      color: NeoColors.card,
      child: Icon(
        Icons.groups_rounded,
        size: size * 0.5,
        color: NeoColors.textTertiary,
      ),
    );
  }
}

class _SquircleClipper extends CustomClipper<Path> {
  final double radius;
  
  _SquircleClipper({this.radius = 0.22});
  
  @override
  Path getClip(Size size) {
    return SquircleBorder._getSquirclePath(
      Rect.fromLTWH(0, 0, size.width, size.height),
      radius,
    );
  }
  
  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
