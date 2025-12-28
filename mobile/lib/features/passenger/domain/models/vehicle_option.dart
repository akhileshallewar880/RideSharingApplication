import 'package:flutter/material.dart';

/// Vehicle option model
class VehicleOption {
  final String id;
  final String name;
  final String model;
  final IconData icon;
  final int seats;
  final int basePrice;
  final int pricePerKm;
  
  VehicleOption({
    required this.id,
    required this.name,
    required this.model,
    required this.icon,
    required this.seats,
    required this.basePrice,
    required this.pricePerKm,
  });
}
