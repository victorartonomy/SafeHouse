package com.victorartonomy.safe_house

import io.flutter.embedding.android.FlutterFragmentActivity

// Extends FlutterFragmentActivity (not FlutterActivity) so that local_auth
// can host the BiometricPrompt FragmentDialog used by the History screen's
// biometric gate.
class MainActivity : FlutterFragmentActivity()
