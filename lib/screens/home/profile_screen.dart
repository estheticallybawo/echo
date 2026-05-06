import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  
  bool _isVerified = true;
  String? _profileImagePath; // Mock path
  String _userName = 'Ada Chukwu';
  String _userPhone = '+234 812 345 6789';

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _slide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _pickImage() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D1F45),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Change Profile Photo', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 24),
            _actionItem(Icons.photo_library_outlined, 'Choose from Gallery', () {
              setState(() => _profileImagePath = 'assets/mock_profile.png');
              Navigator.pop(context);
              _showEchoSnackBar('Photo updated from gallery');
            }),
            _actionItem(Icons.camera_alt_outlined, 'Take a Photo', () {
              setState(() => _profileImagePath = 'assets/mock_profile.png');
              Navigator.pop(context);
              _showEchoSnackBar('Photo captured from camera');
            }),
            _actionItem(Icons.delete_outline_rounded, 'Remove Current Photo', () {
              setState(() => _profileImagePath = null);
              Navigator.pop(context);
              _showEchoSnackBar('Profile photo removed');
            }, color: Colors.orangeAccent),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    final nameCtrl = TextEditingController(text: _userName);
    final phoneCtrl = TextEditingController(text: _userPhone);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0F3169),
                const Color(0xFF02091A),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Profile',
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              const SizedBox(height: 24),
              _buildDialogField('Name', nameCtrl),
              const SizedBox(height: 16),
              _buildDialogField('Phone number', phoneCtrl),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 16)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _userName = nameCtrl.text;
                        _userPhone = phoneCtrl.text;
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EchoColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      elevation: 0,
                    ),
                    child: Text('Save', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogField(String hint, TextEditingController ctrl) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF02091A).withOpacity(0.6), // Deep dark navy
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: TextField(
        controller: ctrl,
        style: GoogleFonts.poppins(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: Colors.white24, fontSize: 14),
          border: InputBorder.none,
          filled: false,
          fillColor: Colors.transparent,
        ),
      ),
    );
  }

  void _showEchoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF0F3169),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Text(
            message,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
          ),
        ),
      ),
    );
  }

  Widget _actionItem(IconData icon, String title, VoidCallback onTap, {Color color = Colors.white}) {
    return ListTile(
      leading: Icon(icon, color: color.withOpacity(0.8)),
      title: Text(title, style: GoogleFonts.poppins(color: color, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF02091A),
      body: Container(
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
              // Header with Consistent Back Arrow
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    if (Navigator.canPop(context))
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    const Spacer(),
                    Text(
                      'Profile',
                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48), // Balance
                  ],
                ),
              ),
              
              Expanded(
                child: FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _slide,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Center(
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Stack(
                                children: [
                                  Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFF2563EB), width: 3),
                                      boxShadow: [
                                        BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.3), blurRadius: 20, spreadRadius: 5),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: 56,
                                      backgroundColor: const Color(0xFF1E3A8A),
                                      backgroundImage: _profileImagePath != null ? const AssetImage('assets/icon/echo.png') : null, // Mock image
                                      child: _profileImagePath == null 
                                        ? const Icon(Icons.person, size: 64, color: Colors.white24)
                                        : null,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(color: Color(0xFF2563EB), shape: BoxShape.circle),
                                      child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _userName,
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            _userPhone,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white54,
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Edit Profile Button
                          OutlinedButton.icon(
                            onPressed: _showEditProfileDialog,
                            icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF00A3C4)),
                            label: Text('Edit Profile', style: GoogleFonts.poppins(color: const Color(0xFF00A3C4), fontWeight: FontWeight.w600)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF00A3C4), width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                          
                          _buildProfileItem(
                            Icons.verified_user_outlined, 
                            'Verification', 
                            _isVerified ? 'Identity Verified' : 'Action Required', 
                            const Color(0xFF00A3C4),
                            () => _showEchoSnackBar('Identity already verified via KYC'),
                          ),
                          _buildProfileItem(
                            Icons.security_rounded, 
                            'Safety Profile', 
                            'Medical & ID info complete', 
                            const Color(0xFF2563EB),
                            () => _showEchoSnackBar('Medical ID screen coming soon'),
                          ),
                          _buildProfileItem(
                            Icons.group_outlined, 
                            'Inner Circle', 
                            '3 active members', 
                            const Color(0xFF8B5CF6),
                            () => Navigator.pushNamed(context, '/contacts'),
                          ),
                          _buildProfileItem(
                            Icons.history_rounded, 
                            'SOS History', 
                            'Last active 2 days ago', 
                            Colors.white38,
                            () => Navigator.pushNamed(context, '/activity'),
                          ),
                          
                          const SizedBox(height: 40),
                          GestureDetector(
                            onTap: () => Navigator.pushNamedAndRemoveUntil(context, '/onboarding', (route) => false),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color:  EchoColors.primaryDark.withOpacity(0.9), 
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withOpacity(0.1)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  'Logout',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, String sub, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E3A8A).withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                  Text(sub, style: GoogleFonts.poppins(fontSize: 13, color: Colors.white38)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }
}
