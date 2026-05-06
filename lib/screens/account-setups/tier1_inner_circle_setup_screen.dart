import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme.dart';

class Tier1InnerCircleSetupScreen extends StatefulWidget {
  const Tier1InnerCircleSetupScreen({super.key});

  @override
  State<Tier1InnerCircleSetupScreen> createState() => _Tier1InnerCircleSetupScreenState();
}

class _Tier1InnerCircleSetupScreenState extends State<Tier1InnerCircleSetupScreen> {
  final List<String> _contacts = [];
  int _nextContactIndex = 1;
  int _selectedPreviewIndex = 0;

  void _addContact() {
    if (_contacts.length >= 10) return;
    setState(() {
      final names = ['Ade', 'Daddy', 'Funke', 'Tobi', 'Sarah', 'Kola', 'Ngozi', 'Bisi', 'Zainab', 'David'];
      if (_nextContactIndex <= names.length) {
        _contacts.add(names[_nextContactIndex - 1]);
      } else {
        _contacts.add('Contact-${_nextContactIndex}');
      }
      _nextContactIndex++;
    });
  }

  Widget _buildContactItem(String name, int index) {
    final isSelected = _selectedPreviewIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPreviewIndex = index;
        });
      },
      child: Column(
        children: [
          Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? EchoColors.primary : Colors.white24,
                    width: isSelected ? 2 : 1,
                  ),
                  color: isSelected ? EchoColors.primary.withOpacity(0.1) : const Color(0xFF0D1F45),
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: EchoColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF081023), width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? Colors.white : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton({bool large = false}) {
    return GestureDetector(
      onTap: _addContact,
      child: Column(
        children: [
          Container(
            width: large ? 72 : 70,
            height: large ? 72 : 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white24,
                width: 1.5,
                style: BorderStyle.solid,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.add,
                size: large ? 32 : 28,
                color: Colors.white70,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.6),
            radius: 1.4,
            colors: [Color(0xFF0D2763), Color(0xFF081023)],
            stops: [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.maybePop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B1C41),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(7, (index) {
                        final bool active = index == 5;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: active ? 74 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: active ? EchoColors.primary : Colors.white24,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  'Your inner circle who\'ll be notified immediately',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select up to 10 contacts. Drag to rank priority — the first 3 are Tier 1.',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    height: 1.7,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_contacts.isEmpty)
                          Center(
                            child: Column(
                              children: [
                                const SizedBox(height: 40),
                                _buildAddButton(large: true),
                                const SizedBox(height: 12),
                                Text(
                                  'Add your first contact',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ...List.generate(_contacts.length, (index) {
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 16),
                                        child: _buildContactItem(_contacts[index], index),
                                      );
                                    }),
                                    if (_contacts.length < 10) _buildAddButton(),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              Center(
                                child: Text(
                                  'Click to customize alert message',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.white54,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 32),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B1C41).withOpacity(0.5),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: EchoColors.primary.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Selected',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.white54,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Tier 1 (immediate)',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.white54,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${_contacts.length} contacts',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _contacts.isEmpty ? 'None' : '${_contacts.length >= 3 ? 3 : _contacts.length} added',
                                          style: GoogleFonts.poppins(
                                            fontSize: 15,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF081023),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 3,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            color: EchoColors.primary,
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'ALERT PREVIEW',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _contacts.isEmpty
                                          ? 'Add contacts to see the alert preview update automatically.'
                                          : '"${_contacts[_selectedPreviewIndex % _contacts.length]}, your contact may be in danger near D-Line Junction. Raised voices detected. Tap to act now."',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        height: 1.6,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/tier2-public-alert-setup');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EchoColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(34),
                      ),
                    ),
                    child: Text(
                      'Set my inner circle',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
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
