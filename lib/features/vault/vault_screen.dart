import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/security/encryption_service.dart';
import '../../core/utilities/responsive_utils.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  static const int _pinLength = 4;

  final LocalAuthentication _localAuth = LocalAuthentication();
  final EncryptionService _encryption = EncryptionService();
  bool _isUnlocked = false;
  bool _hasPinSet = false;
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;
  bool _isAuthenticatingBiometric = false;
  bool _isLoading = true;
  String _enteredPin = '';
  bool _isSettingPin = false;
  bool _isChangingPin = false;
  String _confirmPin = '';
  String? _sessionPin;
  List<BiometricType> _availableBiometrics = [];

  @override
  void initState() {
    super.initState();
    _checkVaultStatus();
  }

  Future<void> _checkVaultStatus() async {
    final pinHash = await database.getSetting('vault_pin_hash');
    final biometricEnabled = await database.getSetting('vault_biometric_enabled');
    final isBiometricAvailable = await _canUseBiometrics();
    final availableBiometrics = await _getAvailableBiometrics();

    if (!mounted) return;
    setState(() {
      _hasPinSet = pinHash != null && pinHash.isNotEmpty;
      _isBiometricEnabled = biometricEnabled == 'true';
      _isBiometricAvailable = isBiometricAvailable;
      _availableBiometrics = availableBiometrics;
      _isLoading = false;
    });

    if (_hasPinSet && _isBiometricEnabled && isBiometricAvailable) {
      await _tryBiometric();
    }
  }

  Future<bool> _canUseBiometrics() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      return canCheckBiometrics &&
          isDeviceSupported &&
          availableBiometrics.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<List<BiometricType>> _getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (_) {
      return [];
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
    if (!_hasPinSet || _isAuthenticatingBiometric) return;

    try {
      final canAuth = await _canUseBiometrics();
      if (!canAuth) {
        if (mounted) {
          setState(() => _isBiometricAvailable = false);
        }
        return;
      }

      if (mounted) {
        setState(() => _isAuthenticatingBiometric = true);
      }

      final didAuth = await _localAuth.authenticate(
        localizedReason: 'Use your phone biometrics to unlock the vault',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );

      if (!didAuth || !mounted) return;

      if (_sessionPin != null) {
        await _encryption.deriveKey(_sessionPin!);
      }

      setState(() => _isUnlocked = true);
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isAuthenticatingBiometric = false);
      }
    }
  }

  Future<void> _verifyPin(String pin) async {
    final storedHash = await database.getSetting('vault_pin_hash');
    if (storedHash == null) return;

    final verified = await _encryption.verifyPin(pin, storedHash);
    if (verified) {
      await _encryption.deriveKey(pin);
      if (!mounted) return;
      setState(() {
        _sessionPin = pin;
        _isUnlocked = true;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.incorrectPin)),
        );
      }
      setState(() => _enteredPin = '');
    }
  }

  Future<void> _setPin(String pin) async {
    final hash = await _encryption.hashPin(pin);
    await database.setSetting('vault_pin_hash', hash);
    await _encryption.deriveKey(pin);
    final isBiometricAvailable = await _canUseBiometrics();
    final availableBiometrics = await _getAvailableBiometrics();

    if (!mounted) return;
    setState(() {
      _hasPinSet = true;
      _isBiometricAvailable = isBiometricAvailable;
      _availableBiometrics = availableBiometrics;
      _isUnlocked = true;
      _isSettingPin = false;
      _isChangingPin = false;
      _enteredPin = '';
      _confirmPin = '';
      _sessionPin = pin;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN updated successfully')),
      );
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value && !_isBiometricAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biometric not available on this device')),
      );
      return;
    }

    await database.setSetting('vault_biometric_enabled', value.toString());
    setState(() => _isBiometricEnabled = value);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? 'Biometric enabled' : 'Biometric disabled'),
        ),
      );
    }
  }

  void _startChangePin() {
    setState(() {
      _isChangingPin = true;
      _isSettingPin = true;
      _enteredPin = '';
      _confirmPin = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isUnlocked) {
      return _buildLockScreen();
    }

    return _buildVaultContent();
  }

  Widget _buildLockScreen() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.privateVault),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: ResponsiveUtils(context).maxContentWidth),
          child: Padding(
          padding: const EdgeInsets.all(32),
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
                        ? [Colors.red.shade800, Colors.pink.shade800]
                        : [Colors.red.shade400, Colors.pink.shade400],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? Colors.red : Colors.pink)
                          .withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              if (!_hasPinSet && !_isSettingPin) ...[
                Text(
                  AppLocalizations.of(context)!.setVaultPin,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.createPinDescription,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: () => setState(() {
                      _isSettingPin = true;
                      _enteredPin = '';
                      _confirmPin = '';
                    }),
                    icon: const Icon(Icons.pin_rounded),
                    label: Text(
                      AppLocalizations.of(context)!.createPin,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ] else if (_isSettingPin) ...[
                Text(
                  _confirmPin.isEmpty
                      ? (_isChangingPin
                          ? 'Enter new PIN'
                          : AppLocalizations.of(context)!.enterNewPin)
                      : AppLocalizations.of(context)!.confirmPin,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _confirmPin.isEmpty
                      ? 'Enter a 4-digit PIN'
                      : 'Re-enter your PIN to confirm',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500),
                ),
                const SizedBox(height: 32),
                _buildPinDots(_enteredPin.length),
                const SizedBox(height: 32),
                _buildPinPad(),
              ] else ...[
                Text(
                  AppLocalizations.of(context)!.enterPin,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your vault PIN to unlock',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500),
                ),
                const SizedBox(height: 32),
                _buildPinDots(_enteredPin.length),
                const SizedBox(height: 32),
                _buildPinPad(),
                if (_isBiometricAvailable && _isBiometricEnabled) ...[
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
                            onPressed: _isAuthenticatingBiometric
                                ? null
                                : _tryBiometric,
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
              ],
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildPinDots(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pinLength, (i) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i < count
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.5),
          ),
        );
      }),
    );
  }

  Widget _buildPinPad() {
    return Column(
      children: [
        for (var row = 0; row < 3; row++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var col = 0; col < 3; col++) ...[
                  if (row == 2 && col == 0)
                    const SizedBox(width: 72)
                  else if (row == 2 && col == 1)
                    _buildPinButton('0', () => _onPinDigit('0'))
                  else if (row == 2 && col == 2)
                    _buildPinButton('⌫', () {
                      if (_enteredPin.isNotEmpty) {
                        setState(() {
                          _enteredPin = _enteredPin.substring(
                            0,
                            _enteredPin.length - 1,
                          );
                        });
                      }
                    })
                  else
                    _buildPinButton(
                      '${row * 3 + col + 1}',
                      () => _onPinDigit('${row * 3 + col + 1}'),
                    ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPinButton(String label, VoidCallback onTap) {
    final r = ResponsiveUtils(context);
    final size = r.isIpad ? 80.0 : (r.isTablet ? 72.0 : 64.0);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.5),
        ),
        child: Center(
          child: Text(label, style: Theme.of(context).textTheme.headlineSmall),
        ),
      ),
    );
  }

  void _onPinDigit(String digit) {
    if (_enteredPin.length >= _pinLength) return;

    setState(() => _enteredPin += digit);

    if (_enteredPin.length >= _pinLength) {
      if (_isSettingPin) {
        if (_confirmPin.isEmpty) {
          setState(() {
            _confirmPin = _enteredPin;
            _enteredPin = '';
          });
        } else {
          if (_enteredPin == _confirmPin) {
            _setPin(_enteredPin);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.pinsDoNotMatch),
              ),
            );
            setState(() {
              _enteredPin = '';
              _confirmPin = '';
            });
          }
        }
      } else {
        _verifyPin(_enteredPin);
      }
    }
  }

  Widget _buildVaultContent() {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.privateVault),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_rounded),
              onPressed: _showSettingsMenu,
            ),
            IconButton(
              icon: const Icon(Icons.lock),
              onPressed: () {
                _encryption.lock();
                setState(() {
                  _isUnlocked = false;
                  _enteredPin = '';
                });
              },
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(
                icon: const Icon(Icons.note),
                text: AppLocalizations.of(context)!.notes,
              ),
              Tab(
                icon: const Icon(Icons.image),
                text: AppLocalizations.of(context)!.images,
              ),
              Tab(
                icon: const Icon(Icons.videocam),
                text: AppLocalizations.of(context)!.videos,
              ),
              Tab(
                icon: const Icon(Icons.folder),
                text: AppLocalizations.of(context)!.files,
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _VaultNotesTab(),
            _VaultImagesTab(),
            _VaultVideosTab(),
            _VaultFilesTab(),
          ],
        ),
      ),
    );
  }

  void _showSettingsMenu() {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // === HEADER ===
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Vault Settings',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // === CHANGE PIN ===
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.pin_rounded, color: Colors.blue),
                ),
                title: const Text('Change PIN'),
                subtitle: Text(
                  'Update your vault PIN',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
                trailing: Icon(Icons.chevron_right_rounded,
                    color: Colors.grey.shade400),
                onTap: () {
                  Navigator.pop(ctx);
                  _startChangePin();
                },
              ),

              // === BIOMETRIC TOGGLE ===
              if (_isBiometricAvailable)
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_getBiometricIcon(), color: Colors.green),
                  ),
                  title: Text('Unlock with ${_getBiometricName()}'),
                  subtitle: Text(
                    _isBiometricEnabled ? 'Enabled' : 'Disabled',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                  trailing: Switch.adaptive(
                    value: _isBiometricEnabled,
                    onChanged: (value) {
                      Navigator.pop(ctx);
                      _toggleBiometric(value);
                    },
                  ),
                ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _VaultNotesTab extends StatelessWidget {
  const _VaultNotesTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.note_add, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.tapToAddNoteToVault),
        ],
      ),
    );
  }
}

class _VaultImagesTab extends StatelessWidget {
  const _VaultImagesTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add_photo_alternate, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.tapToAddImagesToVault),
        ],
      ),
    );
  }
}

class _VaultVideosTab extends StatelessWidget {
  const _VaultVideosTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.videocam, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.tapToAddVideosToVault),
        ],
      ),
    );
  }
}

class _VaultFilesTab extends StatelessWidget {
  const _VaultFilesTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_open, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.tapToAddFilesToVault),
        ],
      ),
    );
  }
}
