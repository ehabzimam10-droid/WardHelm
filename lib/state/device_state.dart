import 'dart:async';
import 'package:flutter/material.dart';
import '../data/models/device_model.dart';
import '../services/device_service.dart';

/// Manages reactive fleet device state and pairing operations
class DeviceState extends ChangeNotifier {
  final DeviceService _service;
  Timer? _pollTimer;

  List<DeviceModel> _devices = [];
  DeviceModel? _selectedDevice;
  bool _isLoading = false;
  String? _errorMessage;

  DeviceState({DeviceService? service}) : _service = service ?? DeviceService();

  List<DeviceModel> get devices => _devices;
  DeviceModel? get selectedDevice => _selectedDevice;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void startPolling() {
    refreshDevices();
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => refreshDevices(silent: true));
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> refreshDevices({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }
    try {
      _devices = await _service.getDevices();
      if (_selectedDevice != null) {
        _selectedDevice = _devices.firstWhere(
          (d) => d.id == _selectedDevice!.id,
          orElse: () => _selectedDevice!,
        );
      }
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if (!silent) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  void selectDevice(String deviceId) {
    _selectedDevice = _devices.firstWhere(
      (d) => d.id == deviceId,
      orElse: () => _devices.first,
    );
    notifyListeners();
  }

  /// Claims pairing code
  Future<bool> pairDevice(String code, {String? customName}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final device = await _service.claimPairingCode(code, customName: customName);
    _isLoading = false;

    if (device != null) {
      await refreshDevices(silent: true);
      _selectedDevice = device;
      notifyListeners();
      return true;
    } else {
      _errorMessage = 'Invalid or expired pairing code';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
