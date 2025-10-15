import 'package:nfc_manager/nfc_manager.dart';

// Check is NFC is available.
bool isAvailable = await NfcManager.instance.isAvailable();

// Start the session.
NfcManager.instance.startSession(
  pollingOptions: {NfcPollingOption.iso14443}, // You can also specify iso18092 and iso15693.
  onDiscovered: (NfcTag tag) async {
    // Do something with an NfcTag instance...
    print(tag);

    // Stop the session when no longer needed.
    await NfcManager.instance.stopSession();
  },
);