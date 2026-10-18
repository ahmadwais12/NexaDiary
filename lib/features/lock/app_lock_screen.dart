import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

import '../../core/security/encryption_service.dart';
import '../../core/utilities/responsive_utils.dart';
import '../../core/utilities/settings_state.dart';

class AppLockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  const AppLockScreen({super.key, required this.onUnlocked});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final EncryptionService _encryption = EncryptionService();
  final TextEditingController _pinController = TextEditingController();
  bool _isVerifying = false;
  String? _error;
  bool _isBiometricAvailable = false;
  bool _biometricAttempted = false;
  List<BiometricType> _availableBiometrics = [];

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final settings = context.read<SettingsState>();
    if (!settings.appLockUseBiometric) return;

    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      final available = await _localAuth.getAvailableBiometrics();

      setState(() {
        _availableBiometrics = available;
        _isBiometricAvailable = canCheck && isDeviceSupported && available.isNotEmpty;
      });

      if (_isBiometricAvailable && !_biometricAttempted) {
        _biometricAttempted = true;
        await _tryBiometric();
      }
    } catch (_) {
      setState(() {
        _isBiometricAvailable = false;
      });
    }
  }

  String _getBiometricName() {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    }
    return 'Biometric';
  }

  IconData _getBiometricIcon() {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return Icons.face_rounded;
    } else if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return Icons.fingerprint_rounded;
    }
    return Icons.security_rounded;
  }

  Future<void> _tryBiometric() async {
    if (!_isBiometricAvailable) return;

    try {
      final didAuth = await _localAuth.authenticate(
        localizedReason: 'Authenticate to unlock NexaDiary',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );

      if (didAuth && mounted) {
        widget.onUnlocked();
      }
    } catch (e) {
      // Biometric authentication failed, user can try PIN
      if (mounted) {
        setState(() {
          _error = null;
        });
      }
    }
  }

  Future<void> _verifyPin() async {
    final settings = context.read<SettingsState>();
    final pin = _pinController.text;

    if (pin.length < 4) {
      setState(() => _error = 'PIN must be at least 4 digits');
      return;
    }

    setState(() {
      _isVerifying = true;
      _error = null;
    });

    try {
      final verified = await _encryption.verifyPin(pin, settings.appLockPinHash);
      if (!mounted) return;

      if (verified) {
        widget.onUnlocked();
      } else {
        setState(() {
          _error = 'Incorrect PIN. Please try again.';
          _isVerifying = false;
        });
        _pinController.clear();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Verification failed. Please try again.';
          _isVerifying = false;
        });
      }
    }
  }

  void _goToSetup() {
    Navigator.pushReplacementNamed(context, '/app-lock-setup');
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils(context).isIpad ? 64 : (ResponsiveUtils(context).isTablet ? 48 : 32)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // === LOCK ICON ===
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [Colors.indigo.shade800, Colors.purple.shade800]
                          : [Colors.indigo.shade400, Colors.purple.shade400],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? Colors.indigo : Colors.purple)
                            .withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),

                // === TITLE ===
                Text(
                  'App Locked',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your PIN to unlock',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),

                // === PIN INPUT ===
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: TextField(
                    controller: _pinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 8,
                    style: const TextStyle(
                      fontSize: 28,
                      letterSpacing: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      hintText: '••••',
                      hintStyle: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.4),
                        letterSpacing: 14,
                      ),
                      counterText: '',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      errorText: _error,
                    ),
                    onSubmitted: (_) => _verifyPin(),
                  ),
                ),
                const SizedBox(height: 24),

                // === UNLOCK BUTTON ===
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: _isVerifying ? null : _verifyPin,
                    icon: _isVerifying
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.lock_open_rounded),
                    label: Text(
                      _isVerifying ? 'Verifying...' : 'Unlock',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),

                // === BIOMETRIC BUTTON ===
                if (_isBiometricAvailable) ...[
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Or use ${_getBiometricName()}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton.icon(
                            onPressed: _tryBiometric,
                            icon: Icon(_getBiometricIcon(), size: 24),
                            label: Text(
                              'Unlock with ${_getBiometricName()}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.colorScheme.primary,
                              side: BorderSide(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.5),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // === MANAGE SETTINGS LINK ===
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: _goToSetup,
                  icon: const Icon(Icons.settings_rounded, size: 18),
                  label: const Text('Manage App Lock Settings'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
