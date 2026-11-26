import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

class StorageService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  SharedPreferences? _prefs;

  // Storage Keys
  static const String _keyToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserId = 'user_id';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyPhone = 'phone_number';
  static const String _keyUserName = 'user_name';
  static const String _keyIsNewUser = 'is_new_user';
  static const String _keyRole = 'user_role';
  static const String _keyAgentStatus = 'agent_status';
  static const String _keyIsApproved = 'is_approved';
  static const String _keyCanCall = 'can_call';
  static const String _keyBio = 'user_bio';
  static const String _keyDob = 'user_dob';
  static const String _keyAvatar = 'user_avatar';
  static const String _keyIdType = 'user_id_type';
  static const String _keyIdNumber = 'user_id_number';

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Secure Token Methods
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _keyToken, value: token);
    await _prefs?.setBool(_keyIsLoggedIn, true);
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: _keyToken);
  }

  Future<void> saveRefreshToken(String token) async {
    await _secureStorage.write(key: _keyRefreshToken, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _keyRefreshToken);
  }

  //  User Session Methods
  Future<void> saveUserId(String userId) async {
    await _prefs?.setString(_keyUserId, userId);
  }

  String? getUserId() {
    return _prefs?.getString(_keyUserId);
  }

  Future<void> savePhone(String phone) async {
    await _prefs?.setString(_keyPhone, phone);
  }

  String? getPhone() {
    return _prefs?.getString(_keyPhone);
  }

  Future<void> saveUserName(String name) async {
    await _prefs?.setString(_keyUserName, name);
  }

  String? getUserName() {
    return _prefs?.getString(_keyUserName);
  }

  Future<void> setIsNewUser(bool isNew) async {
    await _prefs?.setBool(_keyIsNewUser, isNew);
  }

  bool isNewUser() {
    return _prefs?.getBool(_keyIsNewUser) ?? false;
  }

  bool isLoggedIn() {
    return _prefs?.getBool(_keyIsLoggedIn) ?? false;
  }

  Future<void> saveRole(String role) async {
    await _prefs?.setString(_keyRole, role);
  }

  String? getRole() {
    return _prefs?.getString(_keyRole);
  }

  Future<void> saveAgentStatus(String status) async {
    await _prefs?.setString(_keyAgentStatus, status);
  }

  String? getAgentStatus() {
    return _prefs?.getString(_keyAgentStatus);
  }

  Future<void> setIsApproved(bool isApproved) async {
    await _prefs?.setBool(_keyIsApproved, isApproved);
  }

  bool isApproved() {
    return _prefs?.getBool(_keyIsApproved) ?? false;
  }

  Future<void> setCanCall(bool canCall) async {
    await _prefs?.setBool(_keyCanCall, canCall);
  }

  bool canCall() {
    return _prefs?.getBool(_keyCanCall) ?? false;
  }

  Future<void> saveBio(String bio) async {
    await _prefs?.setString(_keyBio, bio);
  }

  String? getBio() {
    return _prefs?.getString(_keyBio);
  }

  Future<void> saveDob(String dob) async {
    await _prefs?.setString(_keyDob, dob);
  }

  String? getDob() {
    return _prefs?.getString(_keyDob);
  }

  Future<void> saveAvatar(String avatar) async {
    await _prefs?.setString(_keyAvatar, avatar);
  }

  String? getAvatar() {
    return _prefs?.getString(_keyAvatar);
  }

  Future<void> saveIdType(String idType) async {
    await _prefs?.setString(_keyIdType, idType);
  }

  String? getIdType() {
    return _prefs?.getString(_keyIdType);
  }

  Future<void> saveIdNumber(String idNumber) async {
    await _prefs?.setString(_keyIdNumber, idNumber);
  }

  String? getIdNumber() {
    return _prefs?.getString(_keyIdNumber);
  }

  //Clear Session (Logout)
  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
    await _prefs?.clear();
  }
}
