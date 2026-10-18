import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

import '../../core/security/encryption_service.dart';
import '../../core/utilities/responsive_utils.dart';
import '../../core/utilities/settings_state.dart';

class AppLockSetupScreen extends StatefulWidget {
  const AppLockSetupScreen({super.key});

  @override
  State<AppLockSetupScreen> createState() => _AppLockSetupScreenState();
}

class _AppLockSetupScreenState extends State<AppLockSetupScreen> {
  final EncryptionService _encryption = EncryptionService();
  final LocalAuthentication _localAuth = LocalAuthentication();
  final TextEditingController _currentPinController = TextEditingController();
  final TextEditingController _newPinController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _isBiometricAvailable = false;
  bool _useBiometric = false;
  bool _isCheckingBiometric = true;
  String? _error;
  List<BiometricType> _availableBiometrics = [];
  int _step = 1; // 1: current pin, 2: new pin, 3: confirm pin (for change flow)

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsState>();
    _useBiometric = settings.appLockUseBiometric;
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      final available = await _localAuth.getAvailableBiometrics();

      setState(() {
        _availableBiometrics = available;
        _isBiometricAvailable = canCheck && isDeviceSupported && available.isNotEmpty;
        _isCheckingBiometric = false;
      });
    } catch (e) {
      setState(() {
        _isBiometricAvailable = false;
        _isCheckingBiometric = false;
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

  Future<void> _setupPin() async {
    final settings = context.read<SettingsState>();
    final isNewSetup = !settings.isAppLockEnabled;

    if (isNewSetup) {
      // New setup flow
      final pin = _newPinController.text;
      final confirm = _confirmController.text;

      if (pin.length < 4) {
        setState(() => _error = 'PIN must be at least 4 digits');
        return;
      }
      if (pin != confirm) {
        setState(() => _error = 'PINs do not match');
        return;
      }

      final hash = await _encryption.hashPin(pin);
      await settings.setAppLock(
        enabled: true,
        pinHash: hash,
        useBiometric: _useBiometric && _isBiometricAvailable,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('App lock enabled successfully')),
        );
        Navigator.pop(context);
      }
    } else {
      // Change PIN flow - verify current PIN first
      final currentPin = _currentPinController.text;
      final newPin = _newPinController.text;
      final confirm = _confirmController.text;

      if (_step == 1) {
        // Verify current PIN
        if (currentPin.length < 4) {
          setState(() => _error = 'PIN must be at least 4 digits');
          return;
        }

        final verified = await _encryption.verifyPin(currentPin, settings.appLockPinHash);
        if (!verified) {
          setState(() => _error = 'Current PIN is incorrect');
          return;
        }

        setState(() {
          _step = 2;
          _error = null;
          _currentPinController.clear();
        });
      } else if (_step == 2) {
        // Enter new PIN
        if (newPin.length < 4) {
          setState(() => _error = 'PIN must be at least 4 digits');
          return;
        }

        setState(() {
          _step = 3;
          _error = null;
          _newPinController.clear();
        });
      } else if (_step == 3) {
        // Confirm new PIN
        if (confirm.length < 4) {
          setState(() => _error = 'PIN must be at least 4 digits');
          return;
        }
        if (confirm != newPin) {
          setState(() => _error = 'PINs do not match');
          return;
        }

        final hash = await _encryption.hashPin(confirm);
        await settings.setAppLock(
          enabled: true,
          pinHash: hash,
          useBiometric: _useBiometric && _isBiometricAvailable,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PIN updated successfully')),
          );
          Navigator.pop(context);
        }
      }
    }
  }

  Future<void> _removePin() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove App Lock?'),
        content: const Text('This will disable app lock and remove your PIN.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final settings = context.read<SettingsState>();
      await settings.setAppLock(enabled: false, pinHash: '', useBiometric: false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('App lock removed')),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _testBiometric() async {
    try {
      final didAuth = await _localAuth.authenticate(
        localizedReason: 'Test biometric authentication',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(didAuth
                ? 'Biometric authentication works!'
                : 'Biometric authentication cancelled'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Biometric error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _currentPinController.dispose();
    _newPinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsState>();
    final isDark = theme.brightness == Brightness.dark;
    final isChangeFlow = settings.isAppLockEnabled;

    return Scaffold(
      appBar: AppBar(
        title: Text(isChangeFlow ? 'Change App Lock PIN' : 'Set Up App Lock'),
      ),
      body: Builder(
        builder: (context) {
          final r = ResponsiveUtils(context);
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: r.maxContentWidth),
              child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // === HEADER ICON ===
            Center(
              child: Container(
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
                child: Icon(
                  isChangeFlow ? Icons.pin_rounded : Icons.lock_rounded,
                  size: 48,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // === TITLE ===
            Text(
              isChangeFlow ? 'Change Your PIN' : 'Secure Your Workspace',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isChangeFlow
                  ? _getStepSubtitle(_step)
                  : 'Set a PIN to protect your notes, files, and vault',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // === PIN INPUT FIELDS ===
            if (isChangeFlow) ...[
              // Step indicator for change flow
              _buildStepIndicator(_step, theme),
              const SizedBox(height: 24),

              if (_step == 1) ...[
                _buildSectionHeader('Current PIN', theme),
                const SizedBox(height: 12),
                _buildPinField(
                  controller: _currentPinController,
                  hint: 'Enter current PIN',
                  theme: theme,
                ),
              ] else if (_step == 2) ...[
                _buildSectionHeader('New PIN', theme),
                const SizedBox(height: 12),
                _buildPinField(
                  controller: _newPinController,
                  hint: 'Enter new PIN',
                  theme: theme,
                ),
              ] else if (_step == 3) ...[
                _buildSectionHeader('Confirm New PIN', theme),
                const SizedBox(height: 12),
                _buildPinField(
                  controller: _confirmController,
                  hint: 'Confirm new PIN',
                  theme: theme,
                ),
              ],
            ] else ...[
              // New setup flow
              _buildSectionHeader('New PIN', theme),
              const SizedBox(height: 12),
              _buildPinField(
                controller: _newPinController,
                hint: 'Enter PIN',
                theme: theme,
              ),
              const SizedBox(height: 12),
              _buildPinField(
                controller: _confirmController,
                hint: 'Confirm PIN',
                theme: theme,
              ),
            ],

            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // === BIOMETRIC SECTION ===
            if (!_isCheckingBiometric && !isChangeFlow) ...[
              const SizedBox(height: 24),
              _buildSectionHeader('Biometric Authentication', theme),
              const SizedBox(height: 12),
              if (_isBiometricAvailable)
                _buildBiometricCard(theme)
              else
                _buildBiometricUnavailableCard(theme),
            ],

            const SizedBox(height: 32),

            // === ACTION BUTTONS ===
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: _setupPin,
                icon: Icon(isChangeFlow ? Icons.check_rounded : Icons.lock_rounded),
                label: Text(
                  isChangeFlow
                      ? (_step == 3 ? 'Update PIN' : 'Continue')
                      : 'Enable App Lock',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            if (isChangeFlow) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: _removePin,
                  icon: const Icon(Icons.lock_open_rounded),
                  label: const Text(
                    'Remove App Lock',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
},
),
);
  }

  String _getStepSubtitle(int step) {
    switch (step) {
      case 1:
        return 'Enter your current PIN to continue';
      case 2:
        return 'Enter your new 4-digit PIN';
      case 3:
        return 'Re-enter your new PIN to confirm';
      default:
        return '';
    }
  }

  Widget _buildStepIndicator(int currentStep, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final step = index + 1;
        final isActive = step <= currentStep;
        final isCurrent = step == currentStep;

        return Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                border: isCurrent
                    ? Border.all(color: theme.colorScheme.primary, width: 2)
                    : null,
              ),
              child: Center(
                child: Text(
                  '$step',
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            if (index < 2)
              Container(
                width: 40,
                height: 2,
                color: step < currentStep
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
              ),
          ],
        );
      }),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.primary,
        fontSize: 14,
      ),
    );
  }

  Widget _buildPinField({
    required TextEditingController controller,
    required String hint,
    required ThemeData theme,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: TextField(
        controller: controller,
        obscureText: true,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 8,
        style: const TextStyle(
          fontSize: 24,
          letterSpacing: 12,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            letterSpacing: 4,
            fontSize: 16,
          ),
          counterText: '',
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildBiometricCard(ThemeData theme) {
    final biometricName = _getBiometricName();
    final biometricIcon = _getBiometricIcon();

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    biometricIcon,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Use $biometricName',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Quickly unlock with $biometricName',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _useBiometric,
                  onChanged: (v) => setState(() => _useBiometric = v),
                ),
              ],
            ),
            if (_useBiometric) ...[
              const Divider(height: 24),
              TextButton.icon(
                onPressed: _testBiometric,
                icon: const Icon(Icons.touch_app_rounded, size: 18),
                label: const Text('Test biometric authentication'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBiometricUnavailableCard(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.fingerprint_rounded,
                color: Colors.grey.shade400,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Biometric not available',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Set up fingerprint or face unlock in your device settings',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
