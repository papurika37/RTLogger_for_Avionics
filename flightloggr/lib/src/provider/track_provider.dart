import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

// 軌跡の座標リスト専用のProvider
final trackPointsProvider = StateProvider<List<LatLng>>((ref) => []);