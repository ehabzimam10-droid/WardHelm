import '../data/dal/firestore_dal.dart';
import '../data/models/device_model.dart';
import '../data/models/pairing_code_model.dart';

/// Orchestrates multi-device fleet management and pairing
class DeviceService {
  final FirestoreDal _dal;

  DeviceService({FirestoreDal? dal}) : _dal = dal ?? FirestoreDal();

  /// Publishes a dynamic 60s pairing code to Firestore
  Future<bool> publishPairingCode(PairingCodeModel model) async {
    return await _dal.setDocument('pairing_codes', model.code, model.toMap());
  }

  /// Claims a pairing code from the Controller Dashboard.
  /// Instantly pairs the device and deletes the pairing code record so it cannot be reused.
  Future<DeviceModel?> claimPairingCode(String code, {String? customName}) async {
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

    // Register or update device
    final device = DeviceModel(
      id: pairingModel.deviceId,
      name: customName?.isNotEmpty == true ? customName! : pairingModel.deviceName,
      os: 'Windows Desktop',
      isOnline: true,
      lastHeartbeat: DateTime.now(),
      mode: 'owner',
    );

    final success = await _dal.setDocument('devices', device.id, device.toMap());
    if (success) {
      // Delete the claimed pairing code immediately
      await _dal.deleteDocument('pairing_codes', cleanCode);
      return device;
    }
    return null;
  }

  /// Fetches all devices in the fleet
  Future<List<DeviceModel>> getDevices() async {
    final list = await _dal.getCollection('devices');
    return list.map((m) => DeviceModel.fromMap(m)).toList();
  }

  /// Fetches single device by ID
  Future<DeviceModel?> getDevice(String deviceId) async {
    final data = await _dal.getDocument('devices', deviceId);
    if (data == null) return null;
    return DeviceModel.fromMap(data, deviceId);
  }

  /// Updates heartbeat directly with known device model (prevents redundant N+1 GET)
  Future<bool> sendHeartbeatDirect(String deviceId, DeviceModel existing) async {
    final updated = existing.copyWith(
      isOnline: true,
      lastHeartbeat: DateTime.now(),
    );
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
}
