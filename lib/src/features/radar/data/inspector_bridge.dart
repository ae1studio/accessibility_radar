import 'dart:convert';

import 'package:devtools_app_shared/service.dart';

/// `ext.flutter.inspector.*` calls for the connected isolate.
class InspectorBridge {
  InspectorBridge(this._serviceManager);

  final ServiceManager _serviceManager;

  String? _objectGroup;

  String? get objectGroup => _objectGroup;

  Future<void> disposeGroup(String? group) async {
    if (group == null) return;
    final service = _serviceManager.service;
    final isolateId = _serviceManager.isolateManager.mainIsolate.value?.id;
    if (service == null || isolateId == null) return;
    try {
      await service.callServiceExtension(
        'ext.flutter.inspector.disposeGroup',
        isolateId: isolateId,
        args: {'objectGroup': group},
      );
    } catch (_) {}
  }

  Future<Map<String, Object?>?> getRootWidgetTree({
    required bool summaryTree,
  }) async {
    await _serviceManager.waitUntilNotPaused();
    final service = _serviceManager.service;
    final isolateId = _serviceManager.isolateManager.mainIsolate.value?.id;
    if (service == null || isolateId == null) return null;

    final previous = _objectGroup;
    _objectGroup =
        'accessibility_radar_${DateTime.now().microsecondsSinceEpoch}';
    await disposeGroup(previous);

    final response = await service.callServiceExtension(
      'ext.flutter.inspector.getRootWidgetTree',
      isolateId: isolateId,
      args: {
        'groupName': _objectGroup!,
        'isSummaryTree': '$summaryTree',
        'withPreviews': 'true',
        'fullDetails': 'true',
      },
    );

    return _unwrapResultMap(response.json);
  }

  Future<void> setSelectionById(String? valueId) async {
    final service = _serviceManager.service;
    final isolateId = _serviceManager.isolateManager.mainIsolate.value?.id;
    final group = _objectGroup;
    if (service == null ||
        isolateId == null ||
        group == null ||
        valueId == null) {
      return;
    }
    await service.callServiceExtension(
      'ext.flutter.inspector.setSelectionById',
      isolateId: isolateId,
      args: {'arg': valueId, 'objectGroup': group},
    );
  }

  Future<List<Object?>?> getProperties(String? valueId) async {
    await _serviceManager.waitUntilNotPaused();
    final service = _serviceManager.service;
    final isolateId = _serviceManager.isolateManager.mainIsolate.value?.id;
    final group = _objectGroup;
    if (service == null ||
        isolateId == null ||
        group == null ||
        valueId == null) {
      return null;
    }
    final response = await service.callServiceExtension(
      'ext.flutter.inspector.getProperties',
      isolateId: isolateId,
      args: {'arg': valueId, 'objectGroup': group},
    );
    final raw = response.json?['result'];
    if (raw is List) return raw;
    if (raw is String) {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded;
    }
    return null;
  }
}

Map<String, Object?>? _unwrapResultMap(Map<String, dynamic>? json) {
  if (json == null) return null;
  final raw = json['result'];
  if (raw is Map<String, Object?>) return raw;
  if (raw is Map) return Map<String, Object?>.from(raw);
  if (raw is String) {
    final decoded = jsonDecode(raw);
    if (decoded is Map) return Map<String, Object?>.from(decoded);
  }
  return null;
}
