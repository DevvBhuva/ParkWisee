import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parkwise/features/profile/models/profile_models.dart';
import 'package:parkwise/features/profile/services/payment_firestore_service.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final PaymentFirestoreService _firestoreService = PaymentFirestoreService();
  late Stream<List<PaymentMethod>> _paymentsStream;

  @override
  void initState() {
    super.initState();
    _paymentsStream = _firestoreService.getPaymentsStream();
  }

  void _showPaymentDialog({PaymentMethod? method}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.center,
          child: _PaymentDialog(
            method: method,
            onSave: (paymentMethod) async {
              if (method == null) {
                await _firestoreService.addPaymentMethod(paymentMethod);
              } else {
                // For update, we keep the ID but update other fields
                final updated = PaymentMethod(
                  id: method.id,
                  category: paymentMethod.category,
                  type: paymentMethod.type,
                  maskedNumber: paymentMethod.maskedNumber,
                  expiryDate: paymentMethod.expiryDate,
                  cardHolderName: paymentMethod.cardHolderName,
                  upiId: paymentMethod.upiId,
                );
                await _firestoreService.updatePaymentMethod(updated);
              }
            },
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          alignment: Alignment.bottomRight,
          child: child,
        );
      },
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'Delete Payment Method?',
          style: GoogleFonts.outfit(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to remove this method?',
          style: GoogleFonts.outfit(color: Colors.grey.shade600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              _firestoreService.deletePaymentMethod(id);
              Navigator.pop(context);
            },
            child: Text('Delete', style: GoogleFonts.outfit(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Payment Methods',
          style: GoogleFonts.outfit(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: StreamBuilder<List<PaymentMethod>>(
        stream: _paymentsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final methods = snapshot.data ?? [];
          if (methods.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.payment, size: 60, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    "No payment methods",
                    style: GoogleFonts.outfit(
                      color: Colors.grey.shade500,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    "Tap + to add Card or UPI",
                    style: GoogleFonts.outfit(color: Colors.grey.shade400),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: methods.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final method = methods[index];
              return _buildPaymentCard(method);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPaymentDialog(),
        backgroundColor: Colors.black,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildPaymentCard(PaymentMethod method) {
    final isCard = method.category == 'CARD';
    final icon = isCard
        ? Icons.credit_card
        : Icons.qr_code; // Simple distinction
    final title = isCard ? method.type : 'UPI';
    final subtitle = isCard
        ? '${method.maskedNumber} • ${method.expiryDate}'
        : (method.upiId ?? 'Unknown UPI ID');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isCard ? Colors.blueGrey.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                color: isCard ? Colors.black87 : Colors.deepOrange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: Colors.grey.shade600,
                  ),
                  onPressed: () => _showPaymentDialog(method: method),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: Colors.red.shade400,
                  ),
                  onPressed: () => _confirmDelete(method.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentDialog extends StatefulWidget {
  final PaymentMethod? method;
  final Function(PaymentMethod) onSave;

  const _PaymentDialog({this.method, required this.onSave});

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  String _selectedCategory = 'CARD';

  // Controllers
  late TextEditingController _cardNumberController;
  late TextEditingController _expiryController;
  late TextEditingController _cvvController;
  late TextEditingController _holderNameController;
  late TextEditingController _upiIdController;

  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    if (widget.method != null) {
      _selectedCategory = widget.method!.category;
    }

    _cardNumberController = TextEditingController(
      text: widget.method?.maskedNumber ?? '',
    );
    _expiryController = TextEditingController(
      text: widget.method?.expiryDate ?? '',
    );
    _cvvController = TextEditingController();
    _holderNameController = TextEditingController(
      text: widget.method?.cardHolderName ?? '',
    );
    _upiIdController = TextEditingController(text: widget.method?.upiId ?? '');

    // Add listeners to validate on change
    _cardNumberController.addListener(_validate);
    _expiryController.addListener(_validate);
    _cvvController.addListener(_validate);
    _holderNameController.addListener(_validate);
    _upiIdController.addListener(_validate);

    _validate();
  }

  @override
  void dispose() {
    _cardNumberController.removeListener(_validate);
    _expiryController.removeListener(_validate);
    _cvvController.removeListener(_validate);
    _holderNameController.removeListener(_validate);
    _upiIdController.removeListener(_validate);

    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _holderNameController.dispose();
    _upiIdController.dispose();
    super.dispose();
  }

  void _validate() {
    setState(() {
      if (_selectedCategory == 'CARD') {
        final number = _cardNumberController.text.replaceAll(' ', '');
        final expiry = _expiryController.text;
        final cvv = _cvvController.text;
        final name = _holderNameController.text;

        // Validation logic
        bool isNumberValid = number.length >= 12 && number.length <= 16;
        bool isExpiryValid = expiry.length == 5;
        bool isCvvValid = cvv.length == 3;
        bool isNameValid =
            name.isNotEmpty && RegExp(r'^[a-zA-Z\s]+$').hasMatch(name);

        _isValid = isNumberValid && isExpiryValid && isCvvValid && isNameValid;
      } else {
        _isValid =
            _upiIdController.text.isNotEmpty &&
            _upiIdController.text.contains('@');
      }
    });
  }

  // Errors for feedback
  String? get _numberErrorText {
    final text = _cardNumberController.text.replaceAll(' ', '');
    if (text.isEmpty) return null; // Don't show error immediately
    if (text.length < 12) return 'Min 12 digits required';
    if (text.length > 16) return 'Max 16 digits allowed';
    return null;
  }

  String? get _expiryErrorText {
    final text = _expiryController.text;
    if (text.isEmpty) return null;
    if (text.length < 5) return 'Format MM/YY required';
    // Basic month/year validation
    final parts = text.split('/');
    if (parts.length == 2) {
      final month = int.tryParse(parts[0]);
      final year = int.tryParse(parts[1]);
      if (month == null || year == null || month < 1 || month > 12) {
        return 'Invalid month';
      }
      // Simple year check, assuming 2-digit year
      final currentYear = DateTime.now().year % 100;
      if (year < currentYear || year > currentYear + 10) {
        // e.g., valid for next 10 years
        return 'Invalid year';
      }
    }
    return null;
  }

  String? get _cvvErrorText {
    final text = _cvvController.text;
    if (text.isEmpty) return null;
    if (text.length < 3) return '3 digits required';
    return null;
  }

  String? get _nameErrorText {
    final text = _holderNameController.text;
    if (text.isEmpty) return null;
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(text)) return 'Alphabets only';
    return null;
  }

  String? get _upiIdErrorText {
    final text = _upiIdController.text;
    if (text.isEmpty) return null;
    if (!text.contains('@')) return 'Invalid UPI ID format';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isKeyboardOpen = mediaQuery.viewInsets.bottom > 0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.9),
        child: SingleChildScrollView(
          // Clamping physics + simple column usually works best for "stop when done"
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.method == null ? 'Add Payment Method' : 'Edit Method',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              if (widget.method == null) ...[
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _buildToggleOption('Card', 'CARD'),
                      _buildToggleOption('UPI', 'UPI'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              if (_selectedCategory == 'CARD')
                _buildCardForm()
              else
                _buildUpiForm(),

              // Show missing fields warning if invalid but some fields entered
              if (!_isValid &&
                  ((_selectedCategory == 'CARD' &&
                          (_cardNumberController.text.isNotEmpty ||
                              _expiryController.text.isNotEmpty ||
                              _cvvController.text.isNotEmpty ||
                              _holderNameController.text.isNotEmpty)) ||
                      (_selectedCategory == 'UPI' &&
                          _upiIdController.text.isNotEmpty)))
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    'Please correct invalid fields.',
                    style: GoogleFonts.outfit(color: Colors.red, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.outfit(color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isValid ? _save : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Save',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Add simple padding for keyboard but rely on SingleChildScrollView default handling with Dialog
              if (isKeyboardOpen)
                SizedBox(height: mediaQuery.viewInsets.bottom),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleOption(String label, String value) {
    final isSelected = _selectedCategory == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedCategory = value;
            _validate();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: isSelected ? Colors.white : Colors.grey.shade600,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardForm() {
    return Column(
      children: [
        _buildLightTextField(
          controller: _cardNumberController,
          label: 'Card Number',
          hint: 'xxxx xxxx xxxx xxxx',
          icon: Icons.credit_card,
          errorText: _numberErrorText,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(16), // Max 16 digits
            _CardNumberFormatter(),
          ],
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildLightTextField(
                controller: _expiryController,
                label: 'Expiry',
                hint: 'MM/YY',
                icon: Icons.calendar_today,
                errorText: _expiryErrorText,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4), // MMYY = 4 digits
                  _ExpiryDateFormatter(),
                ],
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildLightTextField(
                controller: _cvvController,
                label: 'CVV',
                hint: '123',
                icon: Icons.lock_outline,
                errorText: _cvvErrorText,
                isObscure: true,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildLightTextField(
          controller: _holderNameController,
          label: 'Cardholder Name',
          hint: 'Name on Card',
          icon: Icons.person_outline,
          errorText: _nameErrorText,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]')),
          ],
          keyboardType: TextInputType.name,
        ),
      ],
    );
  }

  Widget _buildUpiForm() {
    return Column(
      children: [
        const SizedBox(height: 16),
        _buildLightTextField(
          controller: _upiIdController,
          label: 'UPI ID',
          hint: 'user@bank',
          icon: Icons.alternate_email,
          errorText: _upiIdErrorText,
          keyboardType:
              TextInputType.emailAddress, // UPI IDs often look like emails
        ),
      ],
    );
  }

  void _save() {
    final method = PaymentMethod(
      id: '', // Handled by service
      category: _selectedCategory,
      type: _selectedCategory == 'CARD' ? 'Card' : 'UPI', // Type simplified
      maskedNumber: _selectedCategory == 'CARD'
          ? (_cardNumberController.text.length > 4
                ? _cardNumberController.text.substring(
                    _cardNumberController.text.length - 4,
                  )
                : _cardNumberController.text)
          : '',
      expiryDate: _selectedCategory == 'CARD' ? _expiryController.text : '',
      cardHolderName: _selectedCategory == 'CARD'
          ? _holderNameController.text
          : null,
      upiId: _selectedCategory == 'UPI' ? _upiIdController.text : null,
    );
    widget.onSave(method);
    Navigator.pop(context);
  }

  Widget _buildLightTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isObscure = false,
    String? errorText,
    List<TextInputFormatter>? inputFormatters,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(color: Colors.black87, fontSize: 12),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: (_) => _validate(),
          obscureText: isObscure,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: GoogleFonts.outfit(color: Colors.black),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(color: Colors.grey.shade500),
            errorText: errorText, // Show error if invalid
            errorStyle: GoogleFonts.outfit(color: Colors.red, fontSize: 11),
            prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 20),
            filled: true,
            fillColor: Colors.grey.shade100, // Light Fill
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black, width: 1),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade200, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
          ),
        ),
      ],
    );
  }
}

// Custom Formatter for Card Number spacing
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    final String text = newValue.text.replaceAll(' ', '');
    final StringBuffer buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      // Add space after every 4 digits, but not at the end
      if ((i + 1) % 4 == 0 && i != text.length - 1) {
        buffer.write(' ');
      }
    }

    final String string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

// Custom Formatter for MM/YY
class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    final String text = newValue.text.replaceAll('/', '');
    final StringBuffer buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      // Add slash after 2 digits
      if (i == 1 && i != text.length - 1) {
        buffer.write('/');
      }
    }

    final String string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}
