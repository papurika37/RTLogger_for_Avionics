import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/serial_provider.dart';

class InstrumentWidget extends ConsumerWidget {
  const InstrumentWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serialState = ref.watch(serialProvider);

    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          const Text(
            'Attitude Indicator',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // 姿勢指示器
                  _buildAttitudeIndicator(serialState.pitch, serialState.roll),
                  const SizedBox(height: 16),
                  // 高度・速度計器
                  Row(
                    children: [
                      Expanded(
                        child: _buildAltimeterCard(serialState.alt),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildAirspeedCard(serialState.aispeed),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // ヨー・RPM計器
                  Row(
                    children: [
                      Expanded(
                        child: _buildYawCard(serialState.yaw),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildRPMCard(serialState.rpm),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 温度・気圧計器
                  Row(
                    children: [
                      Expanded(
                        child: _buildTemperatureCard(serialState.temp),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildPressureCard(serialState.pres),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // AoA・パワー計器
                  Row(
                    children: [
                      Expanded(
                        child: _buildAoACard(serialState.aoa),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildPowerCard(serialState.power),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 操舵面計器
                  Row(
                    children: [
                      Expanded(
                        child: _buildElevatorCard(serialState.elevator),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildRudderCard(serialState.rudder),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttitudeIndicator(double roll, double pitch) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const Text(
              'Attitude',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomPaint(
                painter: CompactAttitudePainter(roll: roll, pitch: pitch),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('Roll: ${roll.toStringAsFixed(1)}°', style: const TextStyle(fontSize: 10)),
                Text('Pitch: ${pitch.toStringAsFixed(1)}°', style: const TextStyle(fontSize: 10)),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'DEBUG: R=${roll.toStringAsFixed(2)} P=${pitch.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white, fontSize: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAltimeterCard(double altitude) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const Icon(Icons.height, color: Colors.blue),
            const Text('Alt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Text('${altitude.toStringAsFixed(1)}', 
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Text('cm', style: TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildAirspeedCard(double airspeed) {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const Icon(Icons.speed, color: Colors.green),
            const Text('AS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Text('${airspeed.toStringAsFixed(1)}', 
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Text('m/s', style: TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildYawCard(double yaw) {
    return Card(
      color: Colors.purple.shade50,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const Icon(Icons.explore, color: Colors.purple),
            const Text('Yaw', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Text('${yaw.toStringAsFixed(1)}', 
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Text('°', style: TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildRPMCard(double rpm) {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const Icon(Icons.settings, color: Colors.orange),
            const Text('RPM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Text('${rpm.toStringAsFixed(0)}', 
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Text('/min', style: TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildTemperatureCard(double temperature) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const Icon(Icons.thermostat, color: Colors.red),
            const Text('Tmp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Text('${temperature.toStringAsFixed(1)}', 
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Text('°C', style: TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildPressureCard(double pressure) {
    return Card(
      color: Colors.cyan.shade50,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const Icon(Icons.compress, color: Colors.cyan),
            const Text('Prs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Text('${pressure.toStringAsFixed(2)}', 
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Text('hPa', style: TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildAoACard(double aoa) {
    return Card(
      color: Colors.indigo.shade50,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const Icon(Icons.trending_up, color: Colors.indigo),
            const Text('AoA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Text('${aoa.toStringAsFixed(1)}', 
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Text('°', style: TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildPowerCard(double power) {
    return Card(
      color: Colors.yellow.shade50,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const Icon(Icons.bolt, color: Colors.amber),
            const Text('PWR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Text('${power.toStringAsFixed(1)}', 
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Text('W', style: TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildElevatorCard(double elevator) {
    return Card(
      color: Colors.teal.shade50,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const Icon(Icons.flight_takeoff, color: Colors.teal),
            const Text('Elev', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Text('${elevator.toStringAsFixed(1)}', 
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Text('°', style: TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildRudderCard(double rudder) {
    return Card(
      color: Colors.brown.shade50,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const Icon(Icons.flight_land, color: Colors.brown),
            const Text('Rud', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Text('${rudder.toStringAsFixed(1)}', 
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Text('°', style: TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

// コンパクト姿勢指示器用のCustomPainter
class CompactAttitudePainter extends CustomPainter {
  final double roll;
  final double pitch;

  CompactAttitudePainter({required this.roll, required this.pitch});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 5;

    // 背景円
    final bgPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // 空（上半分）
    final skyPaint = Paint()..color = Colors.lightBlue.shade300;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi,
      pi,
      true,
      skyPaint,
    );

    // 地面（下半分）
    final groundPaint = Paint()..color = Colors.brown.shade400;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      pi,
      true,
      groundPaint,
    );

    // 水平線
    final horizonPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2;
    final horizonY = center.dy + (pitch * 1.5);
    canvas.drawLine(
      Offset(center.dx - radius * 0.6, horizonY),
      Offset(center.dx + radius * 0.6, horizonY),
      horizonPaint,
    );

    // 機体マーク（中央の十字）
    final aircraftPaint = Paint()
      ..color = Colors.yellow
      ..strokeWidth = 2;
    
    canvas.drawLine(
      Offset(center.dx - 15, center.dy),
      Offset(center.dx - 5, center.dy),
      aircraftPaint,
    );
    canvas.drawLine(
      Offset(center.dx + 5, center.dy),
      Offset(center.dx + 15, center.dy),
      aircraftPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - 5),
      Offset(center.dx, center.dy + 5),
      aircraftPaint,
    );

    // ロールポインター
    final rollPointerPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2;
    final rollAngle = roll * pi / 180;
    final pointerX = center.dx + (radius - 5) * sin(rollAngle);
    final pointerY = center.dy - (radius - 5) * cos(rollAngle);
    canvas.drawLine(center, Offset(pointerX, pointerY), rollPointerPaint);

    // 外枠
    final borderPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, borderPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
