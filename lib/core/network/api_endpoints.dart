class ApiEndpoints {
  // Base URL
  static const String baseUrl = 'https://nammalagent.pythonanywhere.com';

  // Request Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // --- Auth Endpoints ---
  static const String register = '/api/agent/register/';
  static const String sendOtp = '/api/agent/send-otp/';
  static const String verifyOtp = '/api/agent/verify-otp/';
  static const String login = '/api/agent/login/';
  static const String logout = '/api/logout/';

  // --- Agent Profile & Dashboard ---
  static const String dashboard = '/api/agent/dashboard/';
  static const String profile = '/api/agent/dashboard/';
  static const String editProfile = '/api/agent/profile/edit/';
  static const String toggleStatus = '/api/agent/toggle-status/';
  static const String avatar = '/api/user/avatar/';
  static const String deleteAccount = '/api/delete-account/';

  // --- Home Endpoints ---
  static const String home = '/api/user/home/';

  // --- Agents Discovery ---
  static const String onlineAgents = '/agents/online';
  static const String agentDetails = '/agents'; // + '/{agentId}'

  // --- Agora Calling & Signaling ---
  static const String initiateCall = '/api/calls/initiate/';

  // static const String callStatus = '/api/calls/';
  static String callStatus(dynamic id) => '/api/calls/$id/';
  static String callEnd(dynamic id) => '/api/calls/$id/status/';
  // static const String callHeartbeat =
  //     '/calls/heartbeat'; // For per-minute coin sync
  static const String callHistory = '/api/user/calls/history/';

  // --- Wallet & Coins ---
  static const String wallet = '/api/user/wallet/';
  static const String walletBalance = '/api/user/wallet/';
  static const String addCoins = '/api/user/coins/add/';
  static const String createPayment = '/api/user/payments/create-order/';
  static const String verifyPurchase = '/api/user/payments/verify/';
  static const String transactions = '/api/user/transactions/';
}
