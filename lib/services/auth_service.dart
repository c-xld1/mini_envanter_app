import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class AuthService extends ChangeNotifier {
  AppUser? _user;
  AppUser? get user => _user;

  Future<void> loadUser() async {
    final supabaseUser = Supabase.instance.client.auth.currentUser;
    if (supabaseUser != null) {
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', supabaseUser.id)
          .single();
      _user = AppUser.fromJson(response);
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
    _user = null;
    notifyListeners();
  }
}