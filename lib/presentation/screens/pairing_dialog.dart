import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../state/device_state.dart';

/// Modal dialog to input and claim a 60s dynamic pairing code
class PairingDialog extends StatefulWidget {
  final DeviceState deviceState;

  const PairingDialog({super.key, required this.deviceState});

  @override
  State<PairingDialog> createState() => _PairingDialogState();
}

class _PairingDialogState extends State<PairingDialog> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  Future<void> _submit() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'يرجى إدخال رمز الربط الظاهر على شاشة الحاسوب');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final success = await widget.deviceState.pairDevice(
      code,
      customName: _nameController.text.trim(),
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم ربط الحاسوب بنجاح!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        setState(() {
          _error = widget.deviceState.errorMessage ?? 'رمز الربط غير صالح أو انتهت صلاحيته (60 ثانية)';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.qr_code_rounded, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'ربط جهاز حاسوب جديد',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'شغّل WardHelm على الحاسوب وأدخل الرمز الديناميكي الظاهر على الشاشة:',
                style: TextStyle(fontSize: 13, color: AppColors.darkTextMuted),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2),
                decoration: InputDecoration(
                  hintText: 'WH-XXXX-XX',
                  errorText: _error,
                  prefixIcon: const Icon(Icons.key_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'تسمية الجهاز (اختياري: مثلاً بي سي الألعاب)',
                  prefixIcon: Icon(Icons.edit_note_rounded),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('إلغاء'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('ربط الجهاز فوراً'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
