import 'package:cashspark/presentation/routes/app_router.dart';
import 'package:flutter/material.dart';

class ConsentPopup extends StatefulWidget {
  final String uid;
  final VoidCallback onAccepted;

  const ConsentPopup({
    super.key,
    required this.uid,
    required this.onAccepted,
  });

  @override
  State<ConsentPopup> createState() => _ConsentPopupState();
}

class _ConsentPopupState extends State<ConsentPopup> {
  bool _acceptedTerms = false;
  bool _acceptedPrivacy = false;

  bool get _canAccept => _acceptedTerms && _acceptedPrivacy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                ),
                child: Icon(
                  Icons.description_outlined,
                  size: 32,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                'Agreement Required',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                'Please read and accept our legal agreements to continue using Fun Pay.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Terms & Conditions Checkbox
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _acceptedTerms
                      ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                      : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _acceptedTerms
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      key: const Key('terms-checkbox'),
                      value: _acceptedTerms,
                      onChanged: (value) => setState(() => _acceptedTerms = value ?? false),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'I have read and agree to the',
                            style: TextStyle(fontSize: 14),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, AppRouter.terms),
                            child: Text(
                              'Terms & Conditions',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Privacy Policy Checkbox
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _acceptedPrivacy
                      ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                      : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _acceptedPrivacy
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      key: const Key('privacy-checkbox'),
                      value: _acceptedPrivacy,
                      onChanged: (value) => setState(() => _acceptedPrivacy = value ?? false),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'I have read and agree to the',
                            style: TextStyle(fontSize: 14),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, AppRouter.privacy),
                            child: Text(
                              'Privacy Policy',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Accept Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _canAccept
                      ? () {
                          widget.onAccepted();
                          Navigator.pop(context);
                        }
                      : null,
                  child: const Text(
                    'Accept & Continue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Note
              Text(
                'You must accept both agreements to continue',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
