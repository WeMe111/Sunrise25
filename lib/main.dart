import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'config/admin_config.dart';
import 'models/notice_model.dart';
import 'models/gallery_model.dart';
import 'models/press_release_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(const MyApp());
}

// Supabase 인스턴스를 쉽게 접근하기 위한 헬퍼
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '인천장애인능력개발협회',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6366F1)),
        useMaterial3: true,
        fontFamily: 'Pretendard',
      ),
      home: const LandingPage(),
    );
  }
}

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  late YoutubePlayerController _youtubeController;
  int _currentPage = 0; // 0: 홈, 1: 협회소개, 2: 공지사항, 3: 활동갤러리, 4: 보도자료, 5: 후원하기, 6: 공지사항 상세, 7: 갤러리 상세
  bool _isLoggedIn = false;
  String _loggedInUser = '';
  bool _isMobileMenuOpen = false;
  List<Notice> _notices = [];
  Notice? _selectedNotice;
  List<Gallery> _galleryItems = [];
  Gallery? _selectedGallery;
  List<PressRelease> _pressReleases = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _youtubeController = YoutubePlayerController.fromVideoId(
      videoId: 'Ff21gFHq1GI',
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        mute: true,
        enableCaption: false,
        playsInline: true,
      ),
    );

    // Supabase에서 데이터 로드 및 세션 확인
    _loadDataFromSupabase();
    _checkSession();
  }

  // 세션 확인 및 자동 로그인
  Future<void> _checkSession() async {
    final session = supabase.auth.currentSession;
    if (session != null) {
      final user = session.user;
      setState(() {
        _isLoggedIn = true;
        _loggedInUser = user.email ?? '';
      });
    }
  }

  // Supabase에서 모든 데이터 로드
  Future<void> _loadDataFromSupabase() async {
    await Future.wait([
      _loadNotices(),
      _loadGallery(),
      _loadPressReleases(),
    ]);

    setState(() {
      _isLoading = false;
    });
  }

  // 공지사항 로드
  Future<void> _loadNotices() async {
    try {
      final response = await supabase
          .from('notices')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        _notices = (response as List).map((notice) => Notice.fromJson(notice)).toList();
      });
    } catch (e) {
      print('공지사항 로드 오류: $e');
    }
  }

  // 활동갤러리 로드
  Future<void> _loadGallery() async {
    try {
      final response = await supabase
          .from('gallery')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        _galleryItems = (response as List).map((gallery) => Gallery.fromJson(gallery)).toList();
      });
    } catch (e) {
      print('갤러리 로드 오류: $e');
    }
  }

  // 보도자료 로드
  Future<void> _loadPressReleases() async {
    try {
      final response = await supabase
          .from('press_releases')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        _pressReleases = (response as List).map((pr) => PressRelease.fromJson(pr)).toList();
      });
    } catch (e) {
      print('보도자료 로드 오류: $e');
    }
  }

  // 관리자 권한 확인
  bool get _isAdmin {
    return AdminConfig.isAdmin(_loggedInUser);
  }

  @override
  void dispose() {
    _youtubeController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            _buildNavigation(),
            if (_currentPage == 0) ...[
              _buildHeroSection(),
              _buildQuickMenu(),
              _buildCalendarSection(),
              _buildNewsSection(),
              _buildGallerySection(),
            ] else if (_currentPage == 1) ...[
              _buildAboutPage(),
            ] else if (_currentPage == 2) ...[
              _buildNoticePage(),
            ] else if (_currentPage == 3) ...[
              _buildActivityGalleryPage(),
            ] else if (_currentPage == 4) ...[
              _buildPressReleasePage(),
            ] else if (_currentPage == 5) ...[
              _buildDonationPage(),
            ] else if (_currentPage == 6) ...[
              _buildNoticeDetailPage(),
            ] else if (_currentPage == 7) ...[
              _buildGalleryDetailPage(),
            ],
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 900;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 20 : (isTablet ? 40 : 60),
            vertical: isMobile ? 16 : 20,
          ),
          child: Row(
            children: [
              // 로고
              InkWell(
                onTap: () {
                  setState(() {
                    _currentPage = 0;
                  });
                },
                child: Image.asset(
                  'assets/images/logo.png',
                  height: isMobile ? 40 : 50,
                  fit: BoxFit.contain,
                ),
              ),
              const Spacer(),
              // 검색창 (태블릿/데스크탑만)
              if (!isMobile) ...[
                Flexible(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: isTablet ? 200 : 280,
                    ),
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(23),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(width: 20),
                        Icon(Icons.search, color: Color(0xFF9CA3AF), size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: '무엇을 찾고 계신가요?',
                              border: InputBorder.none,
                              hintStyle: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 20),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: isMobile ? 16 : (isTablet ? 12 : 20)),
              ],
              // 로그인/로그아웃 버튼
              InkWell(
                onTap: () async {
                  if (_isLoggedIn) {
                    // Supabase에서 로그아웃
                    await supabase.auth.signOut();
                    setState(() {
                      _isLoggedIn = false;
                      _loggedInUser = '';
                    });
                  } else {
                    _showLoginDialog();
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 24,
                    vertical: isMobile ? 10 : 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isLoggedIn
                          ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                          : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: (_isLoggedIn ? const Color(0xFFEF4444) : const Color(0xFF6366F1))
                            .withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isLoggedIn ? Icons.logout : Icons.login,
                        color: Colors.white,
                        size: isMobile ? 14 : 16,
                      ),
                      if (!isMobile) ...[
                        const SizedBox(width: 8),
                        Text(
                          _isLoggedIn ? '로그아웃' : '로그인',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavigation() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 900;

        if (isMobile) {
          // Mobile: Hamburger menu
          return Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(
                        _isMobileMenuOpen ? Icons.close : Icons.menu,
                        color: const Color(0xFF6366F1),
                      ),
                      onPressed: () {
                        setState(() {
                          _isMobileMenuOpen = !_isMobileMenuOpen;
                        });
                      },
                    ),
                  ],
                ),
              ),
              if (_isMobileMenuOpen)
                Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      _buildNavItem('협회소개'),
                      _buildNavItem('공지사항'),
                      _buildNavItem('활동갤러리'),
                      _buildNavItem('보도자료'),
                      _buildNavItem('후원하기'),
                    ],
                  ),
                ),
            ],
          );
        } else {
          // Tablet/Desktop: Horizontal menu
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 40 : 60,
              vertical: 0,
            ),
            child: Row(
              children: [
                _buildNavItem('협회소개'),
                _buildNavItem('공지사항'),
                _buildNavItem('활동갤러리'),
                _buildNavItem('보도자료'),
                _buildNavItem('후원하기'),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildNavItem(String label) {
    int pageIndex = 0;
    if (label == '협회소개') pageIndex = 1;
    if (label == '공지사항') pageIndex = 2;
    if (label == '활동갤러리') pageIndex = 3;
    if (label == '보도자료') pageIndex = 4;
    if (label == '후원하기') pageIndex = 5;

    bool isActive = _currentPage == pageIndex;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextButton(
        onPressed: () {
          setState(() {
            _currentPage = pageIndex;
            _isMobileMenuOpen = false; // Close mobile menu on selection
          });
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
          ),
          backgroundColor: isActive ? const Color(0xFF6366F1).withOpacity(0.1) : Colors.transparent,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? const Color(0xFF6366F1) : const Color(0xFF374151),
            fontSize: 15,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 900;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: isMobile ? 40 : (isTablet ? 60 : 80),
            horizontal: isMobile ? 20 : (isTablet ? 40 : 60),
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF6366F1).withOpacity(0.05),
                const Color(0xFF8B5CF6).withOpacity(0.05),
              ],
            ),
          ),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF6366F1).withOpacity(0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 16,
                            color: Color(0xFF6366F1),
                          ),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Incheon Ability Development Association',
                              style: TextStyle(
                                color: Color(0xFF6366F1),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '장애인능력개발협회',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '(사)인천장애인능력개발협회는 2010년에 설립, 장애인 엑스포 직업체험 참여를 시작으로 '
                      '미국 하와이 장애인 엑스포에도 참가할 정도로 장애인들의 교육을 통한 성장을 위해 힘을 다하고 있다.\n\n'
                      '장애인의 직업재활을 통한 사회참여를 독려 및 지속적인 장애인 직업재활 훈련을 진행하고 있다.\n\n'
                      '특별히 장애인 인재개발센터 설립 장애 영역별 맞춤 일자리 개발 진행하며 '
                      '능력 있는 장애인 전문가 양성을 통한 장애인의 사회참여 확대의 방향을 제시하고 있다.',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                        height: 1.7,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.phone, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            '010-9114-5923',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      width: double.infinity,
                      height: 250,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 40,
                            offset: const Offset(0, 20),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: YoutubePlayer(
                          controller: _youtubeController,
                          aspectRatio: 16 / 9,
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF6366F1).withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.auto_awesome,
                                  size: 16,
                                  color: Color(0xFF6366F1),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Incheon Ability Development Association',
                                  style: TextStyle(
                                    color: const Color(0xFF6366F1),
                                    fontSize: isTablet ? 12 : 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            '장애인능력개발협회',
                            style: TextStyle(
                              fontSize: isTablet ? 36 : 48,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1F2937),
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            '(사)인천장애인능력개발협회는 2010년에 설립, 장애인 엑스포 직업체험 참여를 시작으로 '
                            '미국 하와이 장애인 엑스포에도 참가할 정도로 장애인들의 교육을 통한 성장을 위해 힘을 다하고 있다.\n\n'
                            '장애인의 직업재활을 통한 사회참여를 독려 및 지속적인 장애인 직업재활 훈련을 진행하고 있다.\n\n'
                            '특별히 장애인 인재개발센터 설립 장애 영역별 맞춤 일자리 개발 진행하며 '
                            '능력 있는 장애인 전문가 양성을 통한 장애인의 사회참여 확대의 방향을 제시하고 있다.',
                            style: TextStyle(
                              fontSize: isTablet ? 14 : 16,
                              color: const Color(0xFF6B7280),
                              height: 1.8,
                            ),
                          ),
                          const SizedBox(height: 40),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 28,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF6366F1).withOpacity(0.4),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.phone, color: Colors.white, size: 20),
                                    SizedBox(width: 10),
                                    Text(
                                      '010-9114-5923',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: isTablet ? 40 : 60),
                    Expanded(
                      child: Container(
                        height: isTablet ? 300 : 400,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 40,
                              offset: const Offset(0, 20),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: YoutubePlayer(
                            controller: _youtubeController,
                            aspectRatio: 16 / 9,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildQuickMenu() {
    final menuItems = [
      {'icon': Icons.business_rounded, 'label': '협회소개', 'color': Color(0xFF6366F1), 'url': null, 'page': 1},
      {'icon': Icons.campaign_rounded, 'label': '공지사항', 'color': Color(0xFF8B5CF6), 'url': null, 'page': 2},
      {'icon': Icons.collections_rounded, 'label': '활동갤러리', 'color': Color(0xFFEC4899), 'url': null, 'page': 3},
      {'icon': Icons.description_rounded, 'label': '보도자료', 'color': Color(0xFF14B8A6), 'url': null, 'page': 4},
      {'icon': Icons.favorite_rounded, 'label': '후원하기', 'color': Color(0xFFF59E0B), 'url': null, 'page': 5},
      {'icon': null, 'label': '국세청', 'color': Color(0xFF059669), 'url': 'https://www.nts.go.kr/', 'image': 'assets/images/nationallogo.jpg'},
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 900;

        // Determine grid columns based on screen size
        int crossAxisCount;
        if (isMobile) {
          crossAxisCount = 2;
        } else if (isTablet) {
          crossAxisCount = 3;
        } else {
          crossAxisCount = 3;
        }

        return Container(
          padding: EdgeInsets.symmetric(
            vertical: isMobile ? 40 : (isTablet ? 60 : 80),
            horizontal: isMobile ? 20 : (isTablet ? 40 : 60),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: isMobile ? 24 : 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    child: Text(
                      '빠른 서비스',
                      style: TextStyle(
                        fontSize: isMobile ? 24 : (isTablet ? 28 : 32),
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  if (!isMobile) ...[
                    const SizedBox(width: 16),
                    Flexible(
                      child: Text(
                        '자주 찾는 메뉴를 한눈에',
                        style: TextStyle(
                          fontSize: isTablet ? 14 : 16,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: isMobile ? 24 : (isTablet ? 36 : 48)),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: isMobile ? 1.1 : 1.3,
                  crossAxisSpacing: isMobile ? 12 : (isTablet ? 16 : 24),
                  mainAxisSpacing: isMobile ? 12 : (isTablet ? 16 : 24),
                ),
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  return _buildQuickMenuItem(
                    menuItems[index]['icon'] as IconData?,
                    menuItems[index]['label'] as String,
                    menuItems[index]['color'] as Color,
                    menuItems[index]['url'] as String?,
                    menuItems[index]['page'] as int?,
                    menuItems[index]['image'] as String?,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickMenuItem(IconData? icon, String label, Color color, String? url, int? page, String? image) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            if (url != null) {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            } else if (page != null) {
              setState(() {
                _currentPage = page;
              });
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (image != null)
                  Image.asset(
                    image,
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.account_balance, size: 120, color: color);
                    },
                  )
                else if (icon != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, size: 40, color: color),
                  ),
                const SizedBox(height: 12),
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 900;

        return Container(
          padding: EdgeInsets.symmetric(
            vertical: isMobile ? 40 : (isTablet ? 60 : 80),
            horizontal: isMobile ? 20 : (isTablet ? 40 : 60),
          ),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  '${DateTime.now().year}년 ${DateTime.now().month}월',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.chevron_left, color: Color(0xFF6366F1)),
                                    onPressed: () {},
                                    style: IconButton.styleFrom(
                                      backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.chevron_right, color: Color(0xFF6366F1)),
                                    onPressed: () {},
                                    style: IconButton.styleFrom(
                                      backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildCalendar(),
                        ],
                      ),
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: EdgeInsets.all(isTablet ? 24 : 32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${DateTime.now().year}년 ${DateTime.now().month}월',
                                  style: TextStyle(
                                    fontSize: isTablet ? 20 : 24,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1F2937),
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.chevron_left, color: Color(0xFF6366F1)),
                                      onPressed: () {},
                                      style: IconButton.styleFrom(
                                        backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.chevron_right, color: Color(0xFF6366F1)),
                                      onPressed: () {},
                                      style: IconButton.styleFrom(
                                        backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _buildCalendar(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildCalendar() {
    final weekDays = ['일', '월', '화', '수', '목', '금', '토'];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekDays.map((day) {
            return Expanded(
              child: Center(
                child: Text(
                  day,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: day == '일'
                        ? const Color(0xFFEF4444)
                        : day == '토'
                            ? const Color(0xFF6366F1)
                            : const Color(0xFF9CA3AF),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        ..._buildCalendarDays(),
      ],
    );
  }

  List<Widget> _buildCalendarDays() {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;
    final today = now.day;

    // 해당 월의 첫 날
    final firstDay = DateTime(year, month, 1);
    // 해당 월의 마지막 날
    final lastDay = DateTime(year, month + 1, 0);

    // 첫 날의 요일 (0: 일요일, 6: 토요일)
    final firstWeekday = firstDay.weekday % 7;
    // 마지막 날짜
    final daysInMonth = lastDay.day;

    List<List<int?>> weeks = [];
    List<int?> currentWeek = [];

    // 첫 주의 빈 칸 채우기
    for (int i = 0; i < firstWeekday; i++) {
      currentWeek.add(null);
    }

    // 날짜 채우기
    for (int day = 1; day <= daysInMonth; day++) {
      currentWeek.add(day);
      if (currentWeek.length == 7) {
        weeks.add(currentWeek);
        currentWeek = [];
      }
    }

    // 마지막 주의 빈 칸 채우기
    if (currentWeek.isNotEmpty) {
      while (currentWeek.length < 7) {
        currentWeek.add(null);
      }
      weeks.add(currentWeek);
    }

    return weeks.map((week) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: week.asMap().entries.map((entry) {
            final dayIndex = entry.key;
            final day = entry.value;

            if (day == null) {
              return const Expanded(child: SizedBox());
            }

            final isToday = day == today;
            final isWeekend = dayIndex == 0 || dayIndex == 6;

            return Expanded(
              child: Center(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: isToday
                        ? const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          )
                        : null,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        color: isToday
                            ? Colors.white
                            : isWeekend
                                ? (dayIndex == 0
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF6366F1))
                                : const Color(0xFF374151),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
    }).toList();
  }

  Widget _buildNewsSection() {
    // 최신 3개의 공지사항만 표시
    final displayNotices = _notices.take(3).toList();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 60),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    '최신 소식',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '협회의 새로운 소식을 확인하세요',
                    style: TextStyle(
                      fontSize: 16,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _currentPage = 2;
                  });
                },
                icon: const Text(
                  '전체보기',
                  style: TextStyle(
                    color: Color(0xFF6366F1),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                label: const Icon(
                  Icons.arrow_forward,
                  size: 18,
                  color: Color(0xFF6366F1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          if (displayNotices.isEmpty)
            Container(
              padding: const EdgeInsets.all(60),
              child: const Center(
                child: Text(
                  '등록된 공지사항이 없습니다.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ),
            )
          else
            Column(
              children: displayNotices.map((notice) {
                Color categoryColor = const Color(0xFF6366F1);
                if (notice.category == '교육') {
                  categoryColor = const Color(0xFF8B5CF6);
                } else if (notice.category == '행사') {
                  categoryColor = const Color(0xFFEC4899);
                }

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedNotice = notice;
                      _currentPage = 6;
                      // Note: views는 immutable이므로 증가시키려면 새로운 객체를 만들어야 함
                      // 실제로는 Supabase에서 view count를 증가시키는 함수를 호출해야 함
                    });
                  },
                  child: _buildNewsItem(
                    notice.category,
                    notice.title,
                    notice.createdAt.toString().split(' ')[0],
                    categoryColor,
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildNewsItem(String category, String title, String date, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              category,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          Text(
            date,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: const Color(0xFF9CA3AF),
          ),
        ],
      ),
    );
  }

  Widget _buildGallerySection() {
    // 최신 4개의 갤러리 아이템만 표시
    final displayItems = _galleryItems.reversed.take(4).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 900;

        // Determine grid columns based on screen size
        int crossAxisCount;
        if (isMobile) {
          crossAxisCount = 1;
        } else if (isTablet) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 4;
        }

        return Container(
          padding: EdgeInsets.symmetric(
            vertical: isMobile ? 40 : (isTablet ? 60 : 80),
            horizontal: isMobile ? 20 : (isTablet ? 40 : 60),
          ),
          child: Column(
            children: [
              isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 24,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Text(
                                '활동 갤러리',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                '협회의 다양한 활동을 만나보세요',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _currentPage = 3;
                                });
                              },
                              icon: const Text(
                                '전체보기',
                                style: TextStyle(
                                  color: Color(0xFF6366F1),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              label: const Icon(
                                Icons.arrow_forward,
                                size: 16,
                                color: Color(0xFF6366F1),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: isTablet ? 28 : 32,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              '활동 갤러리',
                              style: TextStyle(
                                fontSize: isTablet ? 28 : 32,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              '협회의 다양한 활동을 만나보세요',
                              style: TextStyle(
                                fontSize: isTablet ? 14 : 16,
                                color: const Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _currentPage = 3;
                            });
                          },
                          icon: const Text(
                            '전체보기',
                            style: TextStyle(
                              color: Color(0xFF6366F1),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          label: const Icon(
                            Icons.arrow_forward,
                            size: 18,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                      ],
                    ),
              SizedBox(height: isMobile ? 24 : (isTablet ? 32 : 40)),
              if (displayItems.isEmpty)
                Container(
                  padding: EdgeInsets.all(isMobile ? 40 : 60),
                  child: Center(
                    child: Text(
                      '등록된 활동 사진이 없습니다.',
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 0.9,
                    crossAxisSpacing: isMobile ? 12 : (isTablet ? 16 : 24),
                    mainAxisSpacing: isMobile ? 12 : (isTablet ? 16 : 24),
                  ),
                  itemCount: displayItems.length,
                  itemBuilder: (context, index) {
                    final item = displayItems[index];
                    return _buildGalleryItemMain(item);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGalleryItemMain(Gallery item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: const Color(0xFFF3F4F6),
                child: const Icon(Icons.image, size: 60, color: Color(0xFF9CA3AF)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.createdAt.toString().split(' ')[0],
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryItem(IconData icon, String title, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color.withOpacity(0.8), color],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Center(
                child: Icon(icon, size: 64, color: Colors.white),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '2025.10.15',
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 교육프로그램 페이지
  Widget _buildEducationPage() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '교육프로그램',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 80,
            height: 4,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 60),
          const Text(
            '다양한 교육 프로그램을 준비 중입니다.',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  // 취업지원 페이지
  Widget _buildEmploymentPage() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '취업지원',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 80,
            height: 4,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 60),
          const Text(
            '취업 지원 서비스를 준비 중입니다.',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  // 커뮤니티 페이지
  Widget _buildCommunityPage() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '커뮤니티',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 80,
            height: 4,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 60),
          const Text(
            '커뮤니티 기능을 준비 중입니다.',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  // 활동갤러리 페이지
  Widget _buildActivityGalleryPage() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '활동갤러리',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: 80,
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
              if (_isAdmin)
                ElevatedButton.icon(
                  onPressed: _showGalleryWriteDialog,
                  icon: const Icon(Icons.add_photo_alternate, size: 20),
                  label: const Text('사진 등록'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 60),
          // 갤러리 그리드
          if (_galleryItems.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(60),
                child: Text(
                  '등록된 활동 사진이 없습니다.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1.0,
              ),
              itemCount: _galleryItems.length,
              itemBuilder: (context, index) {
                final item = _galleryItems[_galleryItems.length - 1 - index];
                return _buildGalleryCard(item);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildGalleryCard(Gallery item) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedGallery = item;
          _currentPage = 7;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFFF3F4F6),
                  child: item.imageUrls.isNotEmpty
                      ? const Icon(Icons.image, size: 60, color: Color(0xFF9CA3AF))
                      : const Icon(Icons.image, size: 60, color: Color(0xFF9CA3AF)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.createdAt.toString().split(' ')[0],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 보도자료 페이지
  Widget _buildPressReleasePage() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '보도자료',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: 80,
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
              if (_isAdmin)
                ElevatedButton.icon(
                  onPressed: _showPressReleaseWriteDialog,
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('보도자료 작성'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 60),
          // 게시판 테이블
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                // 테이블 헤더
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(
                          '번호',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '제목',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: Text(
                          '작성자',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: Text(
                          '날짜',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        child: Text(
                          '조회',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 게시글 목록
                if (_pressReleases.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(60),
                    child: const Center(
                      child: Text(
                        '등록된 보도자료가 없습니다.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
                  )
                else
                  ..._pressReleases.map((press) => _buildPressReleaseRow(press)).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPressReleaseRow(PressRelease press) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              press.id.substring(0, 8),
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Text(
                  press.title,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF1F2937),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (DateTime.now().difference(press.createdAt).inDays < 7) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'N',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(
              press.author,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(
              press.createdAt.toString().split(' ')[0],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              '0',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 후원하기 페이지
  Widget _buildDonationPage() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '후원하기',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 80,
            height: 4,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 60),
          const Text(
            '후원 안내 정보를 준비 중입니다.',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  // 갤러리 상세 페이지
  Widget _buildGalleryDetailPage() {
    if (_selectedGallery == null) return Container();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 뒤로가기 버튼
          InkWell(
            onTap: () {
              setState(() {
                _currentPage = 3;
              });
            },
            child: Row(
              children: [
                const Icon(Icons.arrow_back, size: 20, color: Color(0xFF6366F1)),
                const SizedBox(width: 8),
                const Text(
                  '목록으로',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6366F1),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          // 제목
          Text(
            _selectedGallery!.title,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 20),
          // 작성자 및 날짜
          Row(
            children: [
              const Icon(Icons.person, size: 16, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 6),
              Text(
                _selectedGallery!.author,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(width: 20),
              const Icon(Icons.calendar_today, size: 16, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 6),
              Text(
                _selectedGallery!.createdAt.toString().split(' ')[0],
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          const Divider(),
          const SizedBox(height: 30),
          // 설명
          if (_selectedGallery!.description != null && _selectedGallery!.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: Text(
                _selectedGallery!.description!,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF374151),
                  height: 1.6,
                ),
              ),
            ),
          // 사진 목록
          if (_selectedGallery!.imageUrls.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '사진',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 20),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: _selectedGallery!.imageUrls.length,
                  itemBuilder: (context, index) {
                    final imageUrl = _selectedGallery!.imageUrls[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image, size: 48, color: Color(0xFF9CA3AF)),
                            SizedBox(height: 8),
                            Text(
                              '이미지',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 900;

        return Container(
          color: const Color(0xFF1F2937),
          padding: EdgeInsets.all(isMobile ? 30 : (isTablet ? 40 : 60)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.rocket_launch,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Flexible(
                              child: Text(
                                '인천장애인능력개발협회',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          '(사)인천장애인능력개발협회는 2010년에 설립, 장애인 엑스포 직업체험 참여를 시작으로 '
                          '미국 하와이 장애인 엑스포에도 참가할 정도로 장애인들의 교육을 통한 성장을 위해 힘을 다하고 있다. '
                          '장애인의 직업재활을 통한 사회참여를 독려 및 지속적인 장애인 직업재활 훈련을 진행하고 있다. '
                          '특별히 장애인 인재개발센터 설립 장애 영역별 맞춤 일자리 개발 진행하며 '
                          '능력 있는 장애인 전문가 양성을 통한 장애인의 사회참여 확대의 방향을 제시하고 있다.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13,
                            height: 1.7,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '주소: 인천 중구 월미문화로 95 3층',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tel. 010-9114-5923',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          '바로가기',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildFooterLink('개인정보처리방침'),
                        _buildFooterLink('이용약관'),
                        _buildFooterLink('오시는 길'),
                        _buildFooterLink('사이트맵'),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.rocket_launch,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '인천장애인능력개발협회',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isTablet ? 16 : 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Text(
                                '(사)인천장애인능력개발협회는 2010년에 설립, 장애인 엑스포 직업체험 참여를 시작으로\n'
                                '미국 하와이 장애인 엑스포에도 참가할 정도로 장애인들의 교육을 통한 성장을 위해 힘을 다하고 있다.\n'
                                '장애인의 직업재활을 통한 사회참여를 독려 및 지속적인 장애인 직업재활 훈련을 진행하고 있다.\n'
                                '특별히 장애인 인재개발센터 설립 장애 영역별 맞춤 일자리 개발 진행하며\n'
                                '능력 있는 장애인 전문가 양성을 통한 장애인의 사회참여 확대의 방향을 제시하고 있다.',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: isTablet ? 13 : 14,
                                  height: 1.8,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                '주소: 인천 중구 월미문화로 95 3층',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: isTablet ? 13 : 14,
                                  height: 1.6,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tel. 010-9114-5923',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: isTablet ? 13 : 14,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '바로가기',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: isTablet ? 15 : 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildFooterLink('개인정보처리방침'),
                              _buildFooterLink('이용약관'),
                              _buildFooterLink('오시는 길'),
                              _buildFooterLink('사이트맵'),
                            ],
                          ),
                        ),
                      ],
                    ),
              SizedBox(height: isMobile ? 24 : 40),
              Container(
                height: 1,
                color: Colors.white.withOpacity(0.1),
              ),
              SizedBox(height: isMobile ? 16 : 24),
              Text(
                'Copyright © 2025 인천장애인능력개발협회. All Rights Reserved.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: isMobile ? 12 : 13,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooterLink(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextButton(
        onPressed: () {},
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, 0),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // 게시글 상세 페이지
  Widget _buildNoticeDetailPage() {
    if (_selectedNotice == null) {
      return Container();
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 뒤로가기 버튼
          InkWell(
            onTap: () {
              setState(() {
                _currentPage = 2;
              });
            },
            child: Row(
              children: [
                const Icon(Icons.arrow_back, size: 20, color: Color(0xFF6366F1)),
                const SizedBox(width: 8),
                const Text(
                  '목록으로',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          // 게시글 내용
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 분류 배지
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getCategoryColor(_selectedNotice!.category).withOpacity(0.15),
                        _getCategoryColor(_selectedNotice!.category).withOpacity(0.05)
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _selectedNotice!.category,
                    style: TextStyle(
                      color: _getCategoryColor(_selectedNotice!.category),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // 제목
                Text(
                  _selectedNotice!.title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 20),
                // 메타 정보
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: const Color(0xFF9CA3AF)),
                    const SizedBox(width: 6),
                    Text(
                      _selectedNotice!.author,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Icon(Icons.calendar_today, size: 16, color: const Color(0xFF9CA3AF)),
                    const SizedBox(width: 6),
                    Text(
                      _selectedNotice!.createdAt.toString().split(' ')[0],
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Icon(Icons.visibility, size: 16, color: const Color(0xFF9CA3AF)),
                    const SizedBox(width: 6),
                    Text(
                      _selectedNotice!.views.toString(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Container(
                  height: 1,
                  color: const Color(0xFFE5E7EB),
                ),
                const SizedBox(height: 30),
                // 내용
                Text(
                  _selectedNotice!.content,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF374151),
                    height: 1.8,
                  ),
                ),
                // 첨부 파일
                if (_selectedNotice!.fileUrls.isNotEmpty) ...[
                  const SizedBox(height: 40),
                  Container(
                    height: 1,
                    color: const Color(0xFFE5E7EB),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    '첨부파일',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(_selectedNotice!.fileUrls.length, (index) {
                    final fileName = _selectedNotice!.fileNames[index];
                    final fileUrl = _selectedNotice!.fileUrls[index];
                    final extension = fileName.split('.').last.toLowerCase();

                    return InkWell(
                      onTap: () async {
                        // 파일 다운로드 또는 새 탭에서 열기
                        final uri = Uri.parse(fileUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getFileIcon(extension),
                              color: const Color(0xFF6366F1),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                fileName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF374151),
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.download,
                              color: Color(0xFF6366F1),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
                // 이전 주석 처리된 파일 코드
                /* if (_selectedNotice!['fileCount'] != null && _selectedNotice!['fileCount'] > 0) ...[
                  const SizedBox(height: 40),
                  Container(
                    height: 1,
                    color: const Color(0xFFE5E7EB),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    '첨부파일',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...(_selectedNotice!['files'] as List).map((fileName) {
                    final extension = fileName.split('.').last;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getFileIcon(extension),
                            color: const Color(0xFF6366F1),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              fileName,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF374151),
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.download,
                            color: Color(0xFF6366F1),
                            size: 20,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ], */
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case '공지':
        return const Color(0xFF6366F1);
      case '교육':
        return const Color(0xFF8B5CF6);
      case '행사':
        return const Color(0xFFEC4899);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  // 협회소개 페이지
  Widget _buildAboutPage() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 페이지 타이틀
          const Text(
            '법인 소개',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 60),

          // 1. 기관설립 및 연혁
          _buildSection(
            '1. 기관설립 및 연혁',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildText('○ 인천시 동구에 위치한 장애인재활시설로 장애인 복지에 이바지하고자 설립된 기관으로서'),
                _buildText('  구분에 없이 전국의 모든 장애인을 위한 직업 재활과 취업의지가 있는 모든 '),
                _buildText('  장애인의 자활과 자립에 열정적으로 활동하고 있습니다.'),
                const SizedBox(height: 30),
                _buildHistoryTable(),
              ],
            ),
          ),

          const SizedBox(height: 60),

          // 2. 조직 및 인력현황
          _buildSection(
            '2. 조직 및 인력현황',
            Column(
              children: [
                _buildOrgChart(),
              ],
            ),
          ),

          const SizedBox(height: 60),

          // 3. 주요사업
          _buildSection(
            '3. 주요사업',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBusinessItem(
                  '○ 직업재활',
                  '직업재활이란 장애인의 능력을 개발하고 이를 활용할 수 있도록 함으로써 생산자로서의 자신감과\n'
                  '자긍심을 회복할 수 있도록 도움을 주는 장애인복지 중 하나입니다.',
                ),
                _buildBusinessItem(
                  '○ 직업평가',
                  '※ 직업평가란?\n'
                  '  - 내담자와의 면담(접수면접), 관찰, 검사를 통해 내담자의 신체적, 심리적, 사회적, 직업적\n'
                  '    특성과 능력을 파악하는 것입니다.\n'
                  '  ※ 작업 표본평가(직업평가) 및 작업수행력 평가를 통해 개별적인 사안 설계 작업능력에 대한 평가',
                ),
                _buildBusinessItem(
                  '○ 직업적응훈련',
                  '장애인의 특성을 파악하여 다양한 직종의 직업훈련을 실시함으로써 기술 및 지식을 습득하고\n'
                  '습득한 기술 및 지식을 활용하여 전공과정의 직업 훈련을 통하여 작업장의 조기 배치 및 장기\n'
                  '배치로 지속적인 소득을 가능하게 하는 사업',
                ),
                _buildBusinessItem(
                  '○ 직업훈련\n  (취업 및 기타)',
                  '일정한 훈련 프로그램을 통하여 훈련생들이 직무수행에 필요한 지식과 기능 등을 학습하는 것으로\n'
                  '기술 습득을 목적으로 하는 기능훈련과 직무수행 태도를 목적으로 하는 사회적응훈련으로 구분되며\n'
                  '여러분의 관심과 격려가 필요합니다.',
                ),
                _buildBusinessItem(
                  '○ 취업알선',
                  '※ 내용 : 1급, 2급 직능 장애인들은 직업상담사가 1:1 개별상담을 실시합니다.\n'
                  '  ※ 대상 인원을 참고하여 방문취업 경우 체험을 우선합니다.\n'
                  '※ 직업 상담 결과에 따라 장기간 직업능력개발 훈련(직업능력훈련, 향상훈련 및 활용능력 향상훈련 등)\n'
                  '  자립을 지원합니다.',
                ),
                _buildBusinessItem(
                  '○ 지원고용',
                  '※ 장애인 실직 공개 : 실직 현장에서 도구 사용법 등 의 수행방법을 배웁니다.\n\n'
                  '※ 지속적인 지원 : 효율적인 업무 수행이 가능하게 지원 고용 지원이 제공합니다.\n\n'
                  '※ 사업주 측 : 장애인복지를 위한 고용에 대한 지원을 받습니다.',
                ),
                _buildBusinessItem(
                  '○ 취업 후 적응지도',
                  '직업훈련을 통한 전문 기술을 습득한 장애인이 실제 작업현장에서 적응하도록 사업주에게 장애인\n'
                  '직원 관리 및 근로환경에 조성에 대한 필요한 정보 제공, 훈련생의 작업능력 및 사회적응능력\n'
                  '향상을 돕고 지속적인 고용유지를 위해 사업주와 훈련생에게 실시하는 사업입니다.',
                ),
                _buildBusinessItem(
                  '○ 장애인식\n  개선사업',
                  '※ 장애인에 대한 인식을 개선하기 위하여 지역사회 장애인과 비장애인과의 통합 교육프로그램 실시\n\n'
                  '※ 장애인 : 비장애인의 만남을 통하여 비장애인은 장애에 대한 이해와 정보를 제공받고, 장애인은\n'
                  '  사회통합에의 계기를 마련합니다.',
                ),
                _buildBusinessItem(
                  '○ 기타',
                  '・장애인 직업재활 서비스 강화를 위한 서비스 개발 및 보급\n'
                  '・지역사회 장애인을 위한 직업 기술 및 사회적응 프로그램 개발과 보급\n'
                  '・사회통합을 위한 다양한 복지연계 활동',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          content,
        ],
      ),
    );
  }

  Widget _buildText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFF374151),
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildHistoryTable() {
    final history = [
      {'year': '2006.02', 'content': '직업훈련시설 조세조정 등에 관한 법률에 따른 지정기부금단체 지정'},
      {'year': '', 'content': '장애인 직업재활시설 근로 지원사업 종합'},
      {'year': '2006.01', 'content': '제12대 고은미 이사장 취임'},
      {'year': '2005.06', 'content': '제11대 복지마을 "호두마을집" 현장 직업훈련 종료'},
      {'year': '2005.05', 'content': '장애인 직업재활시설 근로 지원사업 종합'},
      {'year': '2011.03', 'content': '종합재활시설로 시설 이전'},
      {'year': '2011.02', 'content': '제11대 김남애 이사장 취임, 연고기준단체 임기 종료 연임'},
      {'year': '2011.01', 'content': '전문장애인훈련센터 운영개시'},
      {'year': '', 'content': '사무실 보완공사 완료'},
      {'year': '2010.03', 'content': '인천광역시장애인직업훈련센터 지정 위탁 운영'},
      {'year': '', 'content': '창업지원 프로그램 구축'},
      {'year': '2012.11', 'content': '제12대 김길자 이사장 취임'},
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: history.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: index.isEven ? const Color(0xFFF9FAFB) : Colors.white,
              border: index < history.length - 1
                  ? const Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    item['year']!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    item['content']!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOrgChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          'assets/images/orgchart.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 400,
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.image,
                      size: 80,
                      color: Color(0xFF9CA3AF),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '조직도 이미지 영역',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'assets/images/orgchart.png',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFFD1D5DB),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrgBox(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: color.computeLuminance() > 0.5 ? Colors.black87 : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildBusinessItem(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF374151),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // 공지사항 페이지
  Widget _buildNoticePage() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 페이지 타이틀
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '공지사항',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              Row(
                children: [
                  if (_isAdmin) ...[
                    InkWell(
                      onTap: _showWriteNoticeDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.edit, size: 18, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              '글쓰기',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.article, size: 18, color: Color(0xFF6366F1)),
                        const SizedBox(width: 8),
                        Text(
                          '전체 ${_notices.length}건',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 40),

          // 게시판 테이블
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // 테이블 헤더
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 60,
                        child: Text(
                          '번호',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      SizedBox(
                        width: 80,
                        child: Text(
                          '분류',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Text(
                          '제목',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: Text(
                          '작성자',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      SizedBox(
                        width: 100,
                        child: Text(
                          '작성일',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      SizedBox(
                        width: 80,
                        child: Text(
                          '조회수',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 게시글 목록
                ..._notices.asMap().entries.map((entry) {
                  final index = entry.key;
                  final notice = entry.value;
                  return _buildNoticeRow(notice, index);
                }).toList(),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // 페이지네이션
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPageButton('<<', false),
              const SizedBox(width: 8),
              _buildPageButton('<', false),
              const SizedBox(width: 16),
              _buildPageButton('1', true),
              _buildPageButton('2', false),
              _buildPageButton('3', false),
              _buildPageButton('4', false),
              _buildPageButton('5', false),
              const SizedBox(width: 16),
              _buildPageButton('>', false),
              const SizedBox(width: 8),
              _buildPageButton('>>', false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeRow(Notice notice, int index) {
    Color getCategoryColor(String category) {
      switch (category) {
        case '공지':
          return const Color(0xFF6366F1);
        case '교육':
          return const Color(0xFF8B5CF6);
        case '행사':
          return const Color(0xFFEC4899);
        default:
          return const Color(0xFF9CA3AF);
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: BoxDecoration(
        color: index.isEven ? Colors.white : const Color(0xFFFAFAFC),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedNotice = notice;
            _currentPage = 6;
            // Note: views는 immutable이므로 증가시키려면 Supabase 업데이트 필요
          });
        },
        child: Row(
          children: [
            // 번호
            SizedBox(
              width: 60,
              child: Text(
                '${_notices.length - index}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 20),
            // 분류
            SizedBox(
              width: 80,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: getCategoryColor(notice.category).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  notice.category,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: getCategoryColor(notice.category),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            // 제목
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      notice.title,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF1F2937),
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (notice.isNew) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'N',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  /* if (notice['fileCount'] != null && notice['fileCount'] > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.attach_file,
                            size: 12,
                            color: Color(0xFF6366F1),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${notice['fileCount']}',
                            style: const TextStyle(
                              color: Color(0xFF6366F1),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ], */
                ],
              ),
            ),
            // 작성자
            SizedBox(
              width: 100,
              child: Text(
                notice.author,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
            const SizedBox(width: 20),
            // 작성일
            SizedBox(
              width: 100,
              child: Text(
                notice.createdAt.toString().split(' ')[0],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
            const SizedBox(width: 20),
            // 조회수
            SizedBox(
              width: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.visibility, size: 14, color: Color(0xFF9CA3AF)),
                  const SizedBox(width: 4),
                  Text(
                    notice.views.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageButton(String text, bool isActive) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: isActive
            ? const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              )
            : null,
        color: isActive ? null : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? Colors.transparent : const Color(0xFFE5E7EB),
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
            color: isActive ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  // 로그인 다이얼로그
  void _showLoginDialog() {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 24),
                const Text(
                  '로그인',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: '이메일',
                    prefixIcon: const Icon(Icons.email, color: Color(0xFF6366F1)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: '비밀번호',
                    prefixIcon: const Icon(Icons.lock, color: Color(0xFF6366F1)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                    ),
                  ),
                  onSubmitted: (_) async {
                    await _handleLogin(emailController.text, passwordController.text, context, setDialogState, (val) {
                      isLoading = val;
                    });
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '계정이 없으신가요? ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showSignupDialog();
                      },
                      child: const Text(
                        '회원가입',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                        ),
                        child: const Text(
                          '취소',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isLoading ? null : () async {
                          await _handleLogin(emailController.text, passwordController.text, context, setDialogState, (val) {
                            setDialogState(() {
                              isLoading = val;
                            });
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            constraints: const BoxConstraints(minHeight: 48),
                            child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    '로그인',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 로그인 처리
  Future<void> _handleLogin(String email, String password, BuildContext context, StateSetter setDialogState, Function(bool) setLoading) async {
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이메일과 비밀번호를 입력해주세요.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setLoading(true);

    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        setState(() {
          _isLoggedIn = true;
          _loggedInUser = response.user!.email ?? '';
        });
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('환영합니다, ${response.user!.email}님!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('로그인 실패: ${e.message}'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류가 발생했습니다: ${e.toString()}'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    } finally {
      setLoading(false);
    }
  }

  // 회원가입 다이얼로그
  void _showSignupDialog() {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_add, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 24),
                const Text(
                  '회원가입',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: '이메일',
                    prefixIcon: const Icon(Icons.email, color: Color(0xFF6366F1)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: '비밀번호 (최소 6자)',
                    prefixIcon: const Icon(Icons.lock, color: Color(0xFF6366F1)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: '비밀번호 확인',
                    prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF6366F1)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '이미 계정이 있으신가요? ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showLoginDialog();
                      },
                      child: const Text(
                        '로그인',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                        ),
                        child: const Text(
                          '취소',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isLoading ? null : () async {
                          await _handleSignup(
                            emailController.text,
                            passwordController.text,
                            confirmPasswordController.text,
                            context,
                            setDialogState,
                            (val) {
                              setDialogState(() {
                                isLoading = val;
                              });
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            constraints: const BoxConstraints(minHeight: 48),
                            child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    '가입하기',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 회원가입 처리
  Future<void> _handleSignup(String email, String password, String confirmPassword, BuildContext context, StateSetter setDialogState, Function(bool) setLoading) async {
    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('모든 필드를 입력해주세요.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('비밀번호가 일치하지 않습니다.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('비밀번호는 최소 6자 이상이어야 합니다.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setLoading(true);

    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('회원가입이 완료되었습니다! 로그인해주세요.'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 3),
          ),
        );
        // 회원가입 후 로그인 다이얼로그 표시
        Future.delayed(Duration(milliseconds: 500), () {
          _showLoginDialog();
        });
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('회원가입 실패: ${e.message}'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류가 발생했습니다: ${e.toString()}'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    } finally {
      setLoading(false);
    }
  }

  // 글쓰기 다이얼로그
  void _showWriteNoticeDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController contentController = TextEditingController();
    final TextEditingController nicknameController = TextEditingController(text: '관리자');
    String selectedCategory = '공지';
    List<PlatformFile> selectedFiles = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 600,
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.edit, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      '공지사항 작성',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Text(
                  '분류',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildCategoryChip('공지', selectedCategory, (value) {
                      setDialogState(() {
                        selectedCategory = value;
                      });
                    }),
                    const SizedBox(width: 8),
                    _buildCategoryChip('교육', selectedCategory, (value) {
                      setDialogState(() {
                        selectedCategory = value;
                      });
                    }),
                    const SizedBox(width: 8),
                    _buildCategoryChip('행사', selectedCategory, (value) {
                      setDialogState(() {
                        selectedCategory = value;
                      });
                    }),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: nicknameController,
                  decoration: InputDecoration(
                    labelText: '작성자 닉네임',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: '제목',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  maxLines: 8,
                  decoration: InputDecoration(
                    labelText: '내용',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // 파일 첨부 섹션
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '파일 첨부',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(최대 5개)',
                          style: TextStyle(
                            fontSize: 12,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        FilePickerResult? result = await FilePicker.platform.pickFiles(
                          allowMultiple: true,
                          type: FileType.any,
                        );

                        if (result != null) {
                          setDialogState(() {
                            if (selectedFiles.length + result.files.length <= 5) {
                              selectedFiles.addAll(result.files);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('파일은 최대 5개까지 첨부할 수 있습니다.'),
                                  backgroundColor: Color(0xFFEF4444),
                                ),
                              );
                            }
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE5E7EB),
                            style: BorderStyle.solid,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_upload_outlined,
                              color: const Color(0xFF6366F1),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '파일 선택',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF6366F1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (selectedFiles.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          children: selectedFiles.asMap().entries.map((entry) {
                            final index = entry.key;
                            final file = entry.value;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    _getFileIcon(file.extension ?? ''),
                                    color: const Color(0xFF6366F1),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      file.name,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF374151),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    _formatFileSize(file.size),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: const Color(0xFF9CA3AF),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () {
                                      setDialogState(() {
                                        selectedFiles.removeAt(index);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444).withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Color(0xFFEF4444),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                        ),
                        child: const Text(
                          '취소',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (titleController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('제목을 입력해주세요.'),
                                backgroundColor: Color(0xFFEF4444),
                              ),
                            );
                            return;
                          }

                          if (contentController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('내용을 입력해주세요.'),
                                backgroundColor: Color(0xFFEF4444),
                              ),
                            );
                            return;
                          }

                          // Supabase에 공지사항 저장
                          try {
                            final user = supabase.auth.currentUser;
                            print('현재 사용자: ${user?.email}');

                            if (user == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('로그인이 필요합니다.'),
                                  backgroundColor: Color(0xFFEF4444),
                                ),
                              );
                              return;
                            }

                            // 파일 업로드 처리
                            List<String> uploadedFileUrls = [];
                            List<String> uploadedFileNames = [];

                            if (selectedFiles.isNotEmpty) {
                              print('파일 업로드 시작: ${selectedFiles.length}개');

                              for (var file in selectedFiles) {
                                try {
                                  final bytes = file.bytes;
                                  if (bytes == null) continue;

                                  // 파일명에서 특수문자 제거 및 공백을 언더스코어로 변경
                                  final timestamp = DateTime.now().millisecondsSinceEpoch;
                                  final safeName = file.name
                                      .replaceAll(RegExp(r'[^\w\s\.-]'), '') // 특수문자 제거
                                      .replaceAll(RegExp(r'\s+'), '_');      // 공백을 언더스코어로
                                  final fileName = '${user.id}/$timestamp-$safeName';

                                  // Supabase Storage에 업로드
                                  final uploadPath = await supabase.storage
                                      .from('notice-files')
                                      .uploadBinary(fileName, bytes);

                                  // 업로드된 파일의 공개 URL 가져오기
                                  final fileUrl = supabase.storage
                                      .from('notice-files')
                                      .getPublicUrl(fileName);

                                  uploadedFileUrls.add(fileUrl);
                                  uploadedFileNames.add(file.name);
                                  print('파일 업로드 성공: ${file.name}');
                                } catch (fileError) {
                                  print('파일 업로드 실패: ${file.name}, 에러: $fileError');
                                }
                              }
                            }

                            print('공지사항 저장 시도...');
                            final response = await supabase.from('notices').insert({
                              'title': titleController.text,
                              'content': contentController.text,
                              'author': nicknameController.text.isNotEmpty ? nicknameController.text : '관리자',
                              'author_id': user.id,
                              'category': selectedCategory,
                              'views': 0,
                              'is_new': true,
                              'file_urls': uploadedFileUrls,
                              'file_names': uploadedFileNames,
                            }).select();

                            print('Supabase 응답: $response');

                            if (response.isNotEmpty) {
                              // 로컬 리스트에도 추가
                              final newNotice = Notice.fromJson(response.first);
                              setState(() {
                                _notices.insert(0, newNotice);
                              });

                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(selectedFiles.isEmpty
                                      ? '공지사항이 등록되었습니다.'
                                      : '공지사항이 등록되었습니다. (파일 ${uploadedFileUrls.length}개 첨부)'),
                                  backgroundColor: Color(0xFF10B981),
                                ),
                              );
                            }
                          } catch (e) {
                            print('공지사항 등록 에러: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('공지사항 등록 실패: $e'),
                                backgroundColor: Color(0xFFEF4444),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            constraints: const BoxConstraints(minHeight: 48),
                            child: const Text(
                              '등록',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(
      String category, String selectedCategory, Function(String) onSelect) {
    final isSelected = category == selectedCategory;
    Color categoryColor;
    switch (category) {
      case '공지':
        categoryColor = const Color(0xFF6366F1);
        break;
      case '교육':
        categoryColor = const Color(0xFF8B5CF6);
        break;
      case '행사':
        categoryColor = const Color(0xFFEC4899);
        break;
      default:
        categoryColor = const Color(0xFF9CA3AF);
    }

    return InkWell(
      onTap: () => onSelect(category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? categoryColor : categoryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: categoryColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          category,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : categoryColor,
          ),
        ),
      ),
    );
  }

  // 파일 아이콘 가져오기
  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.folder_zip;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  // 파일 크기 포맷팅
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  void _showGalleryWriteDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    List<PlatformFile> selectedImages = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 600,
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add_photo_alternate, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      '활동 사진 등록',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: '제목',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: '설명',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // 사진 첨부 섹션
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '사진 첨부',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(최대 10개)',
                          style: TextStyle(
                            fontSize: 12,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        FilePickerResult? result = await FilePicker.platform.pickFiles(
                          allowMultiple: true,
                          type: FileType.image,
                        );

                        if (result != null) {
                          setDialogState(() {
                            if (selectedImages.length + result.files.length <= 10) {
                              selectedImages.addAll(result.files);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('사진은 최대 10개까지 첨부할 수 있습니다.'),
                                  backgroundColor: Color(0xFFEF4444),
                                ),
                              );
                            }
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFFF9FAFB),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate, color: Color(0xFF6366F1)),
                            SizedBox(width: 12),
                            Text(
                              '사진 선택',
                              style: TextStyle(
                                color: Color(0xFF6366F1),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (selectedImages.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '선택된 사진 (${selectedImages.length}개)',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF374151),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...selectedImages.map((file) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    const Icon(Icons.image, size: 20, color: Color(0xFF6366F1)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        file.name,
                                        style: const TextStyle(fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 20),
                                      onPressed: () {
                                        setDialogState(() {
                                          selectedImages.remove(file);
                                        });
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                      child: const Text(
                        '취소',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (titleController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('제목을 입력해주세요.'),
                              backgroundColor: Color(0xFFEF4444),
                            ),
                          );
                          return;
                        }

                        if (selectedImages.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('사진을 선택해주세요.'),
                              backgroundColor: Color(0xFFEF4444),
                            ),
                          );
                          return;
                        }

                        // TODO: Supabase에 갤러리 저장 구현 필요
                        /* setState(() {
                          _galleryItems.add({
                            'id': (_galleryItems.length + 1).toString(),
                            'title': titleController.text,
                            'description': descriptionController.text,
                            'date': '2025-10-24',
                            'author': _loggedInUser,
                            'images': selectedImages,
                            'image': selectedImages.isNotEmpty ? selectedImages[0] : null,
                          });
                        }); */

                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('활동 사진이 등록되었습니다.'),
                            backgroundColor: Color(0xFF10B981),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '등록',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPressReleaseWriteDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController contentController = TextEditingController();
    List<PlatformFile> selectedFiles = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 600,
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.article, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      '보도자료 작성',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: '제목',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  maxLines: 8,
                  decoration: InputDecoration(
                    labelText: '내용',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // 파일 첨부 섹션
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '파일 첨부',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(최대 5개)',
                          style: TextStyle(
                            fontSize: 12,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        FilePickerResult? result = await FilePicker.platform.pickFiles(
                          allowMultiple: true,
                          type: FileType.any,
                        );

                        if (result != null) {
                          setDialogState(() {
                            if (selectedFiles.length + result.files.length <= 5) {
                              selectedFiles.addAll(result.files);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('파일은 최대 5개까지 첨부할 수 있습니다.'),
                                  backgroundColor: Color(0xFFEF4444),
                                ),
                              );
                            }
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFFF9FAFB),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.attach_file, color: Color(0xFF6366F1)),
                            SizedBox(width: 12),
                            Text(
                              '파일 선택',
                              style: TextStyle(
                                color: Color(0xFF6366F1),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (selectedFiles.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '첨부된 파일 (${selectedFiles.length}개)',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF374151),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...selectedFiles.map((file) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Icon(_getFileIcon(file.extension ?? ''), size: 20, color: const Color(0xFF6366F1)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        file.name,
                                        style: const TextStyle(fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 20),
                                      onPressed: () {
                                        setDialogState(() {
                                          selectedFiles.remove(file);
                                        });
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                      child: const Text(
                        '취소',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (titleController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('제목을 입력해주세요.'),
                              backgroundColor: Color(0xFFEF4444),
                            ),
                          );
                          return;
                        }

                        if (contentController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('내용을 입력해주세요.'),
                              backgroundColor: Color(0xFFEF4444),
                            ),
                          );
                          return;
                        }

                        // TODO: Supabase에 보도자료 저장 구현 필요
                        /* setState(() {
                          _pressReleases.insert(0, {
                            'id': (_pressReleases.length + 1).toString(),
                            'title': titleController.text,
                            'content': contentController.text,
                            'date': '2025-10-24',
                            'author': _loggedInUser,
                            'views': '0',
                            'isNew': true,
                            'files': selectedFiles,
                          });
                        }); */

                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('보도자료가 등록되었습니다.'),
                            backgroundColor: Color(0xFF10B981),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '등록',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
