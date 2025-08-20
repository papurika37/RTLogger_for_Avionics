import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flightloggr/src/provider/moving_dist_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:csv/csv.dart';
import 'package:latlong2/latlong.dart';
import 'log_provider.dart';
import 'track_provider.dart';

// テレメトリーから送信するデータ
// long,lat,temp,pres,humid,roll,pitch,yaw,aispeed,aoa,sideslip,alt,temp,rpm,power,elevator,rudder

@immutable
class SerialState {
  final List<String> availablePorts;
  final String? selectedPort;
  final bool isConnected;
  final bool isBusy;

  final LatLng? currentPosition;
  final double yaw;

  final double roll;
  final double pitch;

  final double temp;
  final double pres;
  final double humid;

  final double aispeed;
  final double aoa;
  final double sideslip;

  final double alt;
  final double rpm;
  final double power;
  final double elevator;
  final double rudder;


  const SerialState({
    this.availablePorts = const [],
    this.selectedPort,
    this.isConnected = false,
    this.isBusy = false,
    this.currentPosition,
    this.yaw = 0.0,
    this.roll = 0.0,
    this.pitch = 0.0,
    this.temp = 0.0,
    this.pres = 0.0,
    this.humid = 0.0,
    this.aispeed = 0.0,
    this.aoa = 0.0,
    this.sideslip = 0.0,
    this.alt = 0.0,
    this.rpm = 0.0,
    this.power = 0.0,
    this.elevator = 0.0,
    this.rudder = 0.0,
  });

  SerialState copyWith({
    List<String>? availablePorts,
    String? selectedPort,
    bool? isConnected,
    bool? isBusy,
    LatLng? currentPosition,
    double? yaw,
    double? roll,
    double? pitch,
    double? temp,
    double? pres,
    double? humid,
    double? aispeed,
    double? aoa,
    double? sideslip,
    double? alt,
    double? rpm,
    double? power,
    double? elevator,
    double? rudder,
  }) {
    return SerialState(
      availablePorts: availablePorts ?? this.availablePorts,
      selectedPort: selectedPort ?? this.selectedPort,
      isConnected: isConnected ?? this.isConnected,
      isBusy: isBusy ?? this.isBusy,
      currentPosition: currentPosition ?? this.currentPosition,
      yaw: yaw ?? this.yaw,
      roll: roll ?? this.roll,
      pitch: pitch ?? this.pitch,
      temp: temp ?? this.temp,
      pres: pres ?? this.pres,
      humid: humid ?? this.humid,
      aispeed: aispeed ?? this.aispeed,
      aoa: aoa ?? this.aoa,
      sideslip: sideslip ?? this.sideslip,
      alt: alt ?? this.alt,
      rpm: rpm ?? this.rpm,
      power: power ?? this.power,
      elevator: elevator ?? this.elevator,
      rudder: rudder ?? this.rudder,
    );
  }
}

class SerialNotifier extends Notifier<SerialState> {
  SerialPort? _serialPort;
  StreamSubscription<List<int>>? _subscription;
  final BytesBuilder _receivedDataBuffer = BytesBuilder();
  final Distance _distanceCalculator = const Distance();

  @override
  SerialState build() {
    ref.onDispose(() {
      _subscription?.cancel();
      _serialPort?.close();
    });

    final ports = SerialPort.availablePorts;
    return SerialState(
      availablePorts: ports,
      selectedPort: ports.isNotEmpty ? ports.first : null,
      currentPosition: LatLng(34.685, 135.804),
      yaw: 0.0,
      roll: 0.0,
      pitch: 0.0,
      
    );
  }
  
  // ★【変更】データ受信時に、それぞれのProviderを更新する
  Future<void> connect() async {
    if (state.isBusy || state.selectedPort == null || state.isConnected) return;
    state = state.copyWith(isBusy: true);
    try {
      _serialPort = SerialPort(state.selectedPort!);
      if (_serialPort!.openReadWrite()) {
        state = state.copyWith(isConnected: true);
        
        final reader = SerialPortReader(_serialPort!);
        _subscription = reader.stream.listen((data) {
          _receivedDataBuffer.add(data);
          while (true) {
            final bufferBytes = _receivedDataBuffer.toBytes();
            final newlineIndex = bufferBytes.indexOf(10);
            if (newlineIndex == -1) break;

            final lineBytes = bufferBytes.sublist(0, newlineIndex);
            final line = utf8.decode(lineBytes);

            // ★【変更】ログ専用Providerを更新
            ref.read(logProvider.notifier).update((state) => [...state, line]);
            
            try {
              final values = line.split(',');
              if (values.length >= 17) {
                final lon = double.tryParse(values[0].trim());
                final lat = double.tryParse(values[1].trim());
                final temp = double.tryParse(values[2].trim()) ?? 0.0;
                final pres = double.tryParse(values[3].trim()) ?? 0.0;
                final humid = double.tryParse(values[4].trim()) ?? 0.0;
                final roll = (double.tryParse(values[5].trim()) ?? 180) - 180;
                final pitch = (double.tryParse(values[6].trim()) ?? 180) - 180;
                final parsedYaw = double.tryParse(values[7].trim());
                final yaw = parsedYaw != null ? parsedYaw - 90.0 : 0.0;
                final aispeed = double.tryParse(values[8].trim()) ?? 0.0;
                final aoa = double.tryParse(values[9].trim()) ?? 0.0;
                final sideslip = double.tryParse(values[10].trim()) ?? 0.0;
                final alt = double.tryParse(values[11].trim()) ?? 0.0;
                final rpm = double.tryParse(values[13].trim()) ?? 0.0;
                final power = double.tryParse(values[14].trim()) ?? 0.0;
                final elevator = double.tryParse(values[15].trim()) ?? 0.0;
                final rudder = double.tryParse(values[16].trim()) ?? 0.0;

                LatLng? newPosition;
                if (lat != null && lon != null) {
                  final previousPosition = state.currentPosition;
                  newPosition = LatLng(lat, lon);
                  if(previousPosition != null){
                    final double dist = _distanceCalculator.as(LengthUnit.Centimeter, previousPosition, newPosition)/100.0;
                    ref.read(distProvider.notifier).update((total) => total + dist);
                  }
                  ref.read(trackPointsProvider.notifier).update((state) => [...state, newPosition!]);
                }
                
                // ★【変更】すべてのテレメトリデータを更新
                state = state.copyWith(
                  currentPosition: newPosition ?? state.currentPosition,
                  yaw: yaw,
                  roll: roll,
                  pitch: pitch,
                  temp: temp,
                  pres: pres,
                  humid: humid,
                  aispeed: aispeed,
                  aoa: aoa,
                  sideslip: sideslip,
                  alt: alt,
                  rpm: rpm,
                  power: power,
                  elevator: elevator,
                  rudder: rudder,
                );
              }
            } catch (e) { /* ... */ }
            
            _receivedDataBuffer.clear();
            _receivedDataBuffer.add(bufferBytes.sublist(newlineIndex + 1));
          }
        },
        onError: (error) {
            print("ポートでエラーが発生しました: $error");
            // エラー内容に関わらず、安全に切断処理を呼び出す
            disconnect();
          },
        );
      }
    } on SerialPortError catch (e, _) {
      print("シリアルポートエラー: $e");
      disconnect();
    } finally {
      // 成功しても失敗しても、必ずisBusyをfalseに戻す
      state = state.copyWith(isBusy: false);
    }
  }

  // ★【変更】ログクリア処理
  void clearData() {
    ref.read(logProvider.notifier).state = [];
    ref.read(trackPointsProvider.notifier).state = [];
    ref.read(distProvider.notifier).state = 0.0;
  }

  // ★【変更】CSV保存処理
  Future<String?> saveAsCsv() async {
    final logData = ref.read(logProvider); // ログProviderからデータを取得
    if (logData.isEmpty) {
      print("保存するデータがありません。");
      return null;
    }
    try {
      // ログデータをCSVが要求する List<List<dynamic>> 形式に変換
      final csvData = logData.map((line) => line.split(',')).toList();
      final projectDir = Directory.current;
      final logDir = Directory('${projectDir.path}/logs');
      if(!await logDir.exists()) {
        await logDir.create(recursive: true);
      }
      final csvString = const ListToCsvConverter().convert(csvData);
      
      final now = DateTime.now();
      final timestamp = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_'
                        '${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}';
      final filepath = '${logDir.path}/flight_data_$timestamp.csv';
      final file = File(filepath);
      await file.writeAsString(csvString);
      print("CSVファイルを保存しました: $filepath");
      return filepath;
    } catch (e) {
      print("CSV保存エラー: $e");
      return null;
    }
  }
  Future<void> disconnect() async {
    if (state.isBusy) return;

    state = state.copyWith(isBusy: true);
    try {
      _subscription?.cancel();
      _subscription = null;
      _serialPort?.close();
      _serialPort?.dispose();
      _serialPort = null;
      _receivedDataBuffer.clear();

      if (state.isConnected) {
        state = state.copyWith(isConnected: false);
        print("切断しました。");
      }
    } catch (e) {
      print("切断処理中のエラー: $e");
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }

  void selectPort(String? port) {
    if (state.isConnected) return;
    state = state.copyWith(selectedPort: port);
  }

  void refreshPorts() {
    if (state.isConnected) return;
    final ports = SerialPort.availablePorts;
    String? currentSelected = state.selectedPort;
    if (!ports.contains(currentSelected)) {
      currentSelected = ports.isNotEmpty ? ports.first : null;
    }
    state = state.copyWith(
      availablePorts: ports,
      selectedPort: currentSelected,
    );
  }
}

final serialProvider =
    NotifierProvider<SerialNotifier, SerialState>(SerialNotifier.new);