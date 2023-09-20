// ignore_for_file: sized_box_for_whitespace

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class CustomMarker extends StatelessWidget {
  final LatLng point;
  final IconData iconData;
  final Color color;

  const CustomMarker({
    super.key,
    required this.point,
    required this.iconData,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40.0,
      height: 40.0,
      child: Icon(
        iconData,
        color: color,
      ),
    );
  }
}
