import 'package:flutter/material.dart';

extension SpaceExtension on num {
  /// Crée un SizedBox vertical avec la hauteur spécifiée (34.ph)
  SizedBox get ph => SizedBox(height: toDouble());

  /// Crée un SizedBox horizontal avec la largeur spécifiée (34.pw)
  SizedBox get pw => SizedBox(width: toDouble());
}
