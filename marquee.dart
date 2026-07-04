// import 'dart:math';
// import 'package:flutter/material.dart';

// void main() {
//   runApp(const MarqueeApp());
// }

// // ─────────────────────────────────────────────────────────────
// //  APP
// // ─────────────────────────────────────────────────────────────
// class MarqueeApp extends StatelessWidget {
//   const MarqueeApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Diagonal Marquee Gallery',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData.dark().copyWith(
//         scaffoldBackgroundColor: const Color(0xFF0A0A0A),
//       ),
//       home: const GalleryPage(),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────
// //  DATA  — swap Color() cards for real Image widgets later
// // ─────────────────────────────────────────────────────────────
// const List<List<_CardData>> kStripData = [
//   [
//     _CardData(color: Color(0xFF1B2B4B), label: 'Architecture'),
//     _CardData(color: Color(0xFF2B1B3B), label: 'Abstract'),
//     _CardData(color: Color(0xFF1B3B2B), label: 'Nature'),
//     _CardData(color: Color(0xFF3B2B1B), label: 'Urban'),
//     _CardData(color: Color(0xFF1B3B3B), label: 'Minimal'),
//     _CardData(color: Color(0xFF3B1B2B), label: 'Dark'),
//     _CardData(color: Color(0xFF2B3B1B), label: 'Organic'),
//   ],
//   [
//     _CardData(color: Color(0xFF0F2A1A), label: 'Forest'),
//     _CardData(color: Color(0xFF2A0F1A), label: 'Bloom'),
//     _CardData(color: Color(0xFF1A0F2A), label: 'Night'),
//     _CardData(color: Color(0xFF2A1A0F), label: 'Desert'),
//     _CardData(color: Color(0xFF0F1A2A), label: 'Ocean'),
//     _CardData(color: Color(0xFF1A2A0F), label: 'Moss'),
//     _CardData(color: Color(0xFF2A0F2A), label: 'Dusk'),
//   ],
//   [
//     _CardData(color: Color(0xFF3A1515), label: 'Ember'),
//     _CardData(color: Color(0xFF153A15), label: 'Jade'),
//     _CardData(color: Color(0xFF15153A), label: 'Indigo'),
//     _CardData(color: Color(0xFF3A3A15), label: 'Olive'),
//     _CardData(color: Color(0xFF153A3A), label: 'Teal'),
//     _CardData(color: Color(0xFF3A153A), label: 'Violet'),
//     _CardData(color: Color(0xFF3A2515), label: 'Amber'),
//   ],
// ];

// // Immutable data class — const-safe
// class _CardData {
//   final Color color;
//   final String label;
//   const _CardData({required this.color, required this.label});
// }

// // ─────────────────────────────────────────────────────────────
// //  GALLERY PAGE
// // ─────────────────────────────────────────────────────────────
// class GalleryPage extends StatelessWidget {
//   const GalleryPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           // Layer 1 — animated background (isolated repaint)
//           const RepaintBoundary(child: DiagonalMarqueeBackground()),

//           // Layer 2 — static foreground hero (never repaints)
//           const _HeroOverlay(),

//           // Layer 3 — gradient edge fades (static, pointer ignored)
//           const _GradientFades(),
//         ],
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────
// //  HERO OVERLAY  (fully static — never causes a repaint)
// // ─────────────────────────────────────────────────────────────
// class _HeroOverlay extends StatelessWidget {
//   const _HeroOverlay();

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const Text(
//             'GALLERY',
//             style: TextStyle(
//               fontSize: 72,
//               fontWeight: FontWeight.w900,
//               color: Colors.white,
//               letterSpacing: 20,
//               height: 1,
//             ),
//           ),
//           const SizedBox(height: 12),
//           Text(
//             'infinite marquee',
//             style: TextStyle(
//               fontSize: 16,
//               color: Colors.white.withAlpha(100),
//               letterSpacing: 6,
//               fontWeight: FontWeight.w300,
//             ),
//           ),
//           const SizedBox(height: 40),
//           Container(
//             padding:
//                 const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
//             decoration: BoxDecoration(
//               border:
//                   Border.all(color: Colors.white.withAlpha(120)),
//               borderRadius: BorderRadius.circular(40),
//             ),
//             child: const Text(
//               'Explore →',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 14,
//                 letterSpacing: 2,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────
// //  GRADIENT FADES  (static, pointer-transparent)
// // ─────────────────────────────────────────────────────────────
// class _GradientFades extends StatelessWidget {
//   const _GradientFades();

//   @override
//   Widget build(BuildContext context) {
//     const bg = Color(0xFF0A0A0A);
//     return Positioned.fill(
//       child: IgnorePointer(
//         child: Column(
//           children: [
//             Container(
//               height: 140,
//               decoration: const BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                   colors: [bg, Color(0x000A0A0A)],
//                 ),
//               ),
//             ),
//             const Spacer(),
//             Container(
//               height: 140,
//               decoration: const BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.bottomCenter,
//                   end: Alignment.topCenter,
//                   colors: [bg, Color(0x000A0A0A)],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────
// //  DIAGONAL MARQUEE BACKGROUND
// // ─────────────────────────────────────────────────────────────
// class DiagonalMarqueeBackground extends StatefulWidget {
//   const DiagonalMarqueeBackground({super.key});

//   @override
//   State<DiagonalMarqueeBackground> createState() =>
//       _DiagonalMarqueeBackgroundState();
// }

// class _DiagonalMarqueeBackgroundState
//     extends State<DiagonalMarqueeBackground> {
//   // One notifier per strip — hovering strip N only pauses strip N
//   final List<ValueNotifier<bool>> _paused = List.generate(
//     kStripData.length,
//     (_) => ValueNotifier<bool>(false),
//   );

//   @override
//   void dispose() {
//     for (final n in _paused) {
//       n.dispose();
//     }
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Positioned.fill(
//       child: Transform.rotate(
//         angle: -0.18, // ~-10°  →  bottom-left to top-right diagonal
//         child: OverflowBox(
//           maxWidth: double.infinity,
//           maxHeight: double.infinity,
//           child: SizedBox(
//             // Oversized so rotated edges never show gaps
//             width: MediaQuery.of(context).size.width * 1.6,
//             height: MediaQuery.of(context).size.height * 1.6,
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 MarqueeStrip(
//                   items: kStripData[0],
//                   direction: ScrollDirection.left,
//                   speed: 60,
//                   pausedNotifier: _paused[0],
//                 ),
//                 const SizedBox(height: 18),
//                 MarqueeStrip(
//                   items: kStripData[1],
//                   direction: ScrollDirection.right,
//                   speed: 45,
//                   pausedNotifier: _paused[1],
//                 ),
//                 const SizedBox(height: 18),
//                 MarqueeStrip(
//                   items: kStripData[2],
//                   direction: ScrollDirection.left,
//                   speed: 75,
//                   pausedNotifier: _paused[2],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────
// //  SCROLL DIRECTION
// // ─────────────────────────────────────────────────────────────
// enum ScrollDirection { left, right }

// // ─────────────────────────────────────────────────────────────
// //  MARQUEE STRIP
// //
// //  Key smoothness choices:
// //  • RepaintBoundary isolates each strip's repaint from others
// //  • Card row is built ONCE and cached — zero per-frame allocation
// //  • Only Transform.translate changes per frame (GPU compositing)
// //  • AnimationController drives a raw double; no tween overhead
// // ─────────────────────────────────────────────────────────────
// class MarqueeStrip extends StatefulWidget {
//   final List<_CardData> items;
//   final ScrollDirection direction;
//   final double speed; // pixels per second
//   final ValueNotifier<bool> pausedNotifier;

//   const MarqueeStrip({
//     super.key,
//     required this.items,
//     required this.direction,
//     required this.speed,
//     required this.pausedNotifier,
//   });

//   @override
//   State<MarqueeStrip> createState() => _MarqueeStripState();
// }

// class _MarqueeStripState extends State<MarqueeStrip>
//     with SingleTickerProviderStateMixin {
//   // ── Constants ────────────────────────────────────────────
//   static const double kCardW = 220;
//   static const double kCardH = 130;
//   static const double kGap = 14;
//   static const double kUnit = kCardW + kGap;
//   static const int kCopies = 4; // enough copies to fill any screen

//   late AnimationController _ctrl;
//   late double _totalWidth; // width of ONE set of cards
//   late Widget _cachedRow; // built once, reused every frame

//   @override
//   void initState() {
//     super.initState();
//     _totalWidth = widget.items.length * kUnit;

//     // Duration so that exactly one full set scrolls in _totalWidth / speed sec
//     final durationMs = (_totalWidth / widget.speed * 1000).round();
//     _ctrl = AnimationController(
//       vsync: this,
//       duration: Duration(milliseconds: durationMs),
//     )..repeat();

//     widget.pausedNotifier.addListener(_onPauseChanged);

//     // Build the repeated card row ONCE — never rebuilt unless items change
//     _cachedRow = _buildStaticRow();
//   }

//   void _onPauseChanged() {
//     if (!mounted) return;
//     if (widget.pausedNotifier.value) {
//       _ctrl.stop(canceled: false); // freeze in place
//     } else {
//       _ctrl.repeat(); // resume from current position
//     }
//   }

//   @override
//   void dispose() {
//     widget.pausedNotifier.removeListener(_onPauseChanged);
//     _ctrl.dispose();
//     super.dispose();
//   }

//   // Built once at init; each card gets its own RepaintBoundary
//   Widget _buildStaticRow() {
//     final cards = widget.items.map((data) {
//       return Padding(
//         padding: const EdgeInsets.only(right: kGap),
//         child: RepaintBoundary(
//           child: GalleryCard(
//             data: data,
//             width: kCardW,
//             height: kCardH,
//             onHoverChanged: (hovered) {
//               widget.pausedNotifier.value = hovered;
//             },
//           ),
//         ),
//       );
//     }).toList();

//     // kCopies copies side by side → seamless infinite loop
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: List.generate(kCopies, (_) => cards).expand((x) => x).toList(),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: kCardH,
//       // RepaintBoundary: only this strip repaints each frame
//       child: RepaintBoundary(
//         child: AnimatedBuilder(
//           animation: _ctrl,
//           // child is passed in so Flutter doesn't rebuild it — only the
//           // Transform.translate wrapper is re-evaluated each frame
//           child: _cachedRow,
//           builder: (context, child) {
//             // Map controller value [0,1] → pixel offset
//             final double offset = widget.direction == ScrollDirection.left
//                 ? -_ctrl.value * _totalWidth
//                 : -(1.0 - _ctrl.value) * _totalWidth;

//             return OverflowBox(
//               maxWidth: double.infinity,
//               alignment: Alignment.centerLeft,
//               // Transform.translate is handled entirely on the GPU —
//               // no layout recalculation happens here
//               child: Transform.translate(
//                 offset: Offset(offset, 0),
//                 child: child,
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────
// //  GALLERY CARD
// //
// //  Smoothness choices:
// //  • Hover state uses setState only on this widget — not the strip
// //  • No AnimatedContainer in the hot path — decoration is built in
// //    build() which only runs when _hovered changes (not every frame)
// //  • ScaleTransition uses the GPU compositing layer, not layout
// //  • Decorative shapes are pre-computed in initState
// // ─────────────────────────────────────────────────────────────
// class GalleryCard extends StatefulWidget {
//   final _CardData data;
//   final double width;
//   final double height;
//   final ValueChanged<bool> onHoverChanged;

//   const GalleryCard({
//     super.key,
//     required this.data,
//     required this.width,
//     required this.height,
//     required this.onHoverChanged,
//   });

//   @override
//   State<GalleryCard> createState() => _GalleryCardState();
// }

// class _GalleryCardState extends State<GalleryCard>
//     with SingleTickerProviderStateMixin {
//   bool _hovered = false;
//   late List<_Shape> _shapes;

//   // Single controller drives both scale and brightness — cheaper than two
//   late AnimationController _hoverCtrl;
//   late Animation<double> _scaleAnim;

//   @override
//   void initState() {
//     super.initState();

//     // Pre-compute decorative shapes deterministically
//     final rng = Random(widget.data.label.hashCode);
//     _shapes = List.generate(4, (_) {
//       return _Shape(
//         x: rng.nextDouble() * widget.width,
//         y: rng.nextDouble() * widget.height,
//         size: 18 + rng.nextDouble() * 45,
//         opacity: 0.06 + rng.nextDouble() * 0.10,
//         isCircle: rng.nextBool(),
//       );
//     });

//     _hoverCtrl = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 200),
//     );
//     // Scale: 1.0 → 1.05  (GPU composited, zero layout cost)
//     _scaleAnim = Tween<double>(begin: 1.0, end: 1.05).animate(
//       CurvedAnimation(parent: _hoverCtrl, curve: Curves.easeOut),
//     );
//   }

//   @override
//   void dispose() {
//     _hoverCtrl.dispose();
//     super.dispose();
//   }

//   void _handleHover(bool hovered) {
//     if (_hovered == hovered) return; // skip redundant state change
//     setState(() => _hovered = hovered);
//     hovered ? _hoverCtrl.forward() : _hoverCtrl.reverse();
//     widget.onHoverChanged(hovered);
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Border color computed once per hover-change, not per animation frame
//     final borderColor = _hovered
//         ? Colors.white.withAlpha(89)
//         : Colors.white.withAlpha(18);

//     return MouseRegion(
//       cursor: SystemMouseCursors.click,
//       onEnter: (_) => _handleHover(true),
//       onExit: (_) => _handleHover(false),
//       child: ScaleTransition(
//         scale: _scaleAnim,
//         child: Container(
//           width: widget.width,
//           height: widget.height,
//           decoration: BoxDecoration(
//             color: widget.data.color,
//             borderRadius: BorderRadius.circular(14),
//             border: Border.all(color: borderColor, width: 1.0),
//           ),
//           child: ClipRRect(
//             borderRadius: BorderRadius.circular(13),
//             child: Stack(
//               fit: StackFit.expand,
//               children: [
//                 // ── Decorative background shapes ──────────────
//                 ..._shapes.map(
//                   (s) => Positioned(
//                     left: s.x - s.size / 2,
//                     top: s.y - s.size / 2,
//                     child: Container(
//                       width: s.size,
//                       height: s.size,
//                       decoration: BoxDecoration(
//                         color: Colors.white.withAlpha((s.opacity * 255).toInt()),
//                         shape: s.isCircle
//                             ? BoxShape.circle
//                             : BoxShape.rectangle,
//                         borderRadius:
//                             s.isCircle ? null : BorderRadius.circular(4),
//                       ),
//                     ),
//                   ),
//                 ),

//                 // ── Hover glow (opacity flip only, no size change) ─
//                 if (_hovered)
//                   Container(
//                     color: Colors.white.withAlpha(15),
//                   ),

//                 // ── Label ─────────────────────────────────────────
//                 Positioned(
//                   bottom: 10,
//                   left: 12,
//                   child: Text(
//                     widget.data.label.toUpperCase(),
//                     style: TextStyle(
//                       fontSize: 9,
//                       letterSpacing: 2.5,
//                       color: Colors.white
//                           .withAlpha(((_hovered ? 0.9 : 0.4) * 255).toInt()),
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),

//                 // ── Paused pill ───────────────────────────────────
//                 if (_hovered)
//                   Positioned(
//                     top: 10,
//                     right: 10,
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 8, vertical: 4),
//                       decoration: BoxDecoration(
//                         color: Colors.white.withAlpha(36),
//                         borderRadius: BorderRadius.circular(20),
//                         border: Border.all(
//                           color: Colors.white.withAlpha(51),
//                           width: 0.5,
//                         ),
//                       ),
//                       child: const Text(
//                         '⏸  paused',
//                         style: TextStyle(
//                           fontSize: 9,
//                           color: Colors.white,
//                           letterSpacing: 1,
//                         ),
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────
// //  MODELS
// // ─────────────────────────────────────────────────────────────
// class _Shape {
//   final double x, y, size, opacity;
//   final bool isCircle;
//   const _Shape({
//     required this.x,
//     required this.y,
//     required this.size,
//     required this.opacity,
//     required this.isCircle,
//   });
// }