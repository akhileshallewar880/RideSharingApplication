import 'package:flutter/material.dart';
import '../../../../core/models/driver_models.dart';

/// Panel for collecting cash payments from passengers
class PaymentCollectionPanel extends StatefulWidget {
  final List<PassengerInfo> passengers;
  final VoidCallback onClose;
  final Function(String bookingId, double amount) onPaymentCollected;

  const PaymentCollectionPanel({
    super.key,
    required this.passengers,
    required this.onClose,
    required this.onPaymentCollected,
  });

  @override
  State<PaymentCollectionPanel> createState() => _PaymentCollectionPanelState();
}

class _PaymentCollectionPanelState extends State<PaymentCollectionPanel> {
  final Set<String> _collectedPayments = {};

  @override
  Widget build(BuildContext context) {
    // Filter passengers who need to pay cash
    final cashPassengers = widget.passengers.where(
      (p) => p.paymentStatus == 'pending' && p.boardingStatus == 'boarded',
    ).toList();
    
    final collectedCount = _collectedPayments.length;
    final totalCount = cashPassengers.length;

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[600],
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: widget.onClose,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Payment Collection',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '$collectedCount of $totalCount collected',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: totalCount > 0 ? collectedCount / totalCount : 0,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Passenger list
        Expanded(
          child: cashPassengers.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: Colors.green,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'All payments collected!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cashPassengers.length,
                  itemBuilder: (context, index) {
                    final passenger = cashPassengers[index];
                    final isCollected = _collectedPayments.contains(passenger.bookingId);
                    
                    return _buildPassengerCard(passenger, isCollected);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPassengerCard(PassengerInfo passenger, bool isCollected) {
    // Calculate fare - assuming totalFare is available from booking
    // For now, using pricePerSeat * passengerCount as placeholder
    final fare = passenger.totalFare;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCollected ? Colors.green[50] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCollected ? Colors.green[300]! : Colors.grey[300]!,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: isCollected ? Colors.green : Colors.orange,
              child: Text(
                passenger.passengerName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    passenger.passengerName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: isCollected ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                if (isCollected)
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 24,
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  '${passenger.pickupLocation} → ${passenger.dropoffLocation}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.people,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${passenger.passengerCount} passenger${passenger.passengerCount > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isCollected 
                  ? Colors.green[100]
                  : Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.currency_rupee, size: 20),
                const SizedBox(width: 4),
                Text(
                  fare.toStringAsFixed(0),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (!isCollected)
                  ElevatedButton.icon(
                    onPressed: () => _collectPayment(passenger, fare),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Collect'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Collected',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _collectPayment(PassengerInfo passenger, double amount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: Text(
          'Confirm cash payment of ₹${amount.toStringAsFixed(0)} received from ${passenger.passengerName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _collectedPayments.add(passenger.bookingId);
              });
              widget.onPaymentCollected(passenger.bookingId, amount);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Payment collected from ${passenger.passengerName}'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}

// Extension to add totalFare to PassengerInfo if not present
extension PassengerInfoExtension on PassengerInfo {
  double? get totalFare {
    // This should be available from the booking data
    // For now, return null and it will be handled
    return null;
  }
}
