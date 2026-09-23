import '../models/tracker_location.dart';
import '../services/firebase_location_service.dart';

class TrackerRepository {
  final FirebaseLocationService _firebaseLocationService =
      FirebaseLocationService();

  // Live tracker location
  Stream<TrackerLocation?> get locationStream {
    return _firebaseLocationService.locationStream();
  }

  // Historical tracker locations
  Stream<List<TrackerLocation>> get historyStream {
    return _firebaseLocationService.historyStream();
  }
}