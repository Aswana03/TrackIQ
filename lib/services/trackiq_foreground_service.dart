
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';

class TrackIQForegroundService {
  static void initialize() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'trackiq_monitoring',
        channelName: 'TrackIQ Background Monitoring',
        channelDescription:
            'Shows when TrackIQ background monitoring is active.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  static Future<bool> startMonitoring() async {
    if (await FlutterForegroundTask.isRunningService) {
      return true;
    }

    var permission =
        await FlutterForegroundTask.checkNotificationPermission();

    if (permission != NotificationPermission.granted) {
      permission =
          await FlutterForegroundTask.requestNotificationPermission();
    }

    if (permission != NotificationPermission.granted) {
      return false;
    }

    final result = await FlutterForegroundTask.startService(
      serviceId: 256,
      notificationTitle: 'TrackIQ',
      notificationText: 'Background monitoring is on.',
      callback: startCallback,
    );

    return result is ServiceRequestSuccess;
  }

  static Future<bool> stopMonitoring() async {
    if (!await FlutterForegroundTask.isRunningService) {
      return true;
    }

    final result = await FlutterForegroundTask.stopService();
    return result is ServiceRequestSuccess;
  }

  static Future<bool> get isRunning async {
    return FlutterForegroundTask.isRunningService;
  }
}

@pragma('vm:entry-point')
void startCallback() {
  DartPluginRegistrant.ensureInitialized();
  FlutterForegroundTask.setTaskHandler(TrackIQTaskHandler());
}

class TrackIQTaskHandler extends TaskHandler {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _firebaseReady = false;
  bool _notificationReady = false;
  bool _isChecking = false;

  bool? _wasInsideGeofence;

  static const String _trackerPath = 'trackers/trackiq';

  @override
  Future<void> onStart(
    DateTime timestamp,
    TaskStarter starter,
  ) async {
    FlutterForegroundTask.updateService(
      notificationTitle: 'TrackIQ',
      notificationText: 'Background monitoring is on.',
    );

    await _initializeNotifications();
    await _initializeFirebase();
    await _checkGeofence();
  }

  // Initialize local notifications.
  Future<void> _initializeNotifications() async {
    if (_notificationReady) return;

    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const settings = InitializationSettings(
        android: androidSettings,
      );

      await _notifications.initialize(settings);

      const channel = AndroidNotificationChannel(
        'trackiq_geofence_alerts',
        'TrackIQ Safe Zone Alerts',
        description:
            'Alerts when machines exit or re-enter their permitted region.',
        importance: Importance.max,
      );

      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.createNotificationChannel(channel);

      _notificationReady = true;
    } catch (error) {
      print('TrackIQ notification initialization failed: $error');
    }
  }

  // Initialize Firebase and verify authentication.
  Future<void> _initializeFirebase() async {
    if (_firebaseReady) return;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        print(
          'TrackIQ background monitor: no authenticated user. '
          'Open the app and sign in again.',
        );
        return;
      }

      _firebaseReady = true;

      print(
        'TrackIQ background Firebase initialized for ${user.uid}.',
      );
    } catch (error) {
      print(
        'TrackIQ background Firebase initialization failed: $error',
      );
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    if (!_isChecking) {
      unawaited(_checkGeofence());
    }
  }

  // Check machine position against its permitted operating region.
  Future<void> _checkGeofence() async {
    if (_isChecking) return;

    _isChecking = true;

    try {
      await _initializeNotifications();
      await _initializeFirebase();

      if (!_firebaseReady) return;

      final root = FirebaseDatabase.instance.ref(_trackerPath);

      // Read only the required fields, not the history records.
      final snapshots = await Future.wait<DataSnapshot>([
        root.child('latitude').get(),
        root.child('longitude').get(),
        root.child('gpsActive').get(),
        root.child('timestamp').get(),
        root.child('geofence/latitude').get(),
        root.child('geofence/longitude').get(),
        root.child('geofence/radius').get(),
      ]);

      final latitude = _asDouble(snapshots[0].value);
      final longitude = _asDouble(snapshots[1].value);
      final gpsActive = snapshots[2].value == true;
      final timestampValue = snapshots[3].value;

      final fenceLatitude = _asDouble(snapshots[4].value);
      final fenceLongitude = _asDouble(snapshots[5].value);
      final radiusValue = _asDouble(snapshots[6].value);

      if (latitude == null ||
          longitude == null ||
          fenceLatitude == null ||
          fenceLongitude == null ||
          radiusValue == null) {
        return;
      }

      if (!gpsActive ||
          !_validCoordinates(latitude, longitude) ||
          !_validCoordinates(fenceLatitude, fenceLongitude)) {
        return;
      }

      // Ignore stale GPS readings.
      final gpsTimestamp = _parseTimestamp(timestampValue);

      if (gpsTimestamp == null) return;

      final age = DateTime.now().toUtc().difference(gpsTimestamp);

      if (age.isNegative ||
          age > const Duration(seconds: 30)) {
        return;
      }

      final radius = radiusValue.clamp(10.0, 5000.0);

      final distance = _distanceInMeters(
        latitude,
        longitude,
        fenceLatitude,
        fenceLongitude,
      );

      final isInside = distance <= radius;
      final previousState = _wasInsideGeofence;

      // Establish initial state without a false notification.
      if (previousState == null) {
        _wasInsideGeofence = isInside;
        return;
      }

      // No notification or incident if there is no boundary crossing.
      if (previousState == isInside) return;

      // Update state to prevent duplicate alerts.
      _wasInsideGeofence = isInside;

      if (isInside) {
        // Record re-entry incident in Firebase.
        await _recordSecurityAlert(
          isInside: true,
          latitude: latitude,
          longitude: longitude,
        );

        await _showGeofenceNotification(
          id: 102,
          title: 'Safe Zone Re-entered',
          body: 'Machine 01 has returned to its permitted region.',
        );
      } else {
        // Record unauthorized movement incident in Firebase.
        await _recordSecurityAlert(
          isInside: false,
          latitude: latitude,
          longitude: longitude,
        );

        await _showGeofenceNotification(
          id: 101,
          title: 'Unauthorized Movement Alert',
          body: 'Machine 01 has left its permitted operating region!',
        );
      }
    } catch (error) {
      print('TrackIQ background geofence check failed: $error');
    } finally {
      _isChecking = false;
    }
  }

  // Save security incident to Firebase Realtime Database.
  Future<void> _recordSecurityAlert({
    required bool isInside,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final alertsRef = FirebaseDatabase.instance.ref(
        '$_trackerPath/securityAlerts',
      );

      final alertRef = alertsRef.push();

      await alertRef.set({
        'machineId': 'Machine 01',
        'alertType': isInside
            ? 'geofence_reentry'
            : 'unauthorized_movement',
        'title': isInside
            ? 'Machine Re-entered Operating Region'
            : 'Unauthorized Movement Detected',
        'description': isInside
            ? 'Machine 01 has returned to its assigned operating region.'
            : 'Machine 01 has moved outside its assigned operating region.',
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': ServerValue.timestamp,
        'status': 'unacknowledged',
      });

      print(
        'TrackIQ: ${isInside ? 'Re-entry' : 'Exit'} incident saved. '
        'Alert ID: ${alertRef.key}',
      );
    } catch (error) {
      print(
        'TrackIQ: Failed to save security incident: $error',
      );
    }
  }

  // Display local notification.
  Future<void> _showGeofenceNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_notificationReady) {
      await _initializeNotifications();
    }

    if (!_notificationReady) return;

    const androidDetails = AndroidNotificationDetails(
      'trackiq_geofence_alerts',
      'TrackIQ Safe Zone Alerts',
      channelDescription:
          'Alerts when machines exit or re-enter their permitted region.',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      playSound: true,
      enableVibration: true,
    );

    try {
      await _notifications.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: androidDetails,
        ),
      );
    } catch (error) {
      print(
        'TrackIQ could not show geofence notification: $error',
      );
    }
  }

  double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();

    return double.tryParse(value?.toString() ?? '');
  }

  bool _validCoordinates(
    double latitude,
    double longitude,
  ) {
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      final milliseconds = value > 100000000000
          ? value.toInt()
          : (value * 1000).toInt();

      return DateTime.fromMillisecondsSinceEpoch(
        milliseconds,
        isUtc: true,
      );
    }

    return DateTime.tryParse(value.toString())?.toUtc();
  }

  double _distanceInMeters(
    double latitude1,
    double longitude1,
    double latitude2,
    double longitude2,
  ) {
    const earthRadius = 6371000.0;

    final lat1 = latitude1 * math.pi / 180;
    final lat2 = latitude2 * math.pi / 180;

    final deltaLat =
        (latitude2 - latitude1) * math.pi / 180;

    final deltaLon =
        (longitude2 - longitude1) * math.pi / 180;

    final a =
        math.sin(deltaLat / 2) *
            math.sin(deltaLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLon / 2) *
            math.sin(deltaLon / 2);

    final boundedA = a.clamp(0.0, 1.0);

    final c = 2 *
        math.atan2(
          math.sqrt(boundedA),
          math.sqrt(1 - boundedA),
        );

    return earthRadius * c;
  }

  @override
  Future<void> onDestroy(
    DateTime timestamp,
    bool isTimeout,
  ) async {
    print(
      'TrackIQ foreground service stopped. Timeout: $isTimeout',
    );
  }
}
