class AuthState {
  final bool isAuthenticated;
  final User? user;
  final bool isLoading;
  final String? error;

  AuthState({
    required this.isAuthenticated,
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    User? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class User {
  final int id;
  final int clientId;
  final String clientName;
  final String name;
  final String lastname;
  final String email;
  final String phoneNumber;
  final String tokenFcm;

  User({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.name,
    required this.lastname,
    required this.email,
    required this.phoneNumber,
    required this.tokenFcm,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: (map['id'] ?? 0) is int ? map['id'] : int.tryParse('${map['id']}') ?? 0,
      clientId: (map['client_id'] ?? 0) is int
          ? map['client_id']
          : int.tryParse('${map['client_id']}') ?? 0,
      clientName: map['client_name']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      lastname: map['lastname']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      phoneNumber: map['phone_number']?.toString() ?? '',
      tokenFcm: map['token_fcm']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'client_id': clientId,
      'client_name': clientName,
      'name': name,
      'lastname': lastname,
      'email': email,
      'phone_number': phoneNumber,
      'token_fcm': tokenFcm,
    };
  }
}
