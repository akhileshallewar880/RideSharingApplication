import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public widget — same external API
// ─────────────────────────────────────────────────────────────────────────────

class CompactSeatSelectionWidget extends StatefulWidget {
  final String? seatingLayoutJson;
  final List<String> bookedSeats;
  final int maxSelectableSeats;
  final double pricePerSeat;
  final Function(List<String> selectedSeats) onSeatsSelected;

  const CompactSeatSelectionWidget({
    Key? key,
    required this.seatingLayoutJson,
    required this.bookedSeats,
    required this.maxSelectableSeats,
    required this.pricePerSeat,
    required this.onSeatsSelected,
  }) : super(key: key);

  @override
  State<CompactSeatSelectionWidget> createState() =>
      _CompactSeatSelectionWidgetState();
}

class _CompactSeatSelectionWidgetState
    extends State<CompactSeatSelectionWidget> {
  List<String> _selected = [];
  Map<String, SeatInfo>? _seatMap;

  @override
  void initState() {
    super.initState();
    _parse();
  }

  @override
  void didUpdateWidget(CompactSeatSelectionWidget old) {
    super.didUpdateWidget(old);
    if (old.seatingLayoutJson != widget.seatingLayoutJson) _parse();
    if (widget.maxSelectableSeats < old.maxSelectableSeats &&
        _selected.length > widget.maxSelectableSeats) {
      setState(() {
        _selected = _selected.sublist(0, widget.maxSelectableSeats);
        WidgetsBinding.instance
            .addPostFrameCallback((_) => widget.onSeatsSelected(_selected));
      });
    }
  }

  void _parse() {
    if (widget.seatingLayoutJson == null || widget.seatingLayoutJson!.isEmpty) {
      return;
    }
    try {
      final json = jsonDecode(widget.seatingLayoutJson!);
      final seats = json['seats'] as List;
      final Map<String, SeatInfo> map = {};
      for (final s in seats) {
        final id = s['id'] as String;
        map[id] = SeatInfo(
          id: id,
          row: s['row'] as int,
          position: s['position'] as String,
          isBooked: widget.bookedSeats.contains(id),
        );
      }
      setState(() => _seatMap = map);
    } catch (e) {
      debugPrint('Seat parse error: $e');
    }
  }

  void _toggle(SeatInfo seat) {
    if (seat.isBooked) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('This seat is already booked'),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }
    setState(() {
      if (_selected.contains(seat.id)) {
        _selected.remove(seat.id);
      } else {
        if (_selected.length >= widget.maxSelectableSeats) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text('Max ${widget.maxSelectableSeats} seats allowed'),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.orange,
          ));
          return;
        }
        _selected.add(seat.id);
      }
      widget.onSeatsSelected(_selected);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_seatMap == null || _seatMap!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_seat_outlined,
                  size: 40, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'Seat selection not available',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    // Group seats by row
    final Map<int, List<SeatInfo>> byRow = {};
    for (final s in _seatMap!.values) {
      byRow.putIfAbsent(s.row, () => []).add(s);
    }
    final rowNums = byRow.keys.toList()..sort();
    for (final r in rowNums) {
      byRow[r]!.sort((a, b) {
        const o = {'left': 0, 'center': 1, 'right': 2};
        return (o[a.position] ?? 0).compareTo(o[b.position] ?? 0);
      });
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Selection progress bar ──────────────────────────────────────
        _SelectionProgressBar(
          selected: _selected.length,
          max: widget.maxSelectableSeats,
        ),

        const SizedBox(height: 16),

        // ── Car interior (self-sizing, no Expanded) ─────────────────────
        _CarInteriorWidget(
          rowNums: rowNums,
          byRow: byRow,
          selected: _selected,
          onTap: _toggle,
        ),

        // ── Selected seat chips ─────────────────────────────────────────
        if (_selected.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SelectedSeatChips(seatIds: _selected),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Selection progress bar widget
// ─────────────────────────────────────────────────────────────────────────────

class _SelectionProgressBar extends StatelessWidget {
  final int selected;
  final int max;

  const _SelectionProgressBar({required this.selected, required this.max});

  @override
  Widget build(BuildContext context) {
    final complete = selected >= max;
    const brandGreen = Color(0xFF2E7D32);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: complete
            ? brandGreen.withValues(alpha: 0.07)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: complete
              ? brandGreen.withValues(alpha: 0.28)
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          // Icon bubble
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: complete
                  ? brandGreen.withValues(alpha: 0.12)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              complete ? Icons.check_circle_outline : Icons.event_seat_rounded,
              size: 21,
              color: complete ? brandGreen : Colors.grey.shade500,
            ),
          ),
          const SizedBox(width: 12),
          // Label + dots
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  complete
                      ? 'All seats selected!'
                      : 'Select ${max - selected} more '
                          'seat${max - selected > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color:
                        complete ? brandGreen : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 6),
                // Animated pill dots
                Row(
                  children: List.generate(max, (i) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.only(right: 5),
                      width: i < selected ? 20 : 8,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i < selected
                            ? brandGreen
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          // Count badge
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: complete ? brandGreen : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$selected / $max',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: complete ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Selected seat chips row
// ─────────────────────────────────────────────────────────────────────────────

class _SelectedSeatChips extends StatelessWidget {
  final List<String> seatIds;
  const _SelectedSeatChips({required this.seatIds});

  @override
  Widget build(BuildContext context) {
    const brandGreen = Color(0xFF2E7D32);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: seatIds.map((id) {
        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: brandGreen.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: brandGreen.withValues(alpha: 0.35), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.event_seat,
                  size: 12, color: brandGreen),
              const SizedBox(width: 5),
              Text(
                'Seat $id',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: brandGreen,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Car interior — fully responsive, self-sizing (NO Expanded = layout-safe)
// ─────────────────────────────────────────────────────────────────────────────

class _CarInteriorWidget extends StatelessWidget {
  final List<int> rowNums;
  final Map<int, List<SeatInfo>> byRow;
  final List<String> selected;
  final void Function(SeatInfo) onTap;

  const _CarInteriorWidget({
    required this.rowNums,
    required this.byRow,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      // ── Responsive dimensions (compact) ───────────────────────────────
      final availW = constraints.maxWidth.clamp(150.0, 210.0);

      // Exclude row 0 from maxSeats (it's always 1 passenger + 1 driver)
      int maxSeats = 1;
      for (int i = 1; i < rowNums.length; i++) {
        maxSeats = math.max(maxSeats, byRow[rowNums[i]]!.length);
      }
      // Row 0 always has 2 visual seats (passenger + driver), account for that
      maxSeats = math.max(maxSeats, 2);

      const double taper   = 10.0;
      const double sidePad = 10.0;
      const double gap     = 5.0;
      const double aisleW  = 16.0;

      // Seat dimensions — narrow width, tall height
      final seatW = ((availW - taper * 2 - sidePad * 2 - aisleW) -
              (maxSeats - 1) * gap) /
          maxSeats;
      final seatH = seatW * 1.45;

      final scale   = availW / 300.0;
      final frontH  = 82.0 * scale;
      final rowGap  = 7.0  * scale;
      final divBarH = 7.0  * scale;
      final rearPad = 20.0 * scale;
      final bodyR   = 20.0 * scale;

      final innerW = taper * 2 + sidePad * 2 +
          maxSeats * seatW + (maxSeats - 1) * gap + aisleW;

      final numRows  = rowNums.length;
      final seatingH = numRows * seatH
          + (numRows - 1) * (divBarH + rowGap)
          + rearPad;
      final innerH   = frontH + seatingH;

      // ── Build ──────────────────────────────────────────────────────────
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Car body — fixed size SizedBox, no Expanded
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: SizedBox(
                width: innerW,
                height: innerH,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 1. Exterior shell
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _CarShellPainter(
                          taper: taper,
                          radius: bodyR,
                          width: innerW,
                          height: innerH,
                        ),
                      ),
                    ),

                    // 2. Cream interior floor
                    Positioned(
                      left: taper + 3,
                      top: 3,
                      right: taper + 3,
                      bottom: 3,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2EDE3),
                          borderRadius: BorderRadius.circular(bodyR - 4),
                        ),
                      ),
                    ),

                    // 3. Front section — dashboard + steering
                    Positioned(
                      left: taper + 3,
                      top: 3,
                      right: taper + 3,
                      height: frontH - 3,
                      child: ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(bodyR - 4),
                          topRight: Radius.circular(bodyR - 4),
                        ),
                        child: CustomPaint(
                          painter: _DashboardPainter(
                            scale: scale,
                            innerW: innerW - (taper + 3) * 2,
                          ),
                        ),
                      ),
                    ),

                    // 4. Seat rows
                    Positioned(
                      left: taper + sidePad,
                      top: frontH,
                      width: innerW - taper * 2 - sidePad * 2,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          for (int ri = 0; ri < numRows; ri++) ...[
                            if (ri > 0) ...[
                              SizedBox(height: rowGap / 2),
                              _DividerBar(height: divBarH),
                              SizedBox(height: rowGap / 2),
                            ],
                            _buildSeatsRow(
                              byRow[rowNums[ri]]!,
                              seatW,
                              seatH,
                              gap,
                              aisleW,
                              isFirstRow: ri == 0,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Legend
          const Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _LegendChip(
                  color: _SeatColors.available, label: 'Available'),
              _LegendChip(
                  color: _SeatColors.selected, label: 'Selected'),
              _LegendChip(color: _SeatColors.booked, label: 'Booked'),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildSeatsRow(
    List<SeatInfo> seats,
    double seatW,
    double seatH,
    double gap,
    double aisleW, {
    bool isFirstRow = false,
  }) {
    if (seats.isEmpty) return const SizedBox.shrink();

    // First row: all JSON seats on the left, driver seat always on the right
    if (isFirstRow) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ..._seatWidgets(seats, seatW, seatH, gap),
          SizedBox(width: aisleW),
          _DriverSeatTile(width: seatW, height: seatH),
        ],
      );
    }

    // Regular rows: split seats left / right of aisle
    final half  = (seats.length / 2).ceil();
    final left  = seats.sublist(0, half);
    final right = seats.sublist(half);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (left.isNotEmpty) ..._seatWidgets(left, seatW, seatH, gap),
        SizedBox(width: aisleW),
        if (right.isNotEmpty) ..._seatWidgets(right, seatW, seatH, gap),
      ],
    );
  }

  List<Widget> _seatWidgets(
    List<SeatInfo> group,
    double seatW,
    double seatH,
    double gap,
  ) {
    final widgets = <Widget>[];
    for (int i = 0; i < group.length; i++) {
      if (i > 0) widgets.add(SizedBox(width: gap));
      final seat = group[i];
      widgets.add(_SeatTile(
        seat: seat,
        isSelected: selected.contains(seat.id),
        onTap: () => onTap(seat),
        width: seatW,
        height: seatH,
      ));
    }
    return widgets;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Divider bar — seat-back bulkhead between rows
// ─────────────────────────────────────────────────────────────────────────────

class _DividerBar extends StatelessWidget {
  final double height;
  const _DividerBar({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF252525), Color(0xFF3C3C3C), Color(0xFF252525)],
        ),
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashboard painter — windshield + dashboard strip + steering wheel (RHD)
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardPainter extends CustomPainter {
  final double scale;
  final double innerW;

  const _DashboardPainter({required this.scale, required this.innerW});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Windshield glass
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(6 * scale, 4 * scale, w - 12 * scale, h * 0.44),
        Radius.circular(10 * scale),
      ),
      Paint()..color = const Color(0xFF8BAEC4).withValues(alpha: 0.55),
    );

    // Glare highlight on windshield
    canvas.drawLine(
      Offset(8 * scale, 8 * scale),
      Offset(w * 0.35, h * 0.40),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.22)
        ..strokeWidth = 7 * scale
        ..strokeCap = StrokeCap.round,
    );

    // Dashboard strip
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.46, w, h * 0.14),
      Paint()..color = const Color(0xFF3A3A3A),
    );

    // Centre console
    canvas.drawRect(
      Rect.fromLTWH(w / 2 - 7 * scale, h * 0.60, 14 * scale, h * 0.40),
      Paint()..color = const Color(0xFF4A4A4A),
    );

    // Steering wheel — RIGHT side (RHD)
    _drawSteering(canvas, Offset(w * 0.73, h * 0.80), 14.0 * scale);
  }

  void _drawSteering(Canvas canvas, Offset c, double r) {
    final rim = Paint()
      ..color = const Color(0xFF2C2C2C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.30;
    canvas.drawCircle(c, r - rim.strokeWidth / 2, rim);
    canvas.drawCircle(c, r * 0.22, Paint()..color = const Color(0xFF2C2C2C));
    final spoke = Paint()
      ..color = const Color(0xFF2C2C2C)
      ..strokeWidth = r * 0.20
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 3; i++) {
      final a = -math.pi / 2 + i * (2 * math.pi / 3);
      canvas.drawLine(
        Offset(c.dx + math.cos(a) * r * 0.22, c.dy + math.sin(a) * r * 0.22),
        Offset(c.dx + math.cos(a) * r * 0.72, c.dy + math.sin(a) * r * 0.72),
        spoke,
      );
    }
  }

  @override
  bool shouldRepaint(_DashboardPainter old) =>
      old.scale != scale || old.innerW != innerW;
}

// ─────────────────────────────────────────────────────────────────────────────
// Car shell painter — dark MPV body with door mirrors
// ─────────────────────────────────────────────────────────────────────────────

class _CarShellPainter extends CustomPainter {
  final double taper;
  final double radius;
  final double width;
  final double height;

  const _CarShellPainter({
    required this.taper,
    required this.radius,
    required this.width,
    required this.height,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final body = _buildBodyPath(w, h);

    // Drop shadow
    canvas.drawPath(
      body.shift(const Offset(0, 4)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Body fill — dark charcoal
    canvas.drawPath(body, Paint()..color = const Color(0xFF1E1E1E));

    // Subtle highlight on sides
    canvas.drawPath(
      body,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.04)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Door mirrors
    _drawMirror(canvas, Offset(taper - 2, h * 0.22), false);
    _drawMirror(canvas, Offset(w - taper + 2, h * 0.22), true);
  }

  Path _buildBodyPath(double w, double h) {
    final path = Path();
    final t = taper;
    final r = radius;
    path.moveTo(t + r, 0);
    path.quadraticBezierTo(t, 0, t, r);
    path.lineTo(0, h * 0.18);
    path.lineTo(0, h * 0.82);
    path.lineTo(t, h - r);
    path.quadraticBezierTo(t, h, t + r, h);
    path.lineTo(w - t - r, h);
    path.quadraticBezierTo(w - t, h, w - t, h - r);
    path.lineTo(w, h * 0.82);
    path.lineTo(w, h * 0.18);
    path.lineTo(w - t, r);
    path.quadraticBezierTo(w - t, 0, w - t - r, 0);
    path.close();
    return path;
  }

  void _drawMirror(Canvas canvas, Offset anchor, bool right) {
    final p = Path();
    if (!right) {
      p.moveTo(anchor.dx, anchor.dy);
      p.lineTo(anchor.dx - 13, anchor.dy + 5);
      p.lineTo(anchor.dx - 13, anchor.dy + 18);
      p.lineTo(anchor.dx, anchor.dy + 20);
    } else {
      p.moveTo(anchor.dx, anchor.dy);
      p.lineTo(anchor.dx + 13, anchor.dy + 5);
      p.lineTo(anchor.dx + 13, anchor.dy + 18);
      p.lineTo(anchor.dx, anchor.dy + 20);
    }
    p.close();
    canvas.drawPath(p, Paint()..color = const Color(0xFF2C2C2C));
  }

  @override
  bool shouldRepaint(_CarShellPainter old) =>
      old.taper != taper ||
      old.radius != radius ||
      old.width != width ||
      old.height != height;
}

// ─────────────────────────────────────────────────────────────────────────────
// Seat tile — top-view leather seat with ID label + booked overlay
// ─────────────────────────────────────────────────────────────────────────────

class _SeatTile extends StatelessWidget {
  final SeatInfo seat;
  final bool isSelected;
  final VoidCallback onTap;
  final double width;
  final double height;

  const _SeatTile({
    required this.seat,
    required this.isSelected,
    required this.onTap,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: seat.isBooked ? null : onTap,
      child: AnimatedScale(
        scale: isSelected ? 1.08 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Seat shape
              Positioned.fill(
                child: CustomPaint(
                  painter: _TopViewSeatPainter(
                    isBooked: seat.isBooked,
                    isSelected: isSelected,
                  ),
                ),
              ),

              // Seat ID label (lower cushion area)
              Positioned(
                bottom: height * 0.11,
                child: Text(
                  seat.id,
                  style: TextStyle(
                    fontSize: (width * 0.22).clamp(8.0, 12.0),
                    fontWeight: FontWeight.bold,
                    color: seat.isBooked
                        ? Colors.grey.shade400
                        : isSelected
                            ? Colors.white
                            : const Color(0xFF37474F),
                    height: 1,
                  ),
                ),
              ),

              // X overlay for booked seats
              if (seat.isBooked)
                Positioned.fill(
                  child: Center(
                    child: Icon(
                      Icons.close_rounded,
                      size: width * 0.36,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Driver seat tile — always blocked, dark charcoal, labeled "Driver"
// ─────────────────────────────────────────────────────────────────────────────

class _DriverSeatTile extends StatelessWidget {
  final double width;
  final double height;

  const _DriverSeatTile({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Seat shape with driver colors
          const Positioned.fill(
            child: CustomPaint(painter: _DriverSeatPainter()),
          ),
          // Steering wheel icon in upper cushion area
          Positioned(
            top: height * 0.32,
            child: Icon(
              Icons.settings_input_svideo,
              size: (width * 0.30).clamp(10.0, 18.0),
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
          // "Driver" label at bottom of cushion
          Positioned(
            bottom: height * 0.11,
            child: Text(
              'Driver',
              style: TextStyle(
                fontSize: (width * 0.18).clamp(7.0, 10.0),
                fontWeight: FontWeight.bold,
                color: Colors.white.withValues(alpha: 0.75),
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverSeatPainter extends CustomPainter {
  const _DriverSeatPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    const bodyColor    = Color(0xFF37474F); // Dark blue-grey
    const headColor    = Color(0xFF263238); // Deeper blue-grey
    const outlineColor = Color(0xFF546E7A);

    final fill   = Paint()..color = bodyColor;
    final border = Paint()
      ..color       = outlineColor
      ..style       = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, w * 0.04)
      ..strokeCap   = StrokeCap.round
      ..strokeJoin  = StrokeJoin.round;

    final headH = h * 0.20;
    final gapH  = h * 0.07;
    final cushY = headH + gapH;
    final cushH = h - cushY;
    final headW = w * 0.68;
    final headX = (w - headW) / 2;
    final armW  = w * 0.09;
    final armH  = cushH * 0.42;
    final armY  = cushY + cushH * 0.10;
    final cr    = w * 0.10;

    // Headrest
    final headRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(headX, 0, headW, headH),
      Radius.circular(cr),
    );
    canvas.drawRRect(headRect, Paint()..color = headColor);
    canvas.drawRRect(headRect, border);

    // Left armrest
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-armW, armY, armW + cr, armH),
        Radius.circular(math.max(2, cr * 0.5)),
      ),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-armW, armY, armW + cr, armH),
        Radius.circular(math.max(2, cr * 0.5)),
      ),
      border,
    );

    // Right armrest
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w - cr, armY, armW + cr, armH),
        Radius.circular(math.max(2, cr * 0.5)),
      ),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w - cr, armY, armW + cr, armH),
        Radius.circular(math.max(2, cr * 0.5)),
      ),
      border,
    );

    // Main cushion
    final cushRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, cushY, w, cushH),
      Radius.circular(cr),
    );
    canvas.drawRRect(cushRect, fill);
    canvas.drawRRect(cushRect, border);

    // Gloss highlight
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.12, cushY + cushH * 0.08, w * 0.28, cushH * 0.28),
        Radius.circular(cr * 0.8),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.08),
    );
  }

  @override
  bool shouldRepaint(_DriverSeatPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Seat CustomPainter — top-view leather seat (headrest + armrests + cushion)
// ─────────────────────────────────────────────────────────────────────────────

class _TopViewSeatPainter extends CustomPainter {
  final bool isBooked;
  final bool isSelected;

  const _TopViewSeatPainter({required this.isBooked, required this.isSelected});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Colour palette ────────────────────────────────────────────────────
    final Color bodyColor;
    final Color headColor;
    final Color outlineColor;

    if (isBooked) {
      bodyColor    = _SeatColors.booked;
      headColor    = _SeatColors.bookedDark;
      outlineColor = const Color(0xFFAAAAAA);
    } else if (isSelected) {
      bodyColor    = _SeatColors.selected;
      headColor    = _SeatColors.selectedDark;
      outlineColor = const Color(0xFF1B5E20);
    } else {
      bodyColor    = _SeatColors.available;
      headColor    = _SeatColors.availableDark;
      outlineColor = const Color(0xFF8FA892);
    }

    final fill   = Paint()..color = bodyColor;
    final border = Paint()
      ..color       = outlineColor
      ..style       = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, w * 0.04)
      ..strokeCap   = StrokeCap.round
      ..strokeJoin  = StrokeJoin.round;

    // ── Proportional layout ──────────────────────────────────────────────
    final headH = h * 0.20;
    final gapH  = h * 0.07;
    final cushY = headH + gapH;
    final cushH = h - cushY;
    final headW = w * 0.68;
    final headX = (w - headW) / 2;
    final armW  = w * 0.09;
    final armH  = cushH * 0.42;
    final armY  = cushY + cushH * 0.10;
    final cr    = w * 0.10;

    // ── 1. Headrest ───────────────────────────────────────────────────────
    final headRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(headX, 0, headW, headH),
      Radius.circular(cr),
    );
    canvas.drawRRect(headRect, Paint()..color = headColor);
    canvas.drawRRect(headRect, border);

    // ── 2. Left armrest ───────────────────────────────────────────────────
    final leftArm = RRect.fromRectAndRadius(
      Rect.fromLTWH(-armW, armY, armW + cr, armH),
      Radius.circular(math.max(2, cr * 0.5)),
    );
    canvas.drawRRect(leftArm, fill);
    canvas.drawRRect(leftArm, border);

    // ── 3. Right armrest ──────────────────────────────────────────────────
    final rightArm = RRect.fromRectAndRadius(
      Rect.fromLTWH(w - cr, armY, armW + cr, armH),
      Radius.circular(math.max(2, cr * 0.5)),
    );
    canvas.drawRRect(rightArm, fill);
    canvas.drawRRect(rightArm, border);

    // ── 4. Main cushion ───────────────────────────────────────────────────
    final cushRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, cushY, w, cushH),
      Radius.circular(cr),
    );
    canvas.drawRRect(cushRect, fill);
    canvas.drawRRect(cushRect, border);

    // ── 5. Centre crease ──────────────────────────────────────────────────
    canvas.drawLine(
      Offset(w / 2, cushY + cushH * 0.15),
      Offset(w / 2, cushY + cushH * 0.78),
      Paint()
        ..color = outlineColor.withValues(alpha: 0.18)
        ..strokeWidth = math.max(0.8, w * 0.025),
    );

    // ── 6. Gloss highlight ────────────────────────────────────────────────
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          w * 0.12, cushY + cushH * 0.08, w * 0.28, cushH * 0.30),
        Radius.circular(cr * 0.8),
      ),
      Paint()..color = Colors.white.withValues(alpha: isSelected ? 0.18 : 0.12),
    );
  }

  @override
  bool shouldRepaint(_TopViewSeatPainter old) =>
      old.isBooked != isBooked || old.isSelected != isSelected;
}

// ─────────────────────────────────────────────────────────────────────────────
// Colour palette — app-themed (Forest Green brand)
// ─────────────────────────────────────────────────────────────────────────────

class _SeatColors {
  // Available — pale green-grey, neutral and clean
  static const available     = Color(0xFFECF0EC);
  static const availableDark = Color(0xFFD0DADA);

  // Selected — app primary forest green
  static const selected      = Color(0xFF2E7D32);
  static const selectedDark  = Color(0xFF1B5E20);

  // Booked — light grey (clearly unavailable)
  static const booked        = Color(0xFFE8E8E8);
  static const bookedDark    = Color(0xFFBBBBBB);
}

// ─────────────────────────────────────────────────────────────────────────────
// Legend chip — pill-style with colour swatch
// ─────────────────────────────────────────────────────────────────────────────

class _LegendChip extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendChip({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = color.computeLuminance() < 0.25;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.45 : 0.30),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────────────────────

class SeatInfo {
  final String id;
  final int    row;
  final String position;
  final bool   isBooked;

  const SeatInfo({
    required this.id,
    required this.row,
    required this.position,
    required this.isBooked,
  });
}
