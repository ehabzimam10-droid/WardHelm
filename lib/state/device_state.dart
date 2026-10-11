import 'dart:async';
import 'package:flutter/material.dart';
import '../data/models/device_model.dart';
import '../data/dal/firestore_dal.dart';
import '../services/auth_service.dart';
import '../services/device_service.dart';

/// Manages reactive fleet device state and pairing operations with owner privacy
class DeviceState extends ChangeNotifier {
  final DeviceService _service;
  final AuthService _authService;
  Timer? _pollTimer;

  List<DeviceModel> _devices = [];
  DeviceModel? _selectedDevice;
  bool _isLoading = false;
  String? _errorMessage;

  DeviceState({DeviceService? service, AuthService? authService})
      : _service = service ?? DeviceService(),
        _authService = authService ?? AuthService();

  List<DeviceModel> get devices => _devices;
  DeviceModel? get selectedDevice => _selectedDevice;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void startPolling() {
    refreshDevices();
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      if (FirestoreDal.isRateLimited) return;
      refreshDevices(silent: true);
    });
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _devices = [];
    _selectedDevice = null;
    notifyListeners();
  }

  Future<void> refreshDevices({bool silent = false}) async {
    if (FirestoreDal.isRateLimited && silent) return;
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }
    try {
      final currentUserId = await _authService.getCurrentUserId();
      _devices = await _service.getDevices(ownerId: currentUserId);
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

  void deselectDevice() {
    _selectedDevice = null;
    notifyListeners();
  }

  /// Claims pairing code and assigns device to the authenticated user
  Future<bool> pairDevice(String code, {String? customName}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final currentUserId = await _authService.getCurrentUserId();
    final device = await _service.claimPairingCode(
      code,
      customName: customName,
      ownerId: currentUserId,
    );
    _isLoading = false;

    if (device != null) {
      await refreshDevices(silent: true);
      _selectedDevice = device;
      notifyListeners();
      return true;
    } else {
      if (FirestoreDal.lastStatusCode == 429) {
        _errorMessage = 'تنبيه: تم استنفاد الحد اليومي المجاني لقاعدة بيانات Firebase (Quota Exceeded). يرجى تفعيل باقة Blaze من لوحة تحكم Firebase لإلغاء القيود فوراً، أو انتظار التصفير التلقائي.';
      } else {
        _errorMessage = 'رمز الربط غير صحيح أو انتهت صلاحيته (مدته 60 ثانية)';
      }
      notifyListeners();
      return false;
    }
  }

  /// Sends a remote command to trigger auto-update on a specific PC agent
  Future<bool> triggerDeviceUpdate(String deviceId, {String? targetVersion}) async {
    final success = await _service.sendUpdateCommand(deviceId, targetVersion: targetVersion);
    if (success) {
      await refreshDevices(silent: true);
    }
    return success;
  }

  /// Completely unpairs and wipes the device data from the fleet
  Future<bool> unpairAndWipeDevice(String deviceId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final success = await _service.unpairAndWipeDevice(deviceId);
      if (success) {
        _devices.removeWhere((d) => d.id == deviceId);
        if (_selectedDevice?.id == deviceId) {
          _selectedDevice = null;
        }
      }
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
