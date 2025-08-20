import 'dart:async'; // ★ StreamSubscriptionのためにインポート
import 'package:flightloggr/src/provider/moving_dist_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../provider/serial_provider.dart';
import 'track_line.dart';

enum MapHeadingMode {
  headingUp,
  northUp,
}

class MapView extends ConsumerStatefulWidget {
  const MapView({super.key});

  @override
  ConsumerState<MapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<MapView> {
  final MapController _mapController = MapController();
  // ★【追加】イベントストリームの購読を管理するための変数
  late final StreamSubscription<MapEvent> _mapEventSubscription;

  double _currentZoom = 15.0;
  MapHeadingMode _headingMode = MapHeadingMode.headingUp;
  bool _isLockedOnLocation = true;

  static const double _minZoom = 10.0;
  static const double _maxZoom = 18.0;

  // ★【追加】initStateでイベントリスナーをセットアップ
  @override
  void initState() {
    super.initState();
    // コントローラーのイベントストリームを購読し、イベントが発生したら_onMapEventを呼び出す
    _mapEventSubscription = _mapController.mapEventStream.listen(_onMapEvent);
  }

  // ★【追加】disposeでリスナーを破棄
  @override
  void dispose() {
    _mapEventSubscription.cancel();
    super.dispose();
  }

  // ★【追加】イベントを処理するメソッド
  void _onMapEvent(MapEvent event) {
    // ユーザーが手動で地図をドラッグしたら、自動追従をオフにする
    if (event is MapEventMove && event.source == MapEventSource.onDrag) {
      if (_isLockedOnLocation) {
        setState(() {
          _isLockedOnLocation = false;
        });
      }
    }
    // 地図のズームレベルが変わったら、スライダーに反映
    if (event.camera.zoom != _currentZoom) {
      setState(() {
        _currentZoom = event.camera.zoom;
      });
    }
  }
  
  void _centerOnLocation() {
    setState(() {
      _isLockedOnLocation = true;
    });
    final currentPosition = ref.read(serialProvider).currentPosition;
    if (currentPosition != null) {
      _mapController.move(currentPosition, _currentZoom);
    }
  }

  void _toggleHeadingMode() {
    setState(() {
      if (_headingMode == MapHeadingMode.headingUp) {
        _headingMode = MapHeadingMode.northUp;
        _mapController.rotate(0);
      } else {
        _headingMode = MapHeadingMode.headingUp;
        final currentYaw = ref.read(serialProvider).yaw;
        if (currentYaw != null) {
          _mapController.rotate(-currentYaw);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final serialState = ref.watch(serialProvider);
    final currentPosition = serialState.currentPosition;

    ref.listen(serialProvider.select((state) => state.currentPosition),
        (previous, next) {
      if (next != null && previous != next && _isLockedOnLocation) {
        _mapController.move(next, _currentZoom);
      }
    });

    ref.listen(serialProvider.select((state) => state.yaw), (previous, next) {
      if (previous != next && _headingMode == MapHeadingMode.headingUp && next != null) {
        _mapController.rotate(-next);
      }
    });

    if (currentPosition == null) {
      return const Center(child: Text("GPSデータを待っています..."));
    }
    final currentYaw = ref.read(serialProvider).yaw;
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            // ★【変更】`onMapEvent`はここでは設定しません
            initialCenter: currentPosition,
            initialZoom: _currentZoom,
            maxZoom: _maxZoom,
            minZoom: _minZoom,
            initialRotation: _headingMode == MapHeadingMode.headingUp ? -(serialState.yaw) : 0,
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'dev.yourcompany.gpslogger',
            ),
            const TrackLineLayer(),
              MarkerLayer(
              markers: [
                Marker(
                  point: currentPosition,
                  width: 80,
                  height: 80,
                  child: Transform.rotate(
                    angle: currentYaw * pi / 180,
                    child: const Icon(
                      Icons.flight,
                      color: Colors.red,
                      size: 40,
                    ),
                  )
                ),
              ],
            ),
          ],
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.my_location,
                        color: _isLockedOnLocation
                            ? Colors.black54
                            : Colors.blue,
                      ),
                      tooltip: '現在地に戻る',
                      onPressed: _centerOnLocation,
                    ),
                    const Divider(height: 1),
                    IconButton(
                      icon: Icon(_headingMode == MapHeadingMode.headingUp
                          ? Icons.explore
                          : Icons.explore_off),
                      tooltip: '表示モード切替',
                      onPressed: _toggleHeadingMode,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: 250,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Icon(Icons.zoom_out),
                    ),
                    Expanded(
                      child: Slider(
                        value: _currentZoom,
                        min: _minZoom,
                        max: _maxZoom,
                        divisions: (_maxZoom - _minZoom).toInt() * 2,
                        label: _currentZoom.toStringAsFixed(1),
                        onChanged: (value) {
                          setState(() {
                            _currentZoom = value;
                          });
                          _mapController.move(_mapController.camera.center, value);
                        },
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: Icon(Icons.zoom_in),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 20,
          left: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children:[
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    '緯度: ${currentPosition.latitude.toStringAsFixed(6)}\n'
                    '経度: ${currentPosition.longitude.toStringAsFixed(6)}\n'
                    '経路長: ${ref.watch(distProvider).toStringAsFixed(2)} m',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              )
            ]
          ))
      ],
    );
  }
}