import 'dart:convert';
import 'package:flutter/material.dart';

/// Seat status enum
enum SeatStatus {
  available,
  selected,
  booked,
  female, // Reserved for female passengers
}

/// Seat model
class SeatModel {
  final String id;
  final int row;
  final String position; // 'left', 'right', 'center', 'aisle'
  SeatStatus status;
  
  SeatModel({
    required this.id,
    required this.row,
    required this.position,
    this.status = SeatStatus.available,
  });
  
  factory SeatModel.fromJson(Map<String, dynamic> json, List<String> bookedSeats) {
    final id = json['id'] as String;
    final status = bookedSeats.contains(id) 
        ? SeatStatus.booked 
        : SeatStatus.available;
    
    return SeatModel(
      id: id,
      row: json['row'] as int,
      position: json['position'] as String,
      status: status,
    );
  }
}

/// Seating layout configuration
class SeatingLayoutConfig {
  final String layoutType; // "2-3", "2-2-3", "2-2-2-2-2-2-1", etc.
  final int rows;
  final List<SeatModel> seats;
  
  SeatingLayoutConfig({
    required this.layoutType,
    required this.rows,
    required this.seats,
  });
  
  factory SeatingLayoutConfig.fromJson(Map<String, dynamic> json, List<String> bookedSeats) {
    final seatsList = (json['seats'] as List)
        .map((s) => SeatModel.fromJson(s as Map<String, dynamic>, bookedSeats))
        .toList();
    
    return SeatingLayoutConfig(
      layoutType: json['layout'] as String,
      rows: json['rows'] as int,
      seats: seatsList,
    );
  }
}

/// Main seat selection widget
class SeatSelectionWidget extends StatefulWidget {
  final String? seatingLayoutJson;
  final List<String> bookedSeats;
  final int maxSelectableSeats;
  final Function(List<String> selectedSeats) onSeatsSelected;
  
  const SeatSelectionWidget({
    Key? key,
    required this.seatingLayoutJson,
    required this.bookedSeats,
    required this.maxSelectableSeats,
    required this.onSeatsSelected,
  }) : super(key: key);

  @override
  State<SeatSelectionWidget> createState() => _SeatSelectionWidgetState();
}

class _SeatSelectionWidgetState extends State<SeatSelectionWidget> {
  List<String> _selectedSeats = [];
  SeatingLayoutConfig? _layoutConfig;
  
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
      setState(() {
        _layoutConfig = SeatingLayoutConfig.fromJson(
          json as Map<String, dynamic>,
          widget.bookedSeats,
        );
      });
    } catch (e) {
      debugPrint('Error parsing seating layout: $e');
    }
  }
  
  void _toggleSeat(SeatModel seat) {
    if (seat.status == SeatStatus.booked) {
      // Cannot select booked seats
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This seat is already booked'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      if (seat.status == SeatStatus.selected) {
        // Deselect
        seat.status = SeatStatus.available;
        _selectedSeats.remove(seat.id);
      } else {
        // Select
        if (_selectedSeats.length >= widget.maxSelectableSeats) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Maximum ${widget.maxSelectableSeats} seats can be selected'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        
        seat.status = SeatStatus.selected;
        _selectedSeats.add(seat.id);
      }
      
      widget.onSeatsSelected(_selectedSeats);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (_layoutConfig == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            'Seat selection not available for this vehicle',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                'Select Your Seats',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_selectedSeats.length}/${widget.maxSelectableSeats} seats selected',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        
        // Legend
        _buildLegend(),
        
        const SizedBox(height: 20),
        
        // Seat map
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildSeatMap(),
          ),
        ),
      ],
    );
  }
  
  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLegendItem(Colors.grey[300]!, 'Available'),
          _buildLegendItem(Colors.green, 'Selected'),
          _buildLegendItem(Colors.red, 'Booked'),
        ],
      ),
    );
  }
  
  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey[400]!, width: 1),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
  
  Widget _buildSeatMap() {
    // Group seats by row
    final Map<int, List<SeatModel>> seatsByRow = {};
    for (var seat in _layoutConfig!.seats) {
      if (!seatsByRow.containsKey(seat.row)) {
        seatsByRow[seat.row] = [];
      }
      seatsByRow[seat.row]!.add(seat);
    }
    
    // Sort rows
    final sortedRows = seatsByRow.keys.toList()..sort();
    
    return Column(
      children: [
        // Driver indicator
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.airlines, size: 20),
              SizedBox(width: 8),
              Text(
                'Driver',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        
        // Rows of seats
        ...sortedRows.map((rowNum) {
          final rowSeats = seatsByRow[rowNum]!;
          return _buildSeatRow(rowNum, rowSeats);
        }).toList(),
      ],
    );
  }
  
  Widget _buildSeatRow(int rowNum, List<SeatModel> seats) {
    // Sort seats by position for consistent layout
    final leftSeats = seats.where((s) => s.position == 'left').toList();
    final centerSeats = seats.where((s) => s.position == 'center').toList();
    final rightSeats = seats.where((s) => s.position == 'right').toList();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Left seats
          ...leftSeats.map((seat) => _buildSeat(seat)),
          
          // Aisle
          if (leftSeats.isNotEmpty && (centerSeats.isNotEmpty || rightSeats.isNotEmpty))
            const SizedBox(width: 30),
          
          // Center seats
          ...centerSeats.map((seat) => _buildSeat(seat)),
          
          // Aisle
          if (centerSeats.isNotEmpty && rightSeats.isNotEmpty)
            const SizedBox(width: 30),
          
          // Right seats
          ...rightSeats.map((seat) => _buildSeat(seat)),
        ],
      ),
    );
  }
  
  Widget _buildSeat(SeatModel seat) {
    Color backgroundColor;
    Color? borderColor;
    
    switch (seat.status) {
      case SeatStatus.available:
        backgroundColor = Colors.grey[300]!;
        borderColor = Colors.grey[400];
        break;
      case SeatStatus.selected:
        backgroundColor = Colors.green;
        borderColor = Colors.green[700];
        break;
      case SeatStatus.booked:
        backgroundColor = Colors.red;
        borderColor = Colors.red[700];
        break;
      case SeatStatus.female:
        backgroundColor = Colors.pink[200]!;
        borderColor = Colors.pink[400];
        break;
    }
    
    return GestureDetector(
      onTap: () => _toggleSeat(seat),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor!, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            seat.id,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: seat.status == SeatStatus.available
                  ? Colors.black87
                  : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
