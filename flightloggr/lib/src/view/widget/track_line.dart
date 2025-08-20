import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../provider/serial_provider.dart';
import '../../provider/track_provider.dart';

class TrackLineLayer extends ConsumerWidget {
  const TrackLineLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 軌跡データプロバイダを監視する
    final points = ref.watch(trackPointsProvider);

    // 点が2つ以上ないと線は描画しない
    if (points.length < 2) {
      return const SizedBox.shrink(); // 何も表示しない
    }

    // PolylineLayerウィジェットを返す
    return PolylineLayer(
      polylines: [
        Polyline(
          points: points,
          color: Colors.blue.withOpacity(0.8),
          strokeWidth: 4.0,
        ),
      ],
    );
  }
}