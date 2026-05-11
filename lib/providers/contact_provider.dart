import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/contact.dart';

class ContactProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Contact> _contacts = [];
  bool _isLoading = false;

  List<Contact> get contacts => _contacts;
  bool get isLoading => _isLoading;

  String? get _userId => _auth.currentUser?.uid ?? 'test_user_id';

  Future<void> fetchContacts() async {
    if (_userId == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _db
          .collection('users')
          .doc(_userId)
          .collection('contacts')
          .orderBy('tier')
          .get();

      _contacts = snapshot.docs
          .map((doc) => Contact.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error fetching contacts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addContact(Contact contact) async {
    if (_userId == null) return;
    try {
      await _db
          .collection('users')
          .doc(_userId)
          .collection('contacts')
          .add(contact.toJson());
      await fetchContacts();
    } catch (e) {
      debugPrint('Error adding contact: $e');
    }
  }

  Future<void> deleteContact(String contactId) async {
    if (_userId == null) return;
    try {
      await _db
          .collection('users')
          .doc(_userId)
          .collection('contacts')
          .doc(contactId)
          .delete();
      await fetchContacts();
    } catch (e) {
      debugPrint('Error deleting contact: $e');
    }
  }
}
