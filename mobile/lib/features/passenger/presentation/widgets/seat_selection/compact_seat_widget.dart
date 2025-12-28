import 'dart:convert';
import 'package:flutter/material.dart';

/// Compact seat selection widget matching screenshot design
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
  State<CompactSeatSelectionWidget> createState() => _CompactSeatSelectionWidgetState();
}

class _CompactSeatSelectionWidgetState extends State<CompactSeatSelectionWidget> {
  List<String> _selectedSeats = [];
  Map<String, SeatInfo>? _seatMap;
  
  @override
  void initState() {
    super.initState();
    _parseSeatingLayout();
  }
  
  void _parseSeatingLayout() {
    if (widget.seatingLayoutJson == null || widget.seatingLayoutJson!.isEmpty) {
      return;
    }
    
    try {
      final json = jsonDecode(widget.seatingLayoutJson!);
      final seats = (json['seats'] as List);
      
      final Map<String, SeatInfo> seatMap = {};
      for (var seat in seats) {
        final id = seat['id'] as String;
        final row = seat['row'] as int;
        final position = seat['position'] as String;
        final isFemaleOnly = seat['femaleOnly'] as bool? ?? false;
        
        seatMap[id] = SeatInfo(
          id: id,
          row: row,
          position: position,
          isFemaleOnly: isFemaleOnly,
          isBooked: widget.bookedSeats.contains(id),
        );
      }
      
      setState(() {
        _seatMap = seatMap;
      });
    } catch (e) {
      debugPrint('Error parsing seating layout: $e');
    }
  }
  
  void _toggleSeat(String seatId, SeatInfo seat) {
    if (seat.isBooked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Seat already booked'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      if (_selectedSeats.contains(seatId)) {
        _selectedSeats.remove(seatId);
      } else {
        if (_selectedSeats.length >= widget.maxSelectableSeats) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Max ${widget.maxSelectableSeats} seats allowed'),
              duration: Duration(seconds: 1),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        _selectedSeats.add(seatId);
      }
      
      widget.onSeatsSelected(_selectedSeats);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (_seatMap == null || _seatMap!.isEmpty) {
      return Container(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text(
            'Seat selection not available',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ),
      );
    }
    
    // Group seats by row
    final Map<int, List<SeatInfo>> seatsByRow = {};
    _seatMap!.forEach((id, seat) {
      if (!seatsByRow.containsKey(seat.row)) {
        seatsByRow[seat.row] = [];
      }
      seatsByRow[seat.row]!.add(seat);
    });
    
    final sortedRows = seatsByRow.keys.toList()..sort();
    
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // Seat rows (including first row with driver seat)
          ...sortedRows.map((rowNum) {
            final rowSeats = seatsByRow[rowNum]!;
            
            // Sort seats by position
            rowSeats.sort((a, b) {
              final order = {'left': 0, 'center': 1, 'right': 2};
              return (order[a.position] ?? 0).compareTo(order[b.position] ?? 0);
            });
            
            return Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ...rowSeats.map((seat) => _buildSeat(seat)).toList(),
                  // Add driver seat to the right of first row
                  if (rowNum == 1) _buildDriverSeat(),
                ],
              ),
            );
          }).toList(),
          
          SizedBox(height: 12),
          
          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildLegendItem(Color(0xFF4CAF50), 'Available'),
              _buildLegendItem(Color(0xFF2196F3), 'Selected'),
              _buildLegendItem(Color(0xFFFFCDD2), 'Booked'),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildDriverSeat() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4),
      width: 55,
      height: 65,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[400]!, width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Steering wheel icon
          Icon(
            Icons.radio_button_unchecked,
            size: 24,
            color: Colors.grey[700],
          ),
          SizedBox(height: 2),
          Text(
            'Driver',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSeat(SeatInfo seat) {
    final isSelected = _selectedSeats.contains(seat.id);
    
    Color bgColor;
    Color textColor;
    Color borderColor;
    
    if (seat.isBooked) {
      // Booked - light red/pink
      bgColor = Color(0xFFFFCDD2);
      textColor = Color(0xFFC62828);
      borderColor = Color(0xFFEF9A9A);
    } else if (isSelected) {
      // Selected - blue
      bgColor = Color(0xFF2196F3);
      textColor = Colors.white;
      borderColor = Color(0xFF1976D2);
    } else {
      // Available - green
      bgColor = Color(0xFF4CAF50);
      textColor = Colors.white;
      borderColor = Color(0xFF388E3C);
    }
    
    return GestureDetector(
      onTap: () => _toggleSeat(seat.id, seat),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4),
        width: 55,
        height: 65,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_seat,
              size: 20,
              color: textColor,
            ),
            SizedBox(height: 4),
            Text(
              seat.isBooked ? 'Sold' : '₹${widget.pricePerSeat.toInt()}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Colors.grey[300]!),
          ),
        ),
        SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}

class SeatInfo {
  final String id;
  final int row;
  final String position;
  final bool isFemaleOnly;
  final bool isBooked;
  
  SeatInfo({
    required this.id,
    required this.row,
    required this.position,
    required this.isFemaleOnly,
    required this.isBooked,
  });
}
