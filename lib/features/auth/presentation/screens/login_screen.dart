import 'package:altum_view/core/design_system/app_theme.dart';
import 'package:altum_view/core/design_system/widgets.dart';
import 'package:altum_view/features/auth/controller/auth_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _clientIdCtrl = TextEditingController(text: 'nkJ1HznwgxwGBnB6');
  final _secretCtrl   = TextEditingController(text: 'm2HGxuNuzUk4JiKloTBOAlulv2odRhj9OkM6hzFKJQsSeBtcyLtYBDtGjxonfV3f');
  final _scopeCtrl    = TextEditingController(
    text: 'camera:write room:write alert:write person:write '
          'user:write group:write invitation:write person_info:write',
  );
  bool _obscureSecret = true;

  static const _scopeChips = [
    'camera:write', 'room:write', 'alert:write',
    'person:write', 'group:write', 'device:write',
  ];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ctrl = context.read<AuthController>();
    final ok = await ctrl.login(
      clientId:     _clientIdCtrl.text.trim(),
      clientSecret: _secretCtrl.text.trim(),
      scope:        _scopeCtrl.text.trim(),
    );
    if (ok && mounted) {
      // Navigation handled by the app shell listening to AuthController
    }
  }

  @override
  void dispose() {
    _clientIdCtrl.dispose();
    _secretCtrl.dispose();
    _scopeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<AuthController>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),

                // ── Brand ────────────────────────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppTheme.primary.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          CupertinoIcons.camera_viewfinder,
                          color: AppTheme.primary, size: 40,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'AltumView',
                        style: TextStyle(
                          color: AppTheme.onBackground,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Sign in with your API credentials',
                        style: TextStyle(
                          color: AppTheme.onSurfaceSub, fontSize: 15),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // ── Grant Type (read-only) ────────────────────────────────────
                const FieldLabel('Grant Type'),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'client_credentials',
                    style: TextStyle(
                      color: AppTheme.onSurfaceSub,
                      fontSize: 15,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Client ID ─────────────────────────────────────────────────
                const FieldLabel('Client ID'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _clientIdCtrl,
                  style: const TextStyle(
                      color: AppTheme.onSurface, fontSize: 15),
                  autocorrect: false,
                  decoration: const InputDecoration(
                    hintText: 'e.g. nkJ1HznwgxwGBnB6',
                    prefixIcon: Icon(
                      CupertinoIcons.person_crop_circle,
                      color: AppTheme.primary,
                    ),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Client ID is required'
                      : null,
                ),

                const SizedBox(height: 20),

                // ── Client Secret ─────────────────────────────────────────────
                const FieldLabel('Client Secret'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _secretCtrl,
                  obscureText: _obscureSecret,
                  style: const TextStyle(
                      color: AppTheme.onSurface, fontSize: 15),
                  autocorrect: false,
                  decoration: InputDecoration(
                    hintText: 'Your client secret',
                    prefixIcon: const Icon(
                      CupertinoIcons.lock_fill,
                      color: AppTheme.primary,
                    ),
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _obscureSecret = !_obscureSecret),
                      icon: Icon(
                        _obscureSecret
                            ? CupertinoIcons.eye
                            : CupertinoIcons.eye_slash,
                        color: AppTheme.onSurfaceSub,
                        size: 20,
                      ),
                    ),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Client secret is required'
                      : null,
                ),

                const SizedBox(height: 20),

                // ── Scope ─────────────────────────────────────────────────────
                const FieldLabel('Scope'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _scopeCtrl,
                  style: const TextStyle(
                      color: AppTheme.onSurface, fontSize: 13),
                  maxLines: 3,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    hintText: 'camera:write room:write …',
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 40),
                      child: Icon(
                        CupertinoIcons.shield_lefthalf_fill,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Scope is required'
                      : null,
                ),

                const SizedBox(height: 12),

                // ── Scope chips ───────────────────────────────────────────────
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _scopeChips
                      .map((s) => _ScopeChip(
                            label: s,
                            onTap: () {
                              final cur = _scopeCtrl.text;
                              if (!cur.contains(s)) {
                                _scopeCtrl.text =
                                    cur.isEmpty ? s : '$cur $s';
                              }
                            },
                          ))
                      .toList(),
                ),

                const SizedBox(height: 32),

                // ── Error ─────────────────────────────────────────────────────
                if (ctrl.error != null) ...[
                  ErrorBanner(ctrl.error!),
                  const SizedBox(height: 16),
                ],

                // ── Sign In ───────────────────────────────────────────────────
                PrimaryButton(
                  label: 'Sign In',
                  loading: ctrl.isLoading,
                  onPressed: _submit,
                ),

                const SizedBox(height: 20),

                Center(
                  child: Text(
                    'Credentials are used only to obtain an access token\n'
                    'and are never stored.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.onSurfaceSub.withOpacity(0.6),
                      fontSize: 12,
                      height: 1.6,
                    ),
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

class _ScopeChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ScopeChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.primary.withOpacity(0.25)),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.primary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
}
