import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:telephony/telephony.dart';
import 'gps_service.dart';

/// Listens for incoming GPS SMS messages on Android
/// GPS devices send formatted SMS: "SERIAL,LAT,LNG,SPEED,HEADING,TS,HB=0,HA=0"
class SmsListenerService {
  static final SmsListenerService _instance = SmsListenerService._internal();
  factory SmsListenerService() => _instance;
  SmsListenerService._internal();

  final Telephony _telephony = Telephony.instance;
  final GpsService _gpsService = GpsService();

  // Registered GPS phone numbers to accept SMS from (whitelist)
  final Set<String> _allowedSenders = {};

  bool _initialized = false;

  Future<void> initialize({List<String> allowedSenders = const []}) async {
    if (kIsWeb) return; // SMS not available on web
    if (_initialized) return;

    _allowedSenders.addAll(allowedSenders);

    // Request SMS permission
    final granted = await _telephony.requestPhoneAndSmsPermissions;
    if (granted != true) {
      debugPrint('[SMS] Permission denied');
      return;
    }

    // Listen to incoming SMS
    _telephony.listenIncomingSms(
      onNewMessage: _onSmsReceived,
      onBackgroundMessage: _backgroundSmsHandler,
    );

    _initialized = true;
    debugPrint('[SMS] Listener initialized. Waiting for GPS packets...');
  }

  void addAllowedSender(String phoneNumber) {
    _allowedSenders.add(phoneNumber);
  }

  void _onSmsReceived(SmsMessage message) {
    final sender = message.address ?? '';
    final body = message.body ?? '';

    debugPrint('[SMS] Received from $sender: $body');

    // Filter by whitelist (if configured)
    if (_allowedSenders.isNotEmpty && !_allowedSenders.contains(sender)) {
      debugPrint('[SMS] Sender $sender not in whitelist, ignoring');
      return;
    }

    // Must look like a GPS packet (contains commas and a known pattern)
    if (!_looksLikeGpsPacket(body)) {
      debugPrint('[SMS] Not a GPS packet, ignoring');
      return;
    }

    _gpsService.ingestSms(sender, body);
  }

  bool _looksLikeGpsPacket(String body) {
    // Must have at least 5 comma-separated values
    final parts = body.split(',');
    if (parts.length < 5) return false;
    // Second and third parts should be numeric (lat/lng)
    if (double.tryParse(parts[1].trim()) == null) return false;
    if (double.tryParse(parts[2].trim()) == null) return false;
    return true;
  }
}

/// Background SMS handler (top-level function required by telephony package)
@pragma('vm:entry-point')
void _backgroundSmsHandler(SmsMessage message) {
  final body = message.body ?? '';
  final sender = message.address ?? '';
  debugPrint('[SMS-BG] Background SMS from $sender: $body');
  // Note: Background processing is limited; main processing happens in foreground
}
