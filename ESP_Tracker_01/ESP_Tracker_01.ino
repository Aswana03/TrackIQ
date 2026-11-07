
#include <WiFi.h>
#include <HTTPClient.h>
#include <TinyGPSPlus.h>
#include <HardwareSerial.h>
#include <time.h>
#include <ArduinoJson.h>

// =====================================================
// Wi-Fi
// =====================================================

const char* WIFI_SSID = "Aswana_03";
const char* WIFI_PASSWORD = "Ashu310__";

// =====================================================
// Firebase Configuration
// =====================================================

const char* FIREBASE_URL =
    "https://trackiq-development-default-rtdb.firebaseio.com";

const char* FIREBASE_API_KEY = "AIzaSyDsWbQR0iGor_kJ6PZ7unPmM7YqKoozjxs";
const char* FIREBASE_EMAIL = "aswanan2005@gmail.com";
const char* FIREBASE_PASSWORD = "12345678";

// Firebase authentication tokens
String firebaseIdToken = "";
String firebaseRefreshToken = "";

unsigned long tokenExpiryTime = 0;

// =====================================================
// GPS
// =====================================================

TinyGPSPlus gps;
HardwareSerial GPS_Serial(2);

#define GPS_RX 16
#define GPS_TX 17

// =====================================================
// Timing
// =====================================================

unsigned long lastFirebaseUpdate = 0;
const unsigned long FIREBASE_INTERVAL = 5000;

// =====================================================
// Function declarations
// =====================================================

bool signInToFirebase();
bool ensureFirebaseToken();
bool refreshFirebaseToken();
void sendToFirebase();

// =====================================================
// Firebase Email/Password Sign-in
// =====================================================

bool signInToFirebase() {
  HTTPClient http;

  String url =
      "https://identitytoolkit.googleapis.com/v1/"
      "accounts:signInWithPassword?key=" +
      String(FIREBASE_API_KEY);

  http.begin(url);
  http.addHeader("Content-Type", "application/json");

  StaticJsonDocument<512> request;

  request["email"] = FIREBASE_EMAIL;
  request["password"] = FIREBASE_PASSWORD;
  request["returnSecureToken"] = true;

  String body;
  serializeJson(request, body);

  Serial.println("Signing in to Firebase...");

  int code = http.POST(body);
  String response = http.getString();

  http.end();

  if (code != 200) {
    Serial.printf("Firebase sign-in failed: HTTP %d\n", code);
    Serial.println(response);
    return false;
  }

  StaticJsonDocument<4096> result;

  DeserializationError error = deserializeJson(result, response);

  if (error ||
      result["idToken"].isNull() ||
      result["refreshToken"].isNull()) {
    Serial.println("Invalid Firebase sign-in response.");
    return false;
  }

  firebaseIdToken = result["idToken"].as<String>();
  firebaseRefreshToken = result["refreshToken"].as<String>();

  unsigned long expiresIn =
      String(result["expiresIn"].as<const char*>()).toInt();

  tokenExpiryTime = millis() + expiresIn * 1000UL;

  Serial.println("Firebase sign-in successful!");

  return true;
}

// =====================================================
// Refresh Firebase ID Token
// =====================================================

bool refreshFirebaseToken() {
  if (firebaseRefreshToken.length() == 0) {
    return signInToFirebase();
  }

  HTTPClient http;

  String url =
      "https://securetoken.googleapis.com/v1/token?key=" +
      String(FIREBASE_API_KEY);

  http.begin(url);

  http.addHeader(
      "Content-Type",
      "application/x-www-form-urlencoded"
  );

  String body =
      "grant_type=refresh_token&refresh_token=" +
      firebaseRefreshToken;

  int code = http.POST(body);
  String response = http.getString();

  http.end();

  if (code != 200) {
    Serial.printf("Firebase token refresh failed: HTTP %d\n", code);
    Serial.println(response);

    firebaseIdToken = "";
    firebaseRefreshToken = "";

    return signInToFirebase();
  }

  StaticJsonDocument<4096> result;

  DeserializationError error = deserializeJson(result, response);

  if (error ||
      result["id_token"].isNull() ||
      result["refresh_token"].isNull()) {
    Serial.println("Invalid token refresh response.");
    return false;
  }

  firebaseIdToken = result["id_token"].as<String>();
  firebaseRefreshToken = result["refresh_token"].as<String>();

  unsigned long expiresIn =
      String(result["expires_in"].as<const char*>()).toInt();

  tokenExpiryTime = millis() + expiresIn * 1000UL;

  Serial.println("Firebase token refreshed.");

  return true;
}

// =====================================================
// Ensure a valid Firebase ID Token
// =====================================================

bool ensureFirebaseToken() {
  if (firebaseIdToken.length() == 0) {
    return signInToFirebase();
  }

  // Refresh one minute before token expiry.
  if ((long)(tokenExpiryTime - millis()) <= 60000L) {
    return refreshFirebaseToken();
  }

  return true;
}

// =====================================================
// Setup
// =====================================================

void setup() {
  Serial.begin(115200);

  GPS_Serial.begin(
      9600,
      SERIAL_8N1,
      GPS_RX,
      GPS_TX
  );

  Serial.println();
  Serial.println("================================");
  Serial.println("       TrackIQ ESP32");
  Serial.println("   GPS + Firebase Tracker");
  Serial.println("================================");

  // Connect to Wi-Fi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  Serial.print("Connecting to Wi-Fi");

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println();
  Serial.println("Wi-Fi connected!");

  Serial.print("ESP32 IP: ");
  Serial.println(WiFi.localIP());

  // Configure NTP time
  configTime(
      0,
      0,
      "pool.ntp.org",
      "time.nist.gov"
  );

  Serial.println("Waiting for GPS fix...");

  // Authenticate with Firebase
  if (!signInToFirebase()) {
    Serial.println(
        "Initial Firebase sign-in failed. "
        "The ESP32 will retry during updates."
    );
  }
}

// =====================================================
// Main Loop
// =====================================================

void loop() {
  // Read GPS data
  while (GPS_Serial.available() > 0) {
    gps.encode(GPS_Serial.read());
  }

  if (gps.location.isValid()) {
    Serial.println();
    Serial.println("--------------------------------");

    Serial.println("GPS Fix: YES");

    Serial.print("Latitude: ");
    Serial.println(gps.location.lat(), 6);

    Serial.print("Longitude: ");
    Serial.println(gps.location.lng(), 6);

    Serial.print("Altitude: ");
    Serial.print(gps.altitude.meters());
    Serial.println(" m");

    Serial.print("Speed: ");
    Serial.print(gps.speed.kmph());
    Serial.println(" km/h");

    Serial.print("Satellites: ");
    Serial.println(gps.satellites.value());

    Serial.print("HDOP: ");
    Serial.println(gps.hdop.hdop());

    Serial.println("--------------------------------");

    if (millis() - lastFirebaseUpdate >=
        FIREBASE_INTERVAL) {
      lastFirebaseUpdate = millis();
      sendToFirebase();
    }
  } else {
    Serial.println("Waiting for GPS fix...");
  }

  delay(100);
}

// =====================================================
// Send Current Location and History to Firebase
// =====================================================

void sendToFirebase() {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("Wi-Fi disconnected!");
    return;
  }

  // Ensure authentication before database requests
  if (!ensureFirebaseToken()) {
    Serial.println("Firebase authentication unavailable.");
    return;
  }

  // ---------------------------------------------------
  // Create timestamp
  // ---------------------------------------------------

  struct tm timeinfo;
  char timestamp[30];

  if (getLocalTime(&timeinfo, 5000)) {
    strftime(
        timestamp,
        sizeof(timestamp),
        "%Y-%m-%dT%H:%M:%SZ",
        &timeinfo
    );
  } else {
    Serial.println("NTP time not available.");
    return;
  }

  // ---------------------------------------------------
  // Create GPS JSON
  // ---------------------------------------------------

  StaticJsonDocument<512> location;

  location["latitude"] = gps.location.lat();
  location["longitude"] = gps.location.lng();
  location["speed"] = gps.speed.kmph();
  location["timestamp"] = timestamp;
  location["gpsActive"] = gps.location.isValid();

  // No battery measurement hardware is connected.
  // Keep this field only for compatibility with the app.
  location["battery"] = 100;

  location["isOnline"] = true;

  // Actual Wi-Fi RSSI classification
  int rssi = WiFi.RSSI();

  String signalStrength;

  if (rssi >= -60) {
    signalStrength = "Strong";
  } else if (rssi >= -75) {
    signalStrength = "Medium";
  } else {
    signalStrength = "Weak";
  }

  location["signalStrength"] = signalStrength;

  String json;
  serializeJson(location, json);

  // ---------------------------------------------------
  // 1. Update CURRENT location
  // ---------------------------------------------------

  HTTPClient currentHttp;

  String currentUrl =
      String(FIREBASE_URL) +
      "/trackers/trackiq.json?auth=" +
      firebaseIdToken;

  currentHttp.begin(currentUrl);

  currentHttp.addHeader(
      "Content-Type",
      "application/json"
  );

  Serial.println();
  Serial.println("Updating current location...");

  int currentCode = currentHttp.PATCH(json);
  String currentResponse = currentHttp.getString();

  Serial.print("Current location HTTP code: ");
  Serial.println(currentCode);

  if (currentCode == 200) {
    Serial.println("Current location updated!");
  } else {
    Serial.println("Current location update FAILED.");
    Serial.println(currentResponse);
  }

  currentHttp.end();

  // ---------------------------------------------------
  // 2. Save location to HISTORY
  // ---------------------------------------------------

  HTTPClient historyHttp;

  String historyUrl =
      String(FIREBASE_URL) +
      "/trackers/trackiq/history.json?auth=" +
      firebaseIdToken;

  historyHttp.begin(historyUrl);

  historyHttp.addHeader(
      "Content-Type",
      "application/json"
  );

  Serial.println("Saving location to history...");

  int historyCode = historyHttp.POST(json);
  String historyResponse = historyHttp.getString();

  Serial.print("History HTTP code: ");
  Serial.println(historyCode);

  if (historyCode == 200) {
    Serial.println("History location saved!");
    Serial.println(historyResponse);
  } else {
    Serial.println("History save FAILED.");
    Serial.println(historyResponse);
  }

  historyHttp.end();

  Serial.println("--------------------------------");
}
