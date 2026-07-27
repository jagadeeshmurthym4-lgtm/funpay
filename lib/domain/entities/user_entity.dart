class UserEntity {
  final String uid;
  final String firstName;
  final String lastName;
  final String fullName;
  final String email;
  final String? phone;
  final String referralCode;
  final String? referralCodeUsed;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final double walletBalance;
  final double totalEarnings;
  final double totalWithdrawn;
  final bool isEmailVerified;
  final bool isActive;
  final bool profileCompleted;
  final String? dateOfBirth;
  final String? gender;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? username;
  final String? profilePicture;
  final String? coverImage;
  final String? aboutMe;
  final String? education;
  final String? experience;
  final List<String> portfolioLinks;
  final String? resumeUrl;
  final String? certificateUrl;
  final bool isVerified;
  final int profileCompletionPercentage;

  const UserEntity({
    required this.uid,
    this.firstName = '',
    this.lastName = '',
    this.fullName = '',
    required this.email,
    this.phone,
    required this.referralCode,
    this.referralCodeUsed,
    required this.createdAt,
    this.lastLoginAt,
    this.walletBalance = 0.0,
    this.totalEarnings = 0.0,
    this.totalWithdrawn = 0.0,
    this.isEmailVerified = false,
    this.isActive = true,
    this.profileCompleted = false,
    this.dateOfBirth,
    this.gender,
    this.address,
    this.city,
    this.state,
    this.country,
    this.username,
    this.profilePicture,
    this.coverImage,
    this.aboutMe,
    this.education,
    this.experience,
    this.portfolioLinks = const [],
    this.resumeUrl,
    this.certificateUrl,
    this.isVerified = false,
    this.profileCompletionPercentage = 0,
  });

  UserEntity copyWith({
    String? uid,
    String? firstName,
    String? lastName,
    String? fullName,
    String? email,
    String? phone,
    String? referralCode,
    String? referralCodeUsed,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    double? walletBalance,
    double? totalEarnings,
    double? totalWithdrawn,
    bool? isEmailVerified,
    bool? isActive,
    bool? profileCompleted,
    String? dateOfBirth,
    String? gender,
    String? address,
    String? city,
    String? state,
    String? country,
    String? username,
    String? profilePicture,
    String? coverImage,
    String? aboutMe,
    String? education,
    String? experience,
    List<String>? portfolioLinks,
    String? resumeUrl,
    String? certificateUrl,
    bool? isVerified,
    int? profileCompletionPercentage,
  }) {
    return UserEntity(
      uid: uid ?? this.uid,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      referralCode: referralCode ?? this.referralCode,
      referralCodeUsed: referralCodeUsed ?? this.referralCodeUsed,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      walletBalance: walletBalance ?? this.walletBalance,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      totalWithdrawn: totalWithdrawn ?? this.totalWithdrawn,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isActive: isActive ?? this.isActive,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      username: username ?? this.username,
      profilePicture: profilePicture ?? this.profilePicture,
      coverImage: coverImage ?? this.coverImage,
      aboutMe: aboutMe ?? this.aboutMe,
      education: education ?? this.education,
      experience: experience ?? this.experience,
      portfolioLinks: portfolioLinks ?? this.portfolioLinks,
      resumeUrl: resumeUrl ?? this.resumeUrl,
      certificateUrl: certificateUrl ?? this.certificateUrl,
      isVerified: isVerified ?? this.isVerified,
      profileCompletionPercentage: profileCompletionPercentage ?? this.profileCompletionPercentage,
    );
  }
}
