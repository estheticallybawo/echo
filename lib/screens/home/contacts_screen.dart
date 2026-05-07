import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme.dart';
import '../../providers/user_preferences_provider.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  final List<Map<String, dynamic>> _allContacts = [
    {'name': 'Mom', 'detail': '+234 XXX XXX XXX', 'type': 'Inner Circle', 'icon': Icons.person},
    {'name': 'Sister', 'detail': '+234 XXX XXX XXX', 'type': 'Inner Circle', 'icon': Icons.person},
    {'name': 'Best Friend', 'detail': '+234 XXX XXX XXX', 'type': 'Inner Circle', 'icon': Icons.person},
    {'name': 'Trusted Colleague', 'detail': '+234 XXX XXX XXX', 'type': 'Extended Network', 'icon': Icons.person},
    {'name': 'Neighbor', 'detail': '+234 XXX XXX XXX', 'type': 'Extended Network', 'icon': Icons.person},
    {'name': 'Support Group', 'detail': '+234 XXX XXX XXX', 'type': 'Extended Network', 'icon': Icons.person},
    {'name': 'Campus Security', 'detail': '200m away • Emergency Services', 'type': 'Nearby Contacts', 'icon': Icons.location_on},
  ];

  List<Map<String, dynamic>> _filteredContacts = [];

  @override
  void initState() {
    super.initState();
    _filteredContacts = _allContacts;
    _searchController.addListener(_filterContacts);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<UserPreferencesProvider>().loadEmergencyContacts();
      }
    });
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredContacts = _allContacts.where((contact) {
        return contact['name'].toLowerCase().contains(query);
      }).toList();
    });
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D1F45),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Add Contact', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 24),
            _actionItem(Icons.edit_note_rounded, 'Add Manually', () {
              Navigator.pop(context);
              _showAddContactDialog();
            }),
            _actionItem(Icons.contact_phone_rounded, 'Select from Phone Book', () {
              Navigator.pop(context);
              _showMockContactPicker();
            }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _actionItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF00A3C4)),
      title: Text(title, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }

  void _showMockContactPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF02091A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.5),
            radius: 1.3,
            colors: [Color(0xFF0F3169), Color(0xFF02091A)],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Text('Phone Contacts', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 15,
                itemBuilder: (context, i) {
                  final names = ['Alice Johnson', 'Bob Smith', 'Charlie Brown', 'David Wilson', 'Eve Davis', 'Frank Miller', 'Grace Lee', 'Henry Garcia', 'Ivy Martinez', 'Jack Robinson', 'Kelly White', 'Leo King', 'Mia Young', 'Noah Hall', 'Olivia Allen'];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF1E3A8A),
                        child: Text(names[i][0], style: const TextStyle(color: Colors.white)),
                      ),
                      title: Text(names[i], style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                      subtitle: Text('+234 802 000 ${1000 + i}', style: GoogleFonts.poppins(color: Colors.white38)),
                      trailing: const Icon(Icons.add_circle_outline, color: Color(0xFF00A3C4)),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${names[i]} added to Inner Circle')),
                        );
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddContactDialog({String? initialName}) {
    final nameController = TextEditingController(text: initialName);
    final phoneController = TextEditingController();
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
                initialName != null ? 'Edit Contact' : 'Add Contact',
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              const SizedBox(height: 24),
              _buildDialogField('Name', controller: nameController),
              const SizedBox(height: 16),
              _buildDialogField('Phone number', controller: phoneController),
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
                    onPressed: () async {
                      if (nameController.text.isEmpty || phoneController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill in all fields')),
                        );
                        return;
                      }
                      await context.read<UserPreferencesProvider>().addEmergencyContact(
                        contactName: nameController.text,
                        phone: phoneController.text,
                        relationship: 'Emergency Contact',
                      );
                      if (mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EchoColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      elevation: 0,
                    ),
                    child: Text(initialName != null ? 'Save' : 'Add', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogField(String hint, {TextEditingController? controller}) {
    final ctrl = controller ?? TextEditingController();
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

  void _showMoreOptions(String name) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D1F45),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.notifications_active_outlined, color: Color(0xFF00A3C4)),
              title: Text('Notify Contact', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500)),
              subtitle: Text('Inform them they are your emergency contact', style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Notification sent to $name'),
                    backgroundColor: const Color(0xFF0F3169),
                  ),
                );
              },
            ),
            const Divider(color: Colors.white10, indent: 16, endIndent: 16),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: Colors.white70),
              title: Text('Edit', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                _showAddContactDialog(initialName: name);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.orangeAccent),
              title: Text('Remove', style: GoogleFonts.poppins(color: Colors.orangeAccent, fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                _showRemoveConfirmation(name);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showRemoveConfirmation(String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F3169),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Remove Contact?', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to remove $name from your safety network?', style: GoogleFonts.poppins(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _allContacts.removeWhere((c) => c['name'] == name);
                _filterContacts();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$name removed'), backgroundColor: Colors.orangeAccent.withOpacity(0.8)),
              );
            },
            child: Text('Remove', style: GoogleFonts.poppins(color: Colors.orangeAccent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        'Contacts',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 22),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF02091A).withOpacity(0.4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.5),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: GoogleFonts.poppins(color: Colors.white),
                          decoration: InputDecoration(
                            icon: const Icon(Icons.search_rounded, color: Colors.white38, size: 24),
                            hintText: 'Search contacts...',
                            hintStyle: GoogleFonts.poppins(color: Colors.white38),
                            border: InputBorder.none,
                            filled: false,
                            fillColor: Colors.transparent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      _buildGroup('Inner Circle', 'First responders', const Color(0xFF00A3C4)),
                      _buildGroup('Extended Network', 'Secondary support', const Color(0xFFF59E0B)),
                      _buildGroup('Nearby Contacts', 'People near you', const Color(0xFF10B981)),
                      
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddOptions,
        backgroundColor: const Color(0xFF00A3C4),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
    );
  }

  Widget _buildGroup(String type, String sub, Color color) {
    final contacts = _filteredContacts.where((c) => c['type'] == type).toList();
    if (contacts.isEmpty && _searchController.text.isNotEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 4, height: 20, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 12),
            Text(type, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 4, bottom: 16),
          child: Text(sub, style: GoogleFonts.poppins(fontSize: 13, color: Colors.white38)),
        ),
        ...contacts.map((c) => _buildProContactCard(c['name'], c['detail'], c['icon'])),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildProContactCard(String name, String detail, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E3A8A).withOpacity(0.5),
            const Color(0xFF1E3A8A).withOpacity(0.2),
          ],
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), offset: const Offset(0, 4), blurRadius: 12),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white60, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                        const SizedBox(height: 2),
                        Text(detail, style: GoogleFonts.poppins(fontSize: 13, color: Colors.white38)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showMoreOptions(name),
                    icon: const Icon(Icons.more_vert_rounded, color: Colors.white24),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
