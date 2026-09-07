import '../models/tracker_location.dart';
import '../services/firebase_location_service.dart';

class TrackerRepository {
  final FirebaseLocationService _firebaseLocationService =
      FirebaseLocationService();

  Stream<TrackerLocation?> get locationStream {
    return _firebaseLocationService.locationStream();
  }
}