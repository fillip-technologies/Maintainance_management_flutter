/// State model for profile screen actions and mutations.
class ProfileState {
  final bool isLoggingOut;
  final String? errorMessage;

  const ProfileState({
    this.isLoggingOut = false,
    this.errorMessage,
  });

  ProfileState copyWith({
    bool? isLoggingOut,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProfileState(
      isLoggingOut: isLoggingOut ?? this.isLoggingOut,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
