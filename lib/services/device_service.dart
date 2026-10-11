import '../core/constants/app_constants.dart';
import '../data/dal/firestore_dal.dart';
import '../data/models/device_model.dart';
import '../data/models/pairing_code_model.dart';

/// Orchestrates multi-device fleet management, user isolation, and remote commands
class DeviceService {
  final FirestoreDal _dal;

  DeviceService({FirestoreDal? dal}) : _dal = dal ?? FirestoreDal();

  /// Publishes a dynamic 60s pairing code to Firestore
  Future<bool> publishPairingCode(PairingCodeModel model) async {
    return await _dal.setDocument('pairing_codes', model.code, model.toMap());
  }

  /// Claims a pairing code from the Controller Dashboard.
  /// Instantly pairs the device to the current owner and deletes the pairing code record.
  Future<DeviceModel?> claimPairingCode(String code, {String? customName, String? ownerId}) async {
    final cleanCode = code.trim().toUpperCase();
    final data = await _dal.getDocument('pairing_codes', cleanCode);
    if (data == null) return null;

    final pairingModel = PairingCodeModel.fromMap(data, cleanCode);
    // Allow 30-second clock skew and transition grace window
    final isExpired = DateTime.now().isAfter(pairingModel.expiresAt.add(const Duration(seconds: 30)));
    if (isExpired) {
      // Clean up expired code
      await _dal.deleteDocument('pairing_codes', cleanCode);
      return null;
    }

    // Register or update device with owner isolation
    final device = DeviceModel(
      id: pairingModel.deviceId,
      name: customName?.isNotEmpty == true ? customName! : pairingModel.deviceName,
      os: 'Windows Desktop',
      isOnline: true,
      lastHeartbeat: DateTime.now(),
      mode: 'owner',
      ownerId: ownerId,
      version: AppConstants.appVersion,
    );

    final success = await _dal.setDocument('devices', device.id, device.toMap());
    if (success) {
      // Delete the claimed pairing code immediately
      await _dal.deleteDocument('pairing_codes', cleanCode);
      return device;
    }
    return null;
  }

  /// Fetches devices in the fleet, filtered by authenticated owner for privacy
  Future<List<DeviceModel>> getDevices({String? ownerId}) async {
    final list = await _dal.getCollection('devices');
    final all = list.map((m) => DeviceModel.fromMap(m)).toList();
    if (ownerId == null || ownerId.isEmpty) {
      return all;
    }
    // Filter to devices owned by this user (or legacy unassigned devices for backwards compatibility)
    return all.where((d) => d.ownerId == null || d.ownerId == ownerId).toList();
  }

  /// Fetches single device by ID
  Future<DeviceModel?> getDevice(String deviceId) async {
    final data = await _dal.getDocument('devices', deviceId);
    if (data == null) return null;
    return DeviceModel.fromMap(data, deviceId);
  }

  /// Sends remote update command to the PC agent
  Future<bool> sendUpdateCommand(String deviceId, {String? targetVersion}) async {
    final dev = await getDevice(deviceId);
    if (dev == null) return false;
    final updatedMetadata = Map<String, dynamic>.from(dev.metadata);
    updatedMetadata['pendingCommand'] = 'check_update';
    if (targetVersion != null) {
      updatedMetadata['targetVersion'] = targetVersion;
    }
    final updated = dev.copyWith(metadata: updatedMetadata);
    return await _dal.setDocument('devices', deviceId, updated.toMap());
  }

  /// Clears pending command on the device
  Future<bool> clearPendingCommand(String deviceId, DeviceModel existing) async {
    final updatedMetadata = Map<String, dynamic>.from(existing.metadata);
    updatedMetadata.remove('pendingCommand');
    updatedMetadata.remove('targetVersion');
    final updated = existing.copyWith(metadata: updatedMetadata);
    return await _dal.setDocument('devices', deviceId, updated.toMap());
  }

  /// Updates heartbeat directly with known device model (prevents redundant N+1 GET)
  Future<bool> sendHeartbeatDirect(String deviceId, DeviceModel existing, {String? currentVersion}) async {
    final updated = existing.copyWith(
      isOnline: true,
      lastHeartbeat: DateTime.now(),
      version: currentVersion ?? existing.version,
    );
    return await _dal.setDocument('devices', deviceId, updated.toMap());
  }

  /// Updates discovered installed applications on the device
  Future<bool> updateDeviceInstalledApps(String deviceId, DeviceModel existing, List<String> apps) async {
    final updatedMetadata = Map<String, dynamic>.from(existing.metadata);
    updatedMetadata['installedApps'] = apps;
    final updated = existing.copyWith(metadata: updatedMetadata);
    return await _dal.setDocument('devices', deviceId, updated.toMap());
  }

  /// Updates heartbeat and online status
  Future<bool> sendHeartbeat(String deviceId) async {
    final existing = await getDevice(deviceId);
    if (existing == null) return false;
    return await sendHeartbeatDirect(deviceId, existing);
  }

  /// Updates device mode (e.g. 'owner' or 'controlled')
  Future<bool> setDeviceMode(String deviceId, String mode, {String? activeSessionId}) async {
    final existing = await getDevice(deviceId);
    if (existing == null) return false;

    final updated = existing.copyWith(
      mode: mode,
      activeSessionId: activeSessionId,
    );
    return await _dal.setDocument('devices', deviceId, updated.toMap());
  }

  /// Completely unpairs and wipes all device data from Firestore.
  /// Guarantees zero remaining data: deletes device document, all related sessions,
  /// all security logs, and any pending pairing codes for total privacy.
  Future<bool> unpairAndWipeDevice(String deviceId) async {
    try {
      // 1. Delete all sessions for this device
      final sessions = await _dal.getCollection('sessions');
      for (final s in sessions) {
        if (s['deviceId'] == deviceId) {
          final sId = s['id'] as String?;
          if (sId != null && sId.isNotEmpty) {
            await _dal.deleteDocument('sessions', sId);
          }
        }
      }

      // 2. Delete all security logs for this device
      final logs = await _dal.getCollection('security_logs');
      for (final l in logs) {
        if (l['deviceId'] == deviceId) {
          final lId = l['id'] as String?;
          if (lId != null && lId.isNotEmpty) {
            await _dal.deleteDocument('security_logs', lId);
          }
        }
      }

      // 3. Delete any pairing codes for this device
      final codes = await _dal.getCollection('pairing_codes');
      for (final c in codes) {
        if (c['deviceId'] == deviceId) {
          final codeId = c['id'] as String? ?? c['code'] as String?;
          if (codeId != null && codeId.isNotEmpty) {
            await _dal.deleteDocument('pairing_codes', codeId);
          }
        }
      }

      // 4. Finally delete the device document itself
      return await _dal.deleteDocument('devices', deviceId);
    } catch (_) {
      return false;
    }
  }
}

