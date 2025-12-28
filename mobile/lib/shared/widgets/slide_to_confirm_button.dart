import 'package:flutter/material.dart';
import '../../app/themes/app_colors.dart';
import '../../app/themes/text_styles.dart';

/// Sliding confirmation button to prevent accidental actions
class SlideToConfirmButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final Color backgroundColor;
  final Color sliderColor;
  final VoidCallback onConfirmed;
  final double height;

  const SlideToConfirmButton({
    super.key,
    required this.text,
    required this.onConfirmed,
    this.icon = Icons.arrow_forward,
    this.backgroundColor = AppColors.success,
    this.sliderColor = Colors.white,
    this.height = 60,
  });

  @override
  State<SlideToConfirmButton> createState() => _SlideToConfirmButtonState();
}

class _SlideToConfirmButtonState extends State<SlideToConfirmButton> {
  double _dragPosition = 0;
  bool _isConfirmed = false;

  @override
  Widget build(BuildContext context) {
    final maxDrag = MediaQuery.of(context).size.width - 120; // Account for padding and slider size

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.backgroundColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(widget.height / 2),
        border: Border.all(
          color: widget.backgroundColor,
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          // Background text
          Center(
            child: Text(
              widget.text,
              style: TextStyles.bodyLarge.copyWith(
                color: widget.backgroundColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Sliding indicator
          AnimatedPositioned(
            duration: Duration(milliseconds: 200),
            left: _dragPosition,
            top: 4,
            bottom: 4,
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                if (!_isConfirmed) {
                  setState(() {
                    _dragPosition = (_dragPosition + details.delta.dx).clamp(0.0, maxDrag);
                  });
                }
              },
              onHorizontalDragEnd: (details) {
                if (_dragPosition >= maxDrag * 0.8) {
                  // Confirmed!
                  setState(() {
                    _isConfirmed = true;
                    _dragPosition = maxDrag;
                  });
                  Future.delayed(Duration(milliseconds: 300), () {
                    widget.onConfirmed();
                  });
                } else {
                  // Reset
                  setState(() {
                    _dragPosition = 0;
                  });
                }
              },
              child: Container(
                width: widget.height - 8,
                decoration: BoxDecoration(
                  color: _isConfirmed ? AppColors.success : widget.sliderColor,
                  borderRadius: BorderRadius.circular((widget.height - 8) / 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  _isConfirmed ? Icons.check : widget.icon,
                  color: _isConfirmed ? Colors.white : widget.backgroundColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
