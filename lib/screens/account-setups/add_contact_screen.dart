import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/contact.dart';
import '../../providers/contact_provider.dart';
import '../../theme.dart';

class AddContactScreen extends StatefulWidget {
  const AddContactScreen({super.key});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _telegramController = TextEditingController();
  int _tier = 1;

  void _saveContact() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter name and phone number')),
      );
      return;
    }

    final newContact = Contact(
      id: '', 
      name: _nameController.text,
      phoneNumber: _phoneController.text,
      telegramChatId: _telegramController.text.isEmpty ? null : _telegramController.text,
      tier: _tier,
    );

    await Provider.of<ContactProvider>(context, listen: false).addContact(newContact);
    if (mounted) Navigator.pop(context);
  }

  Widget _buildField(String label, TextEditingController controller, {TextInputType type = TextInputType.text, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 8),
          child: Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70, letterSpacing: 0.5)),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF081023), // Deep dark background
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white10),
          ),
          child: TextField(
            controller: controller,
            keyboardType: type,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
            cursorColor: Colors.white,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(color: Colors.white24, fontSize: 14),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              border: InputBorder.none,
              filled: false, // Force no background fill
              fillColor: Colors.transparent, // Ensure transparency
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.5),
            radius: 1.3,
            colors: [Color(0xFF0F3169), Color(0xFF02091A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    ),
                    Text('New Contact', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildField('FULL NAME', _nameController, hint: 'e.g. Ijeoma Okafor'),
                      const SizedBox(height: 24),
                      _buildField('PHONE NUMBER', _phoneController, type: TextInputType.phone, hint: '+234...'),
                      const SizedBox(height: 24),
                      _buildField(
                        'TELEGRAM CHAT ID', 
                        _telegramController, 
                        hint: 'Numbers only (from @userinfobot)',
                      ),
                      const SizedBox(height: 32),
                      Text('PRIORITY LEVEL', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white70)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _tierButton(1, 'Tier 1 (Instant)'),
                          const SizedBox(width: 12),
                          _tierButton(2, 'Tier 2'),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              // Save Button
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _saveContact,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EchoColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 8,
                      shadowColor: EchoColors.primary.withOpacity(0.5),
                    ),
                    child: Text('Save Contact', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tierButton(int value, String label) {
    final isSelected = _tier == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tier = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? EchoColors.primary : const Color(0xFF2E3D5E),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: isSelected ? EchoColors.primaryLight : Colors.white12),
          ),
          child: Center(
            child: Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, color: isSelected ? Colors.white : Colors.white60)),
          ),
        ),
      ),
    );
  }
}
