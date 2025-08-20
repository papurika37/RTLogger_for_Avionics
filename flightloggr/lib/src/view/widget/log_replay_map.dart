import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class LogReplayWidget extends StatefulWidget {
  final File logFile;

  const LogReplayWidget({super.key, required this.logFile});

  @override
  State<LogReplayWidget> createState() => _LogReplayWidgetState();
}

class _LogReplayWidgetState extends State<LogReplayWidget> {
  List<List<String>> _logData = [];
  int _currentIndex = 0;
  bool _isPlaying = false;
  Timer? _replayTimer;
  double _playbackSpeed = 1.0;
  double _totalDistance = 0.0;
  List<LatLng> _trackPoints = [];

  // 現在のデータ値
  Map<String, double> _currentValues = {
    'longitude': 0.0,
    'latitude': 0.0,
    'temperature': 0.0,
    'pressure': 0.0,
    'humidity': 0.0,
    'roll': 0.0,
    'pitch': 0.0,
    'yaw': 0.0,
    'airspeed': 0.0,
    'aoa': 0.0,
    'sideslip': 0.0,
    'altitude': 0.0,
    'temp2': 0.0,
    'rpm': 0.0,
    'power': 0.0,
    'elevator': 0.0,
    'rudder': 0.0,
  };

  @override
  void initState() {
    super.initState();
    _loadLogData();
  }

  @override
  void dispose() {
    _replayTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadLogData() async {
    try {
      final lines = await widget.logFile.readAsLines();
      _logData = lines.map((line) => line.split(',')).toList();
      if (_logData.isNotEmpty) {
        _updateCurrentValues(0);
      }
      setState(() {});
    } catch (e) {
      print("ログデータ読み込みエラー: $e");
    }
  }

  void _updateCurrentValues(int index) {
    if (index >= 0 && index < _logData.length && _logData[index].length >= 17) {
      final data = _logData[index];
      _currentValues = {
        'longitude': double.tryParse(data[0]) ?? 0.0,
        'latitude': double.tryParse(data[1]) ?? 0.0,
        'temperature': double.tryParse(data[2]) ?? 0.0,
        'pressure': double.tryParse(data[3]) ?? 0.0,
        'humidity': double.tryParse(data[4]) ?? 0.0,
        'roll': (double.tryParse(data[5]) ?? 180) - 180,
        'pitch': (double.tryParse(data[6]) ?? 180) - 180,
        'yaw': double.tryParse(data[7]) ?? 0.0,
        'airspeed': double.tryParse(data[8]) ?? 0.0,
        'aoa': double.tryParse(data[9]) ?? 0.0,
        'sideslip': double.tryParse(data[10]) ?? 0.0,
        'altitude': double.tryParse(data[11]) ?? 0.0,
        'temp2': double.tryParse(data[12]) ?? 0.0,
        'rpm': double.tryParse(data[13]) ?? 0.0,
        'power': double.tryParse(data[14]) ?? 0.0,
        'elevator': double.tryParse(data[15]) ?? 0.0,
        'rudder': double.tryParse(data[16]) ?? 0.0,
      };
      
      // 移動距離の計算
      _calculateDistanceToIndex(index);
    }
  }

  // 指定されたインデックスまでの移動距離を計算
  void _calculateDistanceToIndex(int index) {
    _totalDistance = 0.0;
    _trackPoints.clear();
    
    for (int i = 0; i <= index && i < _logData.length; i++) {
      if (_logData[i].length >= 17) {
        final lat = double.tryParse(_logData[i][1]) ?? 0.0;
        final lng = double.tryParse(_logData[i][0]) ?? 0.0;
        
        if (lat != 0.0 && lng != 0.0) {
          final point = LatLng(lat, lng);
          _trackPoints.add(point);
          
          if (_trackPoints.length > 1) {
            final Distance distance = Distance();
            final prevPoint = _trackPoints[_trackPoints.length - 2];
            _totalDistance += distance(prevPoint, point);
          }
        }
      }
    }
  }

  void _startReplay() {
    if (_logData.isEmpty) return;
    
    setState(() {
      _isPlaying = true;
    });

    _replayTimer = Timer.periodic(
      Duration(milliseconds: (100 / _playbackSpeed).round()), 
      (timer) {
        if (_currentIndex >= _logData.length - 1) {
          _stopReplay();
          return;
        }
        
        setState(() {
          _currentIndex++;
          _updateCurrentValues(_currentIndex);
        });
      },
    );
  }

  void _stopReplay() {
    _replayTimer?.cancel();
    setState(() {
      _isPlaying = false;
    });
  }

  void _resetReplay() {
    _stopReplay();
    setState(() {
      _currentIndex = 0;
      _updateCurrentValues(0);
    });
  }

  void _seekTo(int index) {
    setState(() {
      _currentIndex = index.clamp(0, _logData.length - 1);
      _updateCurrentValues(_currentIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ログ再生 - ${widget.logFile.path.split(Platform.pathSeparator).last}'),
        backgroundColor: Colors.blue.shade800,
      ),
      body: _logData.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // コントロールパネル
                _buildControlPanel(),
                // データ表示エリア
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildFlightInstruments(),
                          const SizedBox(height: 20),
                          _buildNavigationInfo(),
                          const SizedBox(height: 20),
                          _buildDataTables(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _resetReplay,
                icon: const Icon(Icons.skip_previous),
                tooltip: 'リセット',
              ),
              IconButton(
                onPressed: _isPlaying ? _stopReplay : _startReplay,
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                tooltip: _isPlaying ? '一時停止' : '再生',
              ),
              IconButton(
                onPressed: _stopReplay,
                icon: const Icon(Icons.stop),
                tooltip: '停止',
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 再生速度調整
          Row(
            children: [
              const Text('再生速度: '),
              Expanded(
                child: Slider(
                  value: _playbackSpeed,
                  min: 0.1,
                  max: 5.0,
                  divisions: 49,
                  label: '${_playbackSpeed.toStringAsFixed(1)}x',
                  onChanged: (value) {
                    setState(() {
                      _playbackSpeed = value;
                    });
                  },
                ),
              ),
            ],
          ),
          // 進行状況スライダー
          Row(
            children: [
              Text('${_currentIndex + 1}'),
              Expanded(
                child: Slider(
                  value: _currentIndex.toDouble(),
                  min: 0,
                  max: (_logData.length - 1).toDouble(),
                  onChanged: (value) {
                    _seekTo(value.round());
                  },
                ),
              ),
              Text('${_logData.length}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ナビゲーション情報',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Text(
                        '現在位置',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '緯度: ${(_currentValues['latitude'] ?? 0.0).toStringAsFixed(6)}°',
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                          Text(
                            '経度: ${(_currentValues['longitude'] ?? 0.0).toStringAsFixed(6)}°',
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.timeline, color: Colors.green),
                      const SizedBox(width: 8),
                      const Text(
                        '総移動距離',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Text(
                        '${_totalDistance.toStringAsFixed(2)} m',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.straighten, color: Colors.orange),
                      const SizedBox(width: 8),
                      const Text(
                        '総移動距離 (km)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Text(
                        '${(_totalDistance / 1000).toStringAsFixed(3)} km',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlightInstruments() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'フライト計器',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // 姿勢指示器（簡易版）
                Expanded(
                  child: _buildAttitudeIndicator(),
                ),
                const SizedBox(width: 20),
                // 高度・速度計器
                Expanded(
                  child: _buildAltitudeSpeedIndicator(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttitudeIndicator() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: CustomPaint(
        painter: AttitudePainter(
          roll: _currentValues['roll'] ?? 0.0,
          pitch: _currentValues['pitch'] ?? 0.0,
        ),
        child: Container(),
      ),
    );
  }

  Widget _buildAltitudeSpeedIndicator() {
    return Column(
      children: [
        // 高度計
        Container(
          height: 80,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('高度 (cm)', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                '${_currentValues['altitude']?.toStringAsFixed(1)}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // 速度計
        Container(
          height: 80,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('速度 (m/s)', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                '${_currentValues['airspeed']?.toStringAsFixed(1)}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDataTables() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '詳細データ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDataTable('位置情報', [
              {'label': '経度', 'value': _currentValues['longitude'], 'unit': '°'},
              {'label': '緯度', 'value': _currentValues['latitude'], 'unit': '°'},
              {'label': '総移動距離', 'value': _totalDistance, 'unit': 'm'},
              {'label': '総移動距離', 'value': _totalDistance / 1000, 'unit': 'km'},
            ]),
            const SizedBox(height: 16),
            _buildDataTable('姿勢', [
              {'label': 'Roll', 'value': _currentValues['roll'], 'unit': '°'},
              {'label': 'Pitch', 'value': _currentValues['pitch'], 'unit': '°'},
              {'label': 'Yaw', 'value': _currentValues['yaw'], 'unit': '°'},
            ]),
            const SizedBox(height: 16),
            _buildDataTable('環境データ', [
              {'label': '温度', 'value': _currentValues['temperature'], 'unit': '°C'},
              {'label': '気圧', 'value': _currentValues['pressure'], 'unit': 'hPa'},
              {'label': '湿度', 'value': _currentValues['humidity'], 'unit': '%'},
            ]),
            const SizedBox(height: 16),
            _buildDataTable('フライトデータ', [
              {'label': 'AoA', 'value': _currentValues['aoa'], 'unit': '°'},
              {'label': 'SideSlip', 'value': _currentValues['sideslip'], 'unit': '°'},
              {'label': 'RPM', 'value': _currentValues['rpm'], 'unit': '/min'},
              {'label': 'Power', 'value': _currentValues['power'], 'unit': 'W'},
            ]),
            const SizedBox(height: 16),
            _buildDataTable('操縦面', [
              {'label': 'Elevator', 'value': _currentValues['elevator'], 'unit': '°'},
              {'label': 'Rudder', 'value': _currentValues['rudder'], 'unit': '°'},
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable(String title, List<Map<String, dynamic>> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Table(
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(2),
            2: FlexColumnWidth(1),
          },
          children: data.map((item) {
            return TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(item['label']),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    '${item['value']?.toStringAsFixed(2) ?? 'N/A'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(item['unit'] ?? ''),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

// 姿勢指示器用のCustomPainter
class AttitudePainter extends CustomPainter {
  final double roll;
  final double pitch;

  AttitudePainter({required this.roll, required this.pitch});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 10;

    // 背景（空）
    final skyPaint = Paint()..color = Colors.lightBlue.shade300;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi,
      pi,
      true,
      skyPaint,
    );

    // 地面
    final groundPaint = Paint()..color = Colors.brown.shade400;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      pi,
      true,
      groundPaint,
    );

    // ピッチライン
    final pitchPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2;

    for (int i = -30; i <= 30; i += 10) {
      if (i == 0) continue;
      final y = center.dy + (pitch + i) * 2;
      if (y > center.dy - radius && y < center.dy + radius) {
        canvas.drawLine(
          Offset(center.dx - 30, y),
          Offset(center.dx + 30, y),
          pitchPaint,
        );
      }
    }

    // 水平線
    final horizonPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3;
    canvas.drawLine(
      Offset(center.dx - radius + 20, center.dy + pitch * 2),
      Offset(center.dx + radius - 20, center.dy + pitch * 2),
      horizonPaint,
    );

    // 機体マーク（中央の十字）
    final aircraftPaint = Paint()
      ..color = Colors.yellow
      ..strokeWidth = 4;
    
    canvas.drawLine(
      Offset(center.dx - 40, center.dy),
      Offset(center.dx - 15, center.dy),
      aircraftPaint,
    );
    canvas.drawLine(
      Offset(center.dx + 15, center.dy),
      Offset(center.dx + 40, center.dy),
      aircraftPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - 15),
      Offset(center.dx, center.dy + 15),
      aircraftPaint,
    );

    // ロール指示（外周）
    final rollPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2;

    // ロールスケール
    for (int i = -60; i <= 60; i += 30) {
      final angle = i * pi / 180;
      final x1 = center.dx + (radius - 5) * sin(angle);
      final y1 = center.dy - (radius - 5) * cos(angle);
      final x2 = center.dx + radius * sin(angle);
      final y2 = center.dy - radius * cos(angle);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), rollPaint);
    }

    // ロールポインター
    final rollPointerPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3;
    final rollAngle = roll * pi / 180;
    final pointerX = center.dx + (radius - 10) * sin(rollAngle);
    final pointerY = center.dy - (radius - 10) * cos(rollAngle);
    canvas.drawLine(center, Offset(pointerX, pointerY), rollPointerPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
