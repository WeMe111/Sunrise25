class AdminConfig {
  // 관리자 이메일 목록
  // 여기에 관리자 이메일을 추가하세요
  static const List<String> adminEmails = [
    'aplm12@naver.com',
    // 추가 관리자 이메일을 여기에 추가하세요
  ];

  // 이메일이 관리자인지 확인
  static bool isAdmin(String? email) {
    if (email == null) return false;
    return adminEmails.contains(email.toLowerCase());
  }
}
