import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

class PrintBluetoothThermal {
  static const MethodChannel _channel = MethodChannel('groons.web.app/print');

  ///returns true if bluetooth is on
  static Future<bool> get bluetoothEnabled async {
    bool bluetoothState = false;
    try {
      bluetoothState = await _channel.invokeMethod('bluetoothenabled');
    } on PlatformException catch (e) {
      print("Bluetooth status failure: '${e.message}'.");
    }

    return bluetoothState;
  }

  ///resonates all paired bluetooth on the device
  static Future<List<BluetoothInfo>> get pairedBluetooth async {
    List<BluetoothInfo> items = [];
    try {
      final List result = await _channel.invokeMethod('pairedbluetooths');
      await Future.forEach(result, (element) {
        String item = element as String;
        List<String> info = item.split("#");
        String name = info[0];
        String mac = info[1];
        items.add(BluetoothInfo(name: name, macAddress: mac));
      });
    } on PlatformException catch (e) {
      print("Fail paired Bluetooth: '${e.message}'.");
    }

    return items;
  }

  ///returns true if you are currently connected to the printer
  static Future<bool> get connectionStatus async {
    try {
      final bool result = await _channel.invokeMethod('connectionstatus');
      return result;
    } on PlatformException catch (e) {
      print("Failed state connection: '${e.message}'.");
      return false;
    }
  }

  ///send connection to ticket printer and wait true if it was successful, the mac address of the printer's bluetooth must be sent
  static Future<bool> connect({required String macPrinterAddress}) async {
    bool result = false;

    String mac = macPrinterAddress;

    try {
      result = await _channel.invokeMethod('connect', mac);
      print("Result status connect: $result");
    } on PlatformException catch (e) {
      print("Failed to connect: ${e.message}");
    }
    return result;
  }

  ///send bytes to print, esc_pos_utils_plus package must be used, returns true if successful
  static Future<bool> writeBytes(List<int> bytes) async {
    try {
      final bool result = await _channel.invokeMethod('writebytes', bytes);
      return result;
    } on PlatformException catch (e) {
      print("Failed to write bytes: '${e.message}'.");
      return false;
    }
  }

  ///Strings are sent to be printed by the PrintTextSize class can print from size 1 (50%) to size 5 (400%)
  static Future<bool> writeString({required PrintTextSize printText}) async {
    ///EN: you must send the enter \n to print the complete phrase, it is not sent automatically because you may want to add several
    /// horizontal values ​​of different size
    int size = printText.size <= 5 ? printText.size : 2;
    String text = printText.text;

    String textFinal = "$size///$text";

    try {
      final bool result = await _channel.invokeMethod('printstring', textFinal);
      return result;
    } on PlatformException catch (e) {
      print("Failed to print text: '${e.message}'.");
      return false;
    }
  }

  ///gets the android version where it is running, returns String
  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  ///get the percentage of the battery returns int
  static Future<int> get batteryLevel async {
    int result = 0;

    try {
      result = await _channel.invokeMethod('getBatteryLevel');
    } on PlatformException catch (e) {
      print("Failed to get battery level: '${e.message}'.");
    }
    return result;
  }

  ///disconnect print
  static Future<bool> get disconnect async {
    bool status = false;
    try {
      status = await _channel.invokeMethod('disconnect');
    } on PlatformException catch (e) {
      print("Failed to disconnect: '${e.message}'.");
    }

    return status;
  }
}

class BluetoothInfo {
  String name;
  String macAddress;

  BluetoothInfo({
    required this.name,
    required this.macAddress,
  });

  BluetoothInfo copyWith({
    String? name,
    String? macAddress,
  }) {
    return BluetoothInfo(
      name: name ?? this.name,
      macAddress: macAddress ?? this.macAddress,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'macAddress': macAddress,
    };
  }

  factory BluetoothInfo.fromMap(Map<String, dynamic> map) {
    return BluetoothInfo(
      name: map['name'],
      macAddress: map['macAddress'],
    );
  }

  String toJson() => json.encode(toMap());

  factory BluetoothInfo.fromJson(String source) => BluetoothInfo.fromMap(json.decode(source));

  @override
  String toString() => 'BluetoothInfo(name: $name, macAddress: $macAddress)';
}

class PrintTextSize {
  ///min size 1 max 5, if the size is different to the range it will be 2
  late int size;
  late String text;

  PrintTextSize({
    required this.size,
    required this.text,
  });
}
