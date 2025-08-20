import 'package:flutter_riverpod/flutter_riverpod.dart';

// 移動経路長を計算するProvider
final distProvider = StateProvider<double>((ref) => 0.0);