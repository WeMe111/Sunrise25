import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:html' as html;
import 'dart:async';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'config/admin_config.dart';
import 'models/notice_model.dart';
import 'models/gallery_model.dart';
import 'models/press_release_model.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '인천장애인능력개발협회',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
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
  int _currentPage = 0;
  bool _isLoggedIn = false;
  String _loggedInUser = '';
  bool _isMobileMenuOpen = false;
  List<Notice> _notices = [];
  Notice? _selectedNotice;
  List<Gallery> _galleryItems = [];
  Gallery? _selectedGallery;
  List<PressRelease> _pressReleases = [];
  PressRelease? _selectedPressRelease;
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();
  int _hoveredNavIndex = -1;
  String _selectedNoticeTab = '전체';
  int _heroSlideIndex = 0;
  Timer? _heroTimer;
  int _hoveredQuickMenuIndex = -1;

  final List<Map<String, String>> _heroSlides = [
    {
      'title': '행복한 어울림,\n함께하는 세상',
      'subtitle': '(사)인천장애인능력개발협회가 장애인의\n능력개발과 사회참여를 함께합니다.',
      'color': '0xFF3B82F6',
    },
    {
      'title': '교육으로 여는\n새로운 가능성',
      'subtitle': '성인장애인 평생교육과 직업재활 훈련으로\n자립의 꿈을 실현합니다.',
      'color': '0xFF10B981',
    },
    {
      'title': '당신의 따뜻한\n관심이 힘이 됩니다',
      'subtitle': '후원과 봉사로 장애인의 삶에\n희망의 빛을 더해주세요.',
      'color': '0xFFF59E0B',
    },
  ];

  @override
  void initState() {
    super.initState();
    _youtubeController = YoutubePlayerController.fromVideoId(
      videoId: 'Ff21gFHq1GI',
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: false,
        showFullscreenButton: false,
        mute: true,
        enableCaption: false,
        playsInline: true,
      ),
    );
    _loadDataFromSupabase();
    _checkSession();
    _startHeroSlider();
  }

  void _startHeroSlider() {
    _heroTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        setState(() => _heroSlideIndex = (_heroSlideIndex + 1) % _heroSlides.length);
      }
    });
  }

  Future<void> _checkSession() async {
    final session = supabase.auth.currentSession;
    if (session != null) {
      setState(() { _isLoggedIn = true; _loggedInUser = session.user.email ?? ''; });
    }
  }

  Future<void> _loadDataFromSupabase() async {
    await Future.wait([_loadNotices(), _loadGallery(), _loadPressReleases()]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadNotices() async {
    try {
      final response = await supabase.from('notices').select().order('created_at', ascending: false);
      setState(() => _notices = (response as List).map((n) => Notice.fromJson(n)).toList());
    } catch (e) { debugPrint('공지사항 로드 오류: $e'); }
  }

  Future<void> _loadGallery() async {
    try {
      final response = await supabase.from('gallery').select().order('created_at', ascending: false);
      setState(() => _galleryItems = (response as List).map((g) => Gallery.fromJson(g)).toList());
    } catch (e) { debugPrint('갤러리 로드 오류: $e'); }
  }

  Future<void> _loadPressReleases() async {
    try {
      final response = await supabase.from('press_releases').select().order('created_at', ascending: false);
      setState(() => _pressReleases = (response as List).map((p) => PressRelease.fromJson(p)).toList());
    } catch (e) { debugPrint('보도자료 로드 오류: $e'); }
  }

  bool get _isAdmin => AdminConfig.isAdmin(_loggedInUser);
  bool _isMobile(BuildContext context) => MediaQuery.of(context).size.width < 768;
  double _maxWidth(BuildContext context) => 1200;

  @override
  void dispose() {
    _youtubeController.close();
    _scrollController.dispose();
    _heroTimer?.cancel();
    super.dispose();
  }

  void _navigateTo(int page) {
    setState(() { _currentPage = page; _isMobileMenuOpen = false; });
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.secondary, AppColors.accent]),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.diversity_3, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 24),
              SizedBox(width: 160, child: LinearProgressIndicator(
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation(AppColors.secondary),
                borderRadius: BorderRadius.circular(4),
              )),
            ]))
          : SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  _buildTopUtilityBar(),
                  _buildHeader(),
                  _buildNavigation(),
                  if (_currentPage == 0) ...[
                    _buildHeroSlider(),
                    FadeSlideIn(delay: const Duration(milliseconds: 200), child: _buildQuickMenu()),
                    FadeSlideIn(delay: const Duration(milliseconds: 400), child: _buildNewsAndGallerySection()),
                    FadeSlideIn(delay: const Duration(milliseconds: 500), child: _buildStatsSection()),
                    FadeSlideIn(delay: const Duration(milliseconds: 600), child: _buildVideoSection()),
                  ] else if (_currentPage == 1)
                    ...[_buildBreadcrumb('협회소개'), FadeSlideIn(child: _buildAboutPage())]
                  else if (_currentPage == 2)
                    ...[_buildBreadcrumb('공지사항'), FadeSlideIn(child: _buildNoticePage())]
                  else if (_currentPage == 3)
                    ...[_buildBreadcrumb('활동갤러리'), FadeSlideIn(child: _buildActivityGalleryPage())]
                  else if (_currentPage == 4)
                    ...[_buildBreadcrumb('보도자료'), FadeSlideIn(child: _buildPressReleasePage())]
                  else if (_currentPage == 5)
                    ...[_buildBreadcrumb('후원하기'), FadeSlideIn(child: _buildDonationPage())]
                  else if (_currentPage == 6)
                    ...[_buildBreadcrumb('공지사항', sub: _selectedNotice?.title), FadeSlideIn(child: _buildNoticeDetailPage())]
                  else if (_currentPage == 7)
                    ...[_buildBreadcrumb('활동갤러리', sub: _selectedGallery?.title), FadeSlideIn(child: _buildGalleryDetailPage())]
                  else if (_currentPage == 8)
                    ...[_buildBreadcrumb('보도자료', sub: _selectedPressRelease?.title), FadeSlideIn(child: _buildPressReleaseDetailPage())],
                  _buildFooter(),
                ],
              ),
            ),
    );
  }

  // ═══════════════════════════════════════════
  //  TOP UTILITY BAR
  // ═══════════════════════════════════════════
  Widget _buildTopUtilityBar() {
    final mobile = _isMobile(context);
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
      ),
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: _maxWidth(context)),
          padding: EdgeInsets.symmetric(horizontal: mobile ? 16 : 20, vertical: 6),
          child: Row(
            children: [
              if (!mobile) ...[
                Icon(Icons.phone, size: 13, color: Colors.white.withOpacity(0.6)),
                const SizedBox(width: 4),
                Text('010-9114-5923', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
              ],
              const Spacer(),
              if (_isLoggedIn) ...[
                Text(_loggedInUser, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                _utilBarDivider(),
                _utilBarBtn('로그아웃', () async {
                  await supabase.auth.signOut();
                  setState(() { _isLoggedIn = false; _loggedInUser = ''; });
                }),
              ] else ...[
                _utilBarBtn('로그인', _showLoginDialog),
                _utilBarDivider(),
                _utilBarBtn('회원가입', _showSignupDialog),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _utilBarBtn(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
      ),
    );
  }

  Widget _utilBarDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text('|', style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 12)),
    );
  }

  // ═══════════════════════════════════════════
  //  HEADER
  // ═══════════════════════════════════════════
  Widget _buildHeader() {
    final mobile = _isMobile(context);
    return Container(
      color: AppColors.surface,
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: _maxWidth(context)),
          padding: EdgeInsets.symmetric(horizontal: mobile ? 16 : 20, vertical: mobile ? 14 : 20),
          child: Row(
            children: [
              InkWell(
                onTap: () => _navigateTo(0),
                child: Row(
                  children: [
                    Image.asset('assets/images/logo.png', height: mobile ? 36 : 52, fit: BoxFit.contain),
                    if (!mobile) ...[
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text('인천장애인능력개발협회',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1.2)),
                          SizedBox(height: 2),
                          Text('Incheon Ability Development Association',
                            style: TextStyle(fontSize: 11, color: AppColors.textMuted, letterSpacing: 0.3)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Spacer(),
              if (!mobile)
                Row(
                  children: [
                    _headerIconBtn(Icons.search, '검색', () {}),
                    const SizedBox(width: 4),
                    _headerIconBtn(Icons.language, '사이트맵', () {}),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerIconBtn(IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, size: 18, color: AppColors.textSecondary),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  NAVIGATION
  // ═══════════════════════════════════════════
  Widget _buildNavigation() {
    final mobile = _isMobile(context);
    final navItems = ['협회소개', '공지사항', '활동갤러리', '보도자료', '후원하기'];

    if (mobile) {
      return Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('MENU', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1)),
                IconButton(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(_isMobileMenuOpen ? Icons.close : Icons.menu, key: ValueKey(_isMobileMenuOpen), color: Colors.white, size: 22),
                  ),
                  onPressed: () => setState(() => _isMobileMenuOpen = !_isMobileMenuOpen),
                ),
              ],
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [AppColors.primaryLight, AppColors.primary],
                ),
              ),
              child: Column(
                children: navItems.asMap().entries.map((e) {
                  final isActive = _currentPage == e.key + 1;
                  return InkWell(
                    onTap: () => _navigateTo(e.key + 1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.white.withOpacity(0.1) : Colors.transparent,
                        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06))),
                      ),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: isActive ? 3 : 0, height: 16,
                            margin: EdgeInsets.only(right: isActive ? 10 : 0),
                            decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(2)),
                          ),
                          Text(e.value, style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            crossFadeState: _isMobileMenuOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight, AppColors.primary]),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: _maxWidth(context)),
          child: Row(
            children: navItems.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final label = entry.value;
              final isActive = _currentPage == idx;
              final isHovered = _hoveredNavIndex == idx;
              return Expanded(
                child: MouseRegion(
                  onEnter: (_) => setState(() => _hoveredNavIndex = idx),
                  onExit: (_) => setState(() => _hoveredNavIndex = -1),
                  child: InkWell(
                    onTap: () => _navigateTo(idx),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: isActive
                            ? LinearGradient(colors: [AppColors.secondary, AppColors.secondaryDark])
                            : isHovered
                                ? LinearGradient(colors: [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.04)])
                                : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            width: isActive ? 24 : isHovered ? 16 : 0,
                            height: 2,
                            decoration: BoxDecoration(
                              color: isActive ? Colors.white : AppColors.secondaryLight,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  BREADCRUMB
  // ═══════════════════════════════════════════
  Widget _buildBreadcrumb(String page, {String? sub}) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(color: AppColors.surface, border: Border(bottom: BorderSide(color: AppColors.divider))),
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: _maxWidth(context)),
          padding: EdgeInsets.symmetric(horizontal: _isMobile(context) ? 16 : 20, vertical: 14),
          child: Row(
            children: [
              InkWell(onTap: () => _navigateTo(0), child: const Icon(Icons.home_outlined, size: 16, color: AppColors.textMuted)),
              _breadcrumbArrow(),
              if (sub != null) ...[
                InkWell(
                  onTap: () {
                    if (page == '공지사항') _navigateTo(2);
                    else if (page == '활동갤러리') _navigateTo(3);
                    else if (page == '보도자료') _navigateTo(4);
                  },
                  child: Text(page, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                ),
                _breadcrumbArrow(),
                Expanded(child: Text(sub, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
              ] else
                Text(page, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _breadcrumbArrow() => const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.chevron_right, size: 16, color: AppColors.textMuted));

  // ═══════════════════════════════════════════
  //  HERO SLIDER
  // ═══════════════════════════════════════════
  Widget _buildHeroSlider() {
    final mobile = _isMobile(context);
    final slide = _heroSlides[_heroSlideIndex];
    final bgColor = Color(int.parse(slide['color']!));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [bgColor.withOpacity(0.12), AppColors.surface, bgColor.withOpacity(0.06)],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Animated background circles
          ...List.generate(3, (i) => Positioned(
            top: (i * 120.0) - 40,
            right: (i * 80.0) - 60 + (_heroSlideIndex * 20.0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeInOut,
              width: 200 + i * 60.0,
              height: 200 + i * 60.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [bgColor.withOpacity(0.06 - i * 0.015), Colors.transparent],
                ),
              ),
            ),
          )),
          Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: _maxWidth(context)),
              padding: EdgeInsets.symmetric(horizontal: mobile ? 20 : 48, vertical: mobile ? 44 : 64),
              child: mobile
                  ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _heroText(mobile, slide, bgColor),
                      const SizedBox(height: 28),
                      _heroIllustration(mobile, bgColor),
                    ])
                  : Row(children: [
                      Expanded(flex: 5, child: _heroText(mobile, slide, bgColor)),
                      const SizedBox(width: 48),
                      Expanded(flex: 5, child: _heroIllustration(mobile, bgColor)),
                    ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroText(bool mobile, Map<String, String> slide, Color bgColor) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(animation),
            child: child,
          ),
        );
      },
      child: Column(
        key: ValueKey(_heroSlideIndex),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(slide['title']!, style: TextStyle(fontSize: mobile ? 30 : 44, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1.25, letterSpacing: -0.5)),
          const SizedBox(height: 18),
          Text(slide['subtitle']!, style: TextStyle(fontSize: mobile ? 14 : 17, color: AppColors.textSecondary, height: 1.7)),
          const SizedBox(height: 28),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _navigateTo(1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: mobile ? 24 : 32, vertical: mobile ? 14 : 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [bgColor, bgColor.withOpacity(0.85)]),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: AppShadows.glow(bgColor),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text('자세히보기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 36),
          Row(children: List.generate(_heroSlides.length, (i) => GestureDetector(
            onTap: () => setState(() => _heroSlideIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.only(right: 10),
              width: i == _heroSlideIndex ? 32 : 10, height: 10,
              decoration: BoxDecoration(
                gradient: i == _heroSlideIndex ? LinearGradient(colors: [bgColor, bgColor.withOpacity(0.7)]) : null,
                color: i == _heroSlideIndex ? null : AppColors.border,
                borderRadius: BorderRadius.circular(5),
                boxShadow: i == _heroSlideIndex ? [BoxShadow(color: bgColor.withOpacity(0.3), blurRadius: 6)] : null,
              ),
            ),
          ))),
        ],
      ),
    );
  }

  Widget _heroIllustration(bool mobile, Color bgColor) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 700),
      transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: ScaleTransition(scale: Tween(begin: 0.92, end: 1.0).animate(anim), child: child)),
      child: Container(
        key: ValueKey(_heroSlideIndex),
        height: mobile ? 220 : 340,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [bgColor.withOpacity(0.08), bgColor.withOpacity(0.03)],
          ),
          border: Border.all(color: bgColor.withOpacity(0.1)),
        ),
        child: Stack(children: [
          Positioned(top: 20, right: 30, child: _animatedCircle(70, bgColor.withOpacity(0.12))),
          Positioned(bottom: 30, left: 20, child: _animatedCircle(45, bgColor.withOpacity(0.1))),
          Positioned(top: 70, left: 60, child: _animatedCircle(28, bgColor.withOpacity(0.15))),
          Positioned(bottom: 60, right: 60, child: _animatedCircle(20, bgColor.withOpacity(0.08))),
          Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: RadialGradient(colors: [bgColor.withOpacity(0.15), bgColor.withOpacity(0.05)]),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _heroSlideIndex == 0 ? Icons.diversity_3 : _heroSlideIndex == 1 ? Icons.school : Icons.volunteer_activism,
                size: mobile ? 52 : 76, color: bgColor,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _heroSlideIndex == 0 ? '함께하는 세상' : _heroSlideIndex == 1 ? '교육의 힘' : '나눔의 가치',
              style: TextStyle(fontSize: mobile ? 15 : 17, fontWeight: FontWeight.w700, color: bgColor, letterSpacing: 0.5),
            ),
          ])),
        ]),
      ),
    );
  }

  Widget _animatedCircle(double size, Color color) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.8, end: 1.0), duration: const Duration(milliseconds: 2000),
    curve: Curves.easeInOut,
    builder: (_, value, child) => Transform.scale(scale: value, child: child),
    child: Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
  );

  // ═══════════════════════════════════════════
  //  QUICK MENU
  // ═══════════════════════════════════════════
  Widget _buildQuickMenu() {
    final mobile = _isMobile(context);
    final items = [
      {'icon': Icons.apartment, 'label': '협회소개', 'color': const Color(0xFF6366F1), 'page': 1},
      {'icon': Icons.campaign, 'label': '공지사항', 'color': const Color(0xFF3B82F6), 'page': 2},
      {'icon': Icons.photo_library, 'label': '활동갤러리', 'color': const Color(0xFF10B981), 'page': 3},
      {'icon': Icons.newspaper, 'label': '보도자료', 'color': const Color(0xFF06B6D4), 'page': 4},
      {'icon': Icons.volunteer_activism, 'label': '후원신청', 'color': const Color(0xFFEF4444), 'page': 5},
      {'icon': Icons.directions, 'label': '오시는 길', 'color': const Color(0xFF78716C), 'url': 'https://map.naver.com'},
      {'icon': Icons.rss_feed, 'label': '블로그', 'color': const Color(0xFF03C75A), 'url': 'https://blog.naver.com/icaofd'},
      {'icon': Icons.public, 'label': '국세청', 'color': const Color(0xFF059669), 'url': 'https://www.nts.go.kr/'},
    ];

    return Container(
      color: AppColors.surface,
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: _maxWidth(context)),
          padding: EdgeInsets.symmetric(horizontal: mobile ? 16 : 20, vertical: mobile ? 20 : 36),
          child: Container(
            padding: EdgeInsets.all(mobile ? 12 : 28),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppShadows.medium,
            ),
            child: GridView.builder(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: mobile ? 4 : 8, childAspectRatio: mobile ? 0.85 : 0.95, crossAxisSpacing: 8, mainAxisSpacing: 8),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isHovered = _hoveredQuickMenuIndex == index;
                return MouseRegion(
                  onEnter: (_) => setState(() => _hoveredQuickMenuIndex = index),
                  onExit: (_) => setState(() => _hoveredQuickMenuIndex = -1),
                  child: GestureDetector(
                    onTap: () { if (item.containsKey('url')) html.window.open(item['url'] as String, '_blank'); else _navigateTo(item['page'] as int); },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      transform: Matrix4.identity()..scale(isHovered ? 1.08 : 1.0),
                      transformAlignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isHovered ? (item['color'] as Color).withOpacity(0.08) : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: EdgeInsets.all(mobile ? 10 : 14),
                          decoration: BoxDecoration(
                            gradient: isHovered
                                ? LinearGradient(colors: [(item['color'] as Color).withOpacity(0.2), (item['color'] as Color).withOpacity(0.1)])
                                : null,
                            color: isHovered ? null : (item['color'] as Color).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: isHovered ? AppShadows.glow(item['color'] as Color) : null,
                          ),
                          child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: mobile ? 22 : 28),
                        ),
                        SizedBox(height: mobile ? 6 : 10),
                        Text(item['label'] as String, style: TextStyle(fontSize: mobile ? 11 : 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary), textAlign: TextAlign.center),
                      ]),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  NEWS + GALLERY (side by side on desktop)
  // ═══════════════════════════════════════════
  Widget _buildNewsAndGallerySection() {
    final mobile = _isMobile(context);
    return Container(
      color: AppColors.background,
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: _maxWidth(context)),
          padding: EdgeInsets.symmetric(horizontal: mobile ? 16 : 20, vertical: mobile ? 24 : 44),
          child: mobile
              ? Column(children: [_buildNoticeCard(), const SizedBox(height: 24), _buildGalleryHomeCard()])
              : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: _buildNoticeCard()),
                  const SizedBox(width: 24),
                  Expanded(child: _buildGalleryHomeCard()),
                ]),
        ),
      ),
    );
  }

  Widget _buildNoticeCard() {
    final tabs = ['전체', '공지', '교육', '행사'];
    final filtered = _selectedNoticeTab == '전체' ? _notices.take(6).toList() : _notices.where((n) => n.category == _selectedNoticeTab).take(6).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface, borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.soft,
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.secondary, AppColors.secondaryDark]), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.campaign, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text('공지사항', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const Spacer(),
            InkWell(onTap: () => _navigateTo(2), child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.add, size: 18, color: AppColors.textMuted),
            )),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(children: tabs.map((tab) {
            final isActive = _selectedNoticeTab == tab;
            return Padding(padding: const EdgeInsets.only(right: 6), child: InkWell(
              onTap: () => setState(() => _selectedNoticeTab = tab),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  gradient: isActive ? LinearGradient(colors: [AppColors.secondary, AppColors.secondaryDark]) : null,
                  color: isActive ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isActive ? Colors.transparent : AppColors.border),
                ),
                child: Text(tab, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isActive ? Colors.white : AppColors.textMuted)),
              ),
            ));
          }).toList()),
        ),
        ...filtered.map((notice) => InkWell(
          onTap: () => setState(() { _selectedNotice = notice; _currentPage = 6; }),
          hoverColor: AppColors.secondary.withOpacity(0.04),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
            child: Row(children: [
              Expanded(child: Row(children: [
                Flexible(child: Text(notice.title, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis)),
                if (notice.isNew) ...[const SizedBox(width: 6), _newBadge()],
              ])),
              Text(notice.createdAt.toString().split(' ')[0], style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ]),
          ),
        )),
        if (filtered.isEmpty)
          const Padding(padding: EdgeInsets.all(24), child: Text('등록된 공지사항이 없습니다.', style: TextStyle(color: AppColors.textMuted, fontSize: 13))),
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _buildGalleryHomeCard() {
    final items = _galleryItems.take(4).toList();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface, borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.soft,
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.accentWarm, AppColors.accentWarm.withOpacity(0.7)]), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.photo_library, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text('활동갤러리', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const Spacer(),
            InkWell(onTap: () => _navigateTo(3), child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.add, size: 18, color: AppColors.textMuted),
            )),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: items.isEmpty
              ? const Padding(padding: EdgeInsets.all(24), child: Text('등록된 갤러리가 없습니다.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)))
              : GridView.builder(
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.4, crossAxisSpacing: 8, mainAxisSpacing: 8),
                  itemCount: items.length,
                  itemBuilder: (context, idx) {
                    final item = items[idx];
                    return HoverScaleCard(
                      onTap: () => setState(() { _selectedGallery = item; _currentPage = 7; }),
                      borderRadius: BorderRadius.circular(10),
                      child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Stack(fit: StackFit.expand, children: [
                        item.imageUrls.isNotEmpty
                            ? Image.network(item.imageUrls.first, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _imgPlaceholder())
                            : _imgPlaceholder(),
                        Positioned(bottom: 0, left: 0, right: 0, child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.7)])),
                          child: Text(item.title, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                        )),
                      ])),
                    );
                  },
                ),
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════════
  //  STATS SECTION
  // ═══════════════════════════════════════════
  Widget _buildStatsSection() {
    final mobile = _isMobile(context);
    final stats = [
      {'icon': Icons.people_alt_outlined, 'value': '500+', 'label': '교육 수혜자', 'color': AppColors.secondary},
      {'icon': Icons.school_outlined, 'value': '15+', 'label': '운영 프로그램', 'color': AppColors.accent},
      {'icon': Icons.calendar_month_outlined, 'value': '14', 'label': '설립 연수(년)', 'color': AppColors.info},
      {'icon': Icons.handshake_outlined, 'value': '100+', 'label': '협력 기관', 'color': AppColors.accentWarm},
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
      ),
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: _maxWidth(context)),
          padding: EdgeInsets.symmetric(horizontal: mobile ? 20 : 40, vertical: mobile ? 32 : 52),
          child: Column(
            children: [
              Text('함께한 발자취', style: TextStyle(color: Colors.white, fontSize: mobile ? 22 : 28, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              const SizedBox(height: 8),
              Text('인천장애인능력개발협회의 성과', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
              SizedBox(height: mobile ? 28 : 40),
              Wrap(
                spacing: mobile ? 16 : 32,
                runSpacing: mobile ? 16 : 32,
                alignment: WrapAlignment.center,
                children: stats.map((stat) {
                  final color = stat['color'] as Color;
                  return SizedBox(
                    width: mobile ? (MediaQuery.of(context).size.width - 56) / 2 : 220,
                    child: Container(
                      padding: EdgeInsets.all(mobile ? 16 : 24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Column(children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(stat['icon'] as IconData, color: color, size: mobile ? 24 : 28),
                        ),
                        SizedBox(height: mobile ? 10 : 14),
                        Text(stat['value'] as String, style: TextStyle(color: Colors.white, fontSize: mobile ? 26 : 34, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(stat['label'] as String, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: mobile ? 12 : 14)),
                      ]),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  VIDEO SECTION
  // ═══════════════════════════════════════════
  Widget _buildVideoSection() {
    final mobile = _isMobile(context);
    return Container(
      color: AppColors.surface,
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: _maxWidth(context)),
          padding: EdgeInsets.symmetric(horizontal: mobile ? 16 : 20, vertical: mobile ? 24 : 44),
          child: Column(children: [
            _sectionTitle('협회 소개 영상'),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppShadows.medium,
              ),
              child: ClipRRect(borderRadius: BorderRadius.circular(16), child: AspectRatio(aspectRatio: 16 / 9, child: YoutubePlayer(controller: _youtubeController))),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(children: [
      Container(width: 4, height: 24, decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.secondary, AppColors.secondaryDark]),
        borderRadius: BorderRadius.circular(2),
      )),
      const SizedBox(width: 12),
      Text(title, style: TextStyle(fontSize: _isMobile(context) ? 18 : 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
    ]);
  }

  // ═══════════════════════════════════════════
  //  PAGE HELPERS
  // ═══════════════════════════════════════════
  Widget _pageTitle(String title) {
    return Container(
      padding: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.primary, width: 2))),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(
          gradient: LinearGradient(colors: [AppColors.secondary, AppColors.secondaryDark]),
          borderRadius: BorderRadius.circular(10),
          boxShadow: AppShadows.glow(AppColors.secondary),
        ), child: const Icon(Icons.article, color: Colors.white, size: 20)),
        const SizedBox(width: 14),
        Text(title, style: TextStyle(fontSize: _isMobile(context) ? 22 : 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
      ]),
    );
  }

  Widget _buildContentCard(String title, Widget content) {
    return Container(
      width: double.infinity, padding: EdgeInsets.all(_isMobile(context) ? 16 : 28),
      decoration: _cardDeco(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 4, height: 20, decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.secondary, AppColors.secondaryDark]),
            borderRadius: BorderRadius.circular(2),
          )),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
        ]),
        const SizedBox(height: 20),
        content,
      ]),
    );
  }

  BoxDecoration _cardDeco() => BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.soft);
  Widget _newBadge() => Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.error, AppColors.error.withOpacity(0.8)]), borderRadius: BorderRadius.circular(4)), child: const Text('N', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)));
  Widget _categoryBadge(String c) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: _getCategoryColor(c).withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Text(c, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _getCategoryColor(c)), textAlign: TextAlign.center));

  Color _getCategoryColor(String c) {
    switch (c) { case '공지': return AppColors.categoryNotice; case '교육': return AppColors.categoryEducation; case '행사': return AppColors.categoryEvent; default: return AppColors.textMuted; }
  }

  Widget _backButton(int page) => InkWell(
    onTap: () => _navigateTo(page),
    borderRadius: BorderRadius.circular(8),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: AppColors.secondary.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: const [Icon(Icons.arrow_back_rounded, size: 18, color: AppColors.secondary), SizedBox(width: 6), Text('목록으로', style: TextStyle(color: AppColors.secondary, fontSize: 14, fontWeight: FontWeight.w600))]),
    ),
  );

  Widget _metaRow(String author, DateTime date, int? views) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.divider), bottom: BorderSide(color: AppColors.divider))),
      child: Wrap(spacing: 16, runSpacing: 4, children: [
        Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.person_outline, size: 15, color: AppColors.textMuted), const SizedBox(width: 4), Text(author, style: const TextStyle(fontSize: 13, color: AppColors.textMuted))]),
        Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textMuted), const SizedBox(width: 4), Text(date.toString().split(' ')[0], style: const TextStyle(fontSize: 13, color: AppColors.textMuted))]),
        if (views != null) Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.visibility_outlined, size: 15, color: AppColors.textMuted), const SizedBox(width: 4), Text('$views', style: const TextStyle(fontSize: 13, color: AppColors.textMuted))]),
      ]),
    );
  }

  Widget _fileItem(String url, String name) {
    return InkWell(onTap: () => html.window.open(url, '_blank'), child: Container(margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
      child: Row(children: [Icon(_getFileIcon(name.split('.').last), size: 18, color: AppColors.secondary), const SizedBox(width: 8), Expanded(child: Text(name, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))), const Icon(Icons.download_rounded, size: 16, color: AppColors.secondary)])));
  }

  Widget _imgPlaceholder({double? height}) => Container(height: height, color: AppColors.background, child: const Center(child: Icon(Icons.image, color: AppColors.textMuted, size: 40)));

  bool _isImageUrl(String url) => RegExp(r'\.(jpg|jpeg|png|gif|webp)(\?.*)?$', caseSensitive: false).hasMatch(url);

  Widget _buildRichContent(String content, {List<String>? imageUrls}) {
    final urlRegex = RegExp(r'https?://[^\s\)]+');
    final lines = content.split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Inline images from fileUrls
        if (imageUrls != null) ...imageUrls.where(_isImageUrl).map((url) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(url, fit: BoxFit.cover, width: double.infinity,
              errorBuilder: (_, __, ___) => _imgPlaceholder(height: 200)),
          ),
        )),
        // Content with clickable links
        ...lines.map((line) {
          if (line.trim().isEmpty) return const SizedBox(height: 12);
          final matches = urlRegex.allMatches(line).toList();
          if (matches.isEmpty) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(line, style: const TextStyle(fontSize: 15, height: 1.8, color: AppColors.textSecondary)),
            );
          }
          // Build line with clickable links
          final spans = <TextSpan>[];
          int lastEnd = 0;
          for (final match in matches) {
            if (match.start > lastEnd) {
              spans.add(TextSpan(text: line.substring(lastEnd, match.start)));
            }
            final url = match.group(0)!;
            spans.add(TextSpan(
              text: url,
              style: const TextStyle(color: AppColors.info, decoration: TextDecoration.underline, decorationColor: AppColors.info),
              recognizer: TapGestureRecognizer()..onTap = () => html.window.open(url, '_blank'),
            ));
            lastEnd = match.end;
          }
          if (lastEnd < line.length) {
            spans.add(TextSpan(text: line.substring(lastEnd)));
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: SelectableText.rich(TextSpan(style: const TextStyle(fontSize: 15, height: 1.8, color: AppColors.textSecondary, fontFamily: 'Pretendard'), children: spans)),
          );
        }),
      ],
    );
  }

  // ═══════════════════════════════════════════
  //  ABOUT PAGE
  // ═══════════════════════════════════════════
  Widget _buildAboutPage() {
    final mobile = _isMobile(context);
    return Center(child: Container(constraints: BoxConstraints(maxWidth: _maxWidth(context)), padding: EdgeInsets.all(mobile ? 16 : 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _pageTitle('법인 소개'),
        const SizedBox(height: 28),
        Container(width: double.infinity, decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.medium),
          child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.asset('assets/images/EXPO.jpg', fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 300, color: AppColors.background, child: const Center(child: Icon(Icons.image_not_supported, size: 48, color: AppColors.textMuted)))))),
        const SizedBox(height: 32),
        _buildContentCard('1. 법인 설립목적 및 연혁', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('본 협회는 불우하고 소외된 이웃과 장애인들의 복지를 위하여 아가페적인 사랑을 밑거름으로\n돌봄, 재활, 교육개선 및 선진 복지를 실천함을 목적으로 한다.', style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.7)),
          const SizedBox(height: 20),
          _buildHistoryTable(),
        ])),
        const SizedBox(height: 20),
        _buildContentCard('2. 조직 및 인력현황', _buildOrgChart()),
        const SizedBox(height: 20),
        _buildContentCard('3. 주요사업', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildBizGroup('교육사업', [
            _buildBizItem('성인장애인 평생교육원 "꿈 땅"', '학업의 기회를 놓친 성인 장애인을 위한 맞춤교육 제공\n특화교육활동을 통한 여가·취미활동 및 직업재활 능력 강화\n일정: 매회 3월~12월 / 장소: 인천 중구 진성빌딩 2F'),
            _buildBizItem('교육바우쳐', '장애인 직업훈련 및 평생교육을 위한 바우쳐 사업\n학습자가 자율적으로 학습\n일정: 매회 3월~12월 / 장소: 인천 중구 신포로 진성빌딩 2,3F'),
          ]),
          const SizedBox(height: 16),
          _buildBizGroup('특화사업', [
            _buildBizItem('직업현장훈련', '장애영역에 맞는 직종 개발과 직업재활 훈련\n일정: 주5회 (월~토 오전9시~오후3시)\n내용: 바리스타, 체험강사, 문화해설사, 마사지 서비스'),
            _buildBizItem('캠프', '창의적 체육 프로그램으로 건강한 삶 향유\n일정: 주2회 (매주 화, 목)\n내용: 농구교실, 무예댄스, 스트레칭 교실'),
          ]),
        ])),
      ])));
  }

  Widget _buildHistoryTable() {
    final h = [['2010', '법인설립 / 장애인엑스포 직업체험 참여'], ['2011~2012', '미국 하와이 장애인 엑스포 참가'], ['2013~2015', '장애인 직업재활 훈련 사업 확대'], ['2016~2018', '장애인 인재개발센터 설립 및 운영'], ['2019~현재', '평생교육원, 교육바우쳐, 직업현장훈련 운영']];
    return ClipRRect(borderRadius: BorderRadius.circular(10), child: Table(border: TableBorder.all(color: AppColors.border), columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(3)}, children: [
      TableRow(decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryLight])), children: ['연도', '주요내용'].map((t) => Padding(padding: const EdgeInsets.all(12), child: Text(t, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center))).toList()),
      ...h.asMap().entries.map((e) => TableRow(decoration: BoxDecoration(color: e.key.isEven ? AppColors.surface : AppColors.background), children: [
        Padding(padding: const EdgeInsets.all(12), child: Text(e.value[0], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
        Padding(padding: const EdgeInsets.all(12), child: Text(e.value[1], style: const TextStyle(fontSize: 14, color: AppColors.textSecondary))),
      ])),
    ]));
  }

  Widget _buildOrgChart() => ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.asset('assets/images/orgchart.png', fit: BoxFit.contain, errorBuilder: (_, __, ___) => Container(height: 200, color: AppColors.background, child: const Center(child: Text('조직도', style: TextStyle(color: AppColors.textMuted))))));
  Widget _buildBizGroup(String title, List<Widget> items) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.secondary, AppColors.secondaryDark]), borderRadius: BorderRadius.circular(8)), child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14))),
    const SizedBox(height: 12), ...items]);
  Widget _buildBizItem(String title, String desc) => Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)), const SizedBox(height: 8), Text(desc, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6))]));

  // ═══════════════════════════════════════════
  //  NOTICE PAGE
  // ═══════════════════════════════════════════
  Widget _buildNoticePage() {
    final mobile = _isMobile(context);
    return Center(child: Container(constraints: BoxConstraints(maxWidth: _maxWidth(context)), padding: EdgeInsets.all(mobile ? 16 : 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _pageTitle('공지사항'),
          Row(children: [
            if (_isAdmin) ElevatedButton.icon(onPressed: _showWriteNoticeDialog, icon: const Icon(Icons.edit, size: 16), label: const Text('글쓰기'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12))),
            const SizedBox(width: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
              child: Text('전체 ${_notices.length}건', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
          ]),
        ]),
        const SizedBox(height: 24),
        Container(decoration: _cardDeco(), child: Column(children: [
          if (!mobile) Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]), borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
            child: const Row(children: [SizedBox(width: 50, child: Text('번호', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))), SizedBox(width: 20), SizedBox(width: 60, child: Text('분류', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))), SizedBox(width: 20), Expanded(child: Text('제목', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))), SizedBox(width: 80, child: Text('작성자', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))), SizedBox(width: 20), SizedBox(width: 90, child: Text('작성일', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))), SizedBox(width: 20), SizedBox(width: 60, child: Text('조회', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)))])),
          ..._notices.asMap().entries.map((e) {
            final i = e.key; final n = e.value;
            return InkWell(onTap: () => setState(() { _selectedNotice = n; _currentPage = 6; }),
              hoverColor: AppColors.secondary.withOpacity(0.04),
              child: Container(padding: EdgeInsets.symmetric(horizontal: mobile ? 16 : 24, vertical: mobile ? 12 : 14), decoration: BoxDecoration(color: i.isEven ? AppColors.surface : AppColors.background, border: const Border(bottom: BorderSide(color: AppColors.divider))),
                child: mobile
                  ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [_categoryBadge(n.category), if (n.isNew) ...[const SizedBox(width: 6), _newBadge()], const Spacer(), Text(n.createdAt.toString().split(' ')[0], style: const TextStyle(fontSize: 11, color: AppColors.textMuted))]), const SizedBox(height: 6), Text(n.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)])
                  : Row(children: [SizedBox(width: 50, child: Text('${_notices.length - i}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.textMuted))), const SizedBox(width: 20), SizedBox(width: 60, child: _categoryBadge(n.category)), const SizedBox(width: 20), Expanded(child: Row(children: [Flexible(child: Text(n.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis)), if (n.isNew) ...[const SizedBox(width: 6), _newBadge()]])), SizedBox(width: 80, child: Text(n.author, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.textMuted))), const SizedBox(width: 20), SizedBox(width: 90, child: Text(n.createdAt.toString().split(' ')[0], textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.textMuted))), const SizedBox(width: 20), SizedBox(width: 60, child: Text(n.views.toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)))])));
          }),
        ])),
      ])));
  }

  // ═══════════════════════════════════════════
  //  DETAIL PAGES
  // ═══════════════════════════════════════════
  Widget _buildNoticeDetailPage() {
    if (_selectedNotice == null) return const SizedBox();
    final m = _isMobile(context); final n = _selectedNotice!;
    return Center(child: Container(constraints: BoxConstraints(maxWidth: _maxWidth(context)), padding: EdgeInsets.all(m ? 16 : 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _backButton(2), const SizedBox(height: 16),
        Container(width: double.infinity, padding: EdgeInsets.all(m ? 16 : 28), decoration: _cardDeco(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _categoryBadge(n.category), const SizedBox(height: 12),
          Text(n.title, style: TextStyle(fontSize: m ? 20 : 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 16), _metaRow(n.author, n.createdAt, n.views), const SizedBox(height: 24),
          _buildRichContent(n.content, imageUrls: n.fileUrls),
          if (n.fileUrls.where((u) => !_isImageUrl(u)).isNotEmpty) ...[const SizedBox(height: 32), const Divider(), const SizedBox(height: 12), const Text('첨부파일', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)), const SizedBox(height: 8),
            ...n.fileUrls.asMap().entries.where((e) => !_isImageUrl(e.value)).map((e) => _fileItem(e.value, n.fileNames.length > e.key ? n.fileNames[e.key] : '파일 ${e.key + 1}'))],
        ])),
        if (_isAdmin) ...[const SizedBox(height: 12), Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: () => _deleteItem('notices', n.id, () { _navigateTo(2); _loadNotices(); }), icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error), label: const Text('삭제', style: TextStyle(color: AppColors.error))))],
      ])));
  }

  Widget _buildActivityGalleryPage() {
    final m = _isMobile(context);
    return Center(child: Container(constraints: BoxConstraints(maxWidth: _maxWidth(context)), padding: EdgeInsets.all(m ? 16 : 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _pageTitle('활동갤러리'),
          if (_isAdmin) ElevatedButton.icon(onPressed: _showWriteGalleryDialog, icon: const Icon(Icons.add_photo_alternate, size: 16), label: const Text('등록'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12))),
        ]),
        const SizedBox(height: 24),
        _galleryItems.isEmpty
            ? const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('등록된 갤러리가 없습니다.', style: TextStyle(color: AppColors.textMuted))))
            : GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: m ? 2 : 3, childAspectRatio: 0.85, crossAxisSpacing: 12, mainAxisSpacing: 12),
                itemCount: _galleryItems.length,
                itemBuilder: (context, idx) { final item = _galleryItems[idx];
                  return HoverScaleCard(
                    onTap: () => setState(() { _selectedGallery = item; _currentPage = 7; }),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), boxShadow: AppShadows.soft),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Expanded(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(14)), child: item.imageUrls.isNotEmpty ? Image.network(item.imageUrls.first, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _imgPlaceholder()) : _imgPlaceholder())),
                        Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(item.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4), Text(item.createdAt.toString().split(' ')[0], style: const TextStyle(fontSize: 11, color: AppColors.textMuted))])),
                      ])));
                }),
      ])));
  }

  Widget _buildGalleryDetailPage() {
    if (_selectedGallery == null) return const SizedBox();
    final m = _isMobile(context); final g = _selectedGallery!;
    return Center(child: Container(constraints: BoxConstraints(maxWidth: _maxWidth(context)), padding: EdgeInsets.all(m ? 16 : 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _backButton(3), const SizedBox(height: 16),
        Container(width: double.infinity, padding: EdgeInsets.all(m ? 16 : 28), decoration: _cardDeco(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(g.title, style: TextStyle(fontSize: m ? 20 : 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 12), _metaRow(g.author, g.createdAt, null),
          if (g.description != null && g.description!.isNotEmpty) ...[const SizedBox(height: 20), Text(g.description!, style: const TextStyle(fontSize: 15, height: 1.7, color: AppColors.textSecondary))],
          const SizedBox(height: 20),
          ...g.imageUrls.map((url) => Padding(padding: const EdgeInsets.only(bottom: 12), child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(url, fit: BoxFit.cover, width: double.infinity, errorBuilder: (_, __, ___) => _imgPlaceholder(height: 200))))),
        ])),
        if (_isAdmin) ...[const SizedBox(height: 12), Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: () => _deleteItem('gallery', g.id, () { _navigateTo(3); _loadGallery(); }), icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error), label: const Text('삭제', style: TextStyle(color: AppColors.error))))],
      ])));
  }

  Widget _buildPressReleasePage() {
    final m = _isMobile(context);
    return Center(child: Container(constraints: BoxConstraints(maxWidth: _maxWidth(context)), padding: EdgeInsets.all(m ? 16 : 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _pageTitle('보도자료'),
          if (_isAdmin) ElevatedButton.icon(onPressed: _showWritePressReleaseDialog, icon: const Icon(Icons.edit, size: 16), label: const Text('글쓰기'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12))),
        ]),
        const SizedBox(height: 24),
        Container(decoration: _cardDeco(), child: _pressReleases.isEmpty
            ? const Padding(padding: EdgeInsets.all(40), child: Center(child: Text('등록된 보도자료가 없습니다.', style: TextStyle(color: AppColors.textMuted))))
            : Column(children: _pressReleases.asMap().entries.map((e) {
                final i = e.key; final pr = e.value;
                return InkWell(onTap: () => setState(() { _selectedPressRelease = pr; _currentPage = 8; }),
                  hoverColor: AppColors.secondary.withOpacity(0.04),
                  child: Container(padding: EdgeInsets.symmetric(horizontal: m ? 16 : 24, vertical: 14), decoration: BoxDecoration(border: i < _pressReleases.length - 1 ? const Border(bottom: BorderSide(color: AppColors.divider)) : null),
                    child: Row(children: [SizedBox(width: 40, child: Text('${_pressReleases.length - i}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.textMuted))), const SizedBox(width: 16), Expanded(child: Text(pr.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis)), if (!m) Text(pr.createdAt.toString().split(' ')[0], style: const TextStyle(fontSize: 13, color: AppColors.textMuted))])));
              }).toList())),
      ])));
  }

  Widget _buildPressReleaseDetailPage() {
    if (_selectedPressRelease == null) return const SizedBox();
    final m = _isMobile(context); final pr = _selectedPressRelease!;
    return Center(child: Container(constraints: BoxConstraints(maxWidth: _maxWidth(context)), padding: EdgeInsets.all(m ? 16 : 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _backButton(4), const SizedBox(height: 16),
        Container(width: double.infinity, padding: EdgeInsets.all(m ? 16 : 28), decoration: _cardDeco(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(pr.title, style: TextStyle(fontSize: m ? 20 : 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 12), _metaRow(pr.author, pr.createdAt, null), const SizedBox(height: 24),
          _buildRichContent(pr.content, imageUrls: pr.fileUrls),
          if (pr.fileUrls.where((u) => !_isImageUrl(u)).isNotEmpty) ...[const SizedBox(height: 32), const Divider(), const SizedBox(height: 12), const Text('첨부파일', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)), const SizedBox(height: 8),
            ...pr.fileUrls.asMap().entries.where((e) => !_isImageUrl(e.value)).map((e) => _fileItem(e.value, pr.fileNames.length > e.key ? pr.fileNames[e.key] : '파일 ${e.key + 1}'))],
        ])),
        if (_isAdmin) ...[const SizedBox(height: 12), Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: () => _deleteItem('press_releases', pr.id, () { setState(() { _currentPage = 4; _selectedPressRelease = null; }); _loadPressReleases(); }), icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error), label: const Text('삭제', style: TextStyle(color: AppColors.error))))],
      ])));
  }

  Widget _buildDonationPage() {
    return Center(child: Container(constraints: BoxConstraints(maxWidth: _maxWidth(context)), padding: EdgeInsets.all(_isMobile(context) ? 16 : 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _pageTitle('후원하기'), const SizedBox(height: 28),
        _buildContentCard('후원 안내', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.secondary.withOpacity(0.08), AppColors.secondary.withOpacity(0.03)]),
            borderRadius: BorderRadius.circular(14)),
            child: Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.secondary, AppColors.secondaryDark]), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.volunteer_activism, size: 28, color: Colors.white)), const SizedBox(width: 16),
              const Expanded(child: Text('(사)인천장애인능력개발협회에 보내주시는 후원금은\n장애인의 교육과 직업재활을 위해 소중하게 사용됩니다.', style: TextStyle(fontSize: 15, height: 1.6, color: AppColors.textSecondary)))])),
          const SizedBox(height: 20),
          const Text('후원 안내 정보를 준비 중입니다.', style: TextStyle(fontSize: 15, color: AppColors.textMuted)),
        ])),
      ])));
  }

  // ═══════════════════════════════════════════
  //  FOOTER
  // ═══════════════════════════════════════════
  Widget _buildFooter() {
    final m = _isMobile(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      child: Column(children: [
        Container(decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08)))),
          child: Center(child: Container(constraints: BoxConstraints(maxWidth: _maxWidth(context)), padding: EdgeInsets.symmetric(horizontal: m ? 16 : 20, vertical: 12),
            child: Wrap(spacing: m ? 16 : 28, runSpacing: 8, children: ['개인정보처리방침', '이용약관', '오시는 길', '사이트맵'].map((t) =>
              InkWell(onTap: () {}, child: Text(t, style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13, fontWeight: t == '개인정보처리방침' ? FontWeight.bold : FontWeight.normal)))).toList())))),
        Center(child: Container(constraints: BoxConstraints(maxWidth: _maxWidth(context)), padding: EdgeInsets.symmetric(horizontal: m ? 16 : 20, vertical: 28),
          child: m
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [Image.asset('assets/images/logo.png', height: 32, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const SizedBox()), const SizedBox(width: 10), const Text('인천장애인능력개발협회', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold))]),
                  const SizedBox(height: 16),
                  Text('주소 : 인천 중구 월미문화로 95 3층', style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13, height: 1.7)),
                  Text('Tel : 010-9114-5923', style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13, height: 1.7)),
                  const SizedBox(height: 16),
                  _socialRow(),
                ])
              : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [Image.asset('assets/images/logo.png', height: 36, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const SizedBox()), const SizedBox(width: 12), const Text('(사)인천장애인능력개발협회', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))]),
                    const SizedBox(height: 16),
                    Text('주소 : 인천 중구 월미문화로 95 3층', style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13, height: 1.7)),
                    Text('Tel : 010-9114-5923', style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13, height: 1.7)),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    _socialRow(),
                    const SizedBox(height: 16),
                    Wrap(spacing: 16, children: ['협회소개', '공지사항', '활동갤러리', '보도자료', '후원하기'].asMap().entries.map((e) => InkWell(onTap: () => _navigateTo(e.key + 1), child: Text(e.value, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)))).toList()),
                  ]),
                ]))),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.black.withOpacity(0.2), Colors.black.withOpacity(0.3)]),
          ),
          padding: EdgeInsets.symmetric(horizontal: m ? 16 : 20, vertical: 14),
          child: Center(child: Text('Copyright (c) (사)인천장애인능력개발협회. All rights reserved.', style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 12), textAlign: TextAlign.center)),
        ),
      ]),
    );
  }

  Widget _socialRow() {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      _socialBtn(Icons.language, 'Blog', () => html.window.open('https://blog.naver.com/icaofd', '_blank')),
    ]);
  }

  Widget _socialBtn(IconData icon, String label, VoidCallback onTap) {
    return Tooltip(message: label, child: InkWell(onTap: onTap, child: Container(margin: const EdgeInsets.only(left: 8), padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.15)),
        gradient: LinearGradient(colors: [Colors.white.withOpacity(0.06), Colors.white.withOpacity(0.02)])),
      child: Icon(icon, color: Colors.white.withOpacity(0.75), size: 18))));
  }

  // ═══════════════════════════════════════════
  //  DELETE HELPER
  // ═══════════════════════════════════════════
  Future<void> _deleteItem(String table, String id, VoidCallback onSuccess) async {
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('삭제 확인'), content: const Text('정말 삭제하시겠습니까?'), actions: [
      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
      TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: AppColors.error), child: const Text('삭제')),
    ]));
    if (confirmed == true) {
      try {
        await supabase.from(table).delete().eq('id', id);
        if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('삭제되었습니다.'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))); onSuccess(); }
      } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('삭제 실패: $e'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))); }
    }
  }

  // ═══════════════════════════════════════════
  //  DIALOGS
  // ═══════════════════════════════════════════
  void _showLoginDialog() {
    final ec = TextEditingController(); final pc = TextEditingController(); bool loading = false;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, ss) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(width: 400, padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.secondary, AppColors.secondaryDark]), shape: BoxShape.circle, boxShadow: AppShadows.glow(AppColors.secondary)), child: const Icon(Icons.lock, color: Colors.white, size: 28)),
        const SizedBox(height: 20), const Text('로그인', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)), const SizedBox(height: 24),
        _dlgField(ec, '이메일', Icons.email, false), const SizedBox(height: 12),
        _dlgField(pc, '비밀번호', Icons.lock, true, onSubmit: () async { await _handleLogin(ec.text, pc.text, ctx, ss, (v) { loading = v; }); }),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Text('계정이 없으신가요? ', style: TextStyle(fontSize: 13, color: AppColors.textMuted)), TextButton(onPressed: () { Navigator.of(ctx).pop(); _showSignupDialog(); }, child: const Text('회원가입', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.secondary)))]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.of(ctx).pop(), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), side: const BorderSide(color: AppColors.border)), child: const Text('취소', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600)))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(onPressed: loading ? null : () async { await _handleLogin(ec.text, pc.text, ctx, ss, (v) { ss(() { loading = v; }); }); },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
            child: loading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('로그인', style: TextStyle(fontWeight: FontWeight.w700)))),
        ]),
      ])))));
  }

  void _showSignupDialog() {
    final ec = TextEditingController(); final pc = TextEditingController(); final cc = TextEditingController(); bool loading = false;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, ss) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(width: 400, padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.secondary, AppColors.secondaryDark]), shape: BoxShape.circle, boxShadow: AppShadows.glow(AppColors.secondary)), child: const Icon(Icons.person_add, color: Colors.white, size: 28)),
        const SizedBox(height: 20), const Text('회원가입', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)), const SizedBox(height: 24),
        _dlgField(ec, '이메일', Icons.email, false), const SizedBox(height: 12),
        _dlgField(pc, '비밀번호 (최소 6자)', Icons.lock, true), const SizedBox(height: 12),
        _dlgField(cc, '비밀번호 확인', Icons.lock_outline, true),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Text('이미 계정이 있으신가요? ', style: TextStyle(fontSize: 13, color: AppColors.textMuted)), TextButton(onPressed: () { Navigator.of(ctx).pop(); _showLoginDialog(); }, child: const Text('로그인', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.secondary)))]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.of(ctx).pop(), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), side: const BorderSide(color: AppColors.border)), child: const Text('취소', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600)))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(onPressed: loading ? null : () async { await _handleSignup(ec.text, pc.text, cc.text, ctx, ss, (v) { ss(() { loading = v; }); }); },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
            child: loading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('가입하기', style: TextStyle(fontWeight: FontWeight.w700)))),
        ]),
      ])))));
  }

  void _showWriteNoticeDialog() {
    final tc = TextEditingController(); final cc = TextEditingController(); final nc = TextEditingController(text: '관리자');
    String cat = '공지'; List<PlatformFile> files = [];
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, ss) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(width: 540, padding: const EdgeInsets.all(32), child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.secondary, AppColors.secondaryDark]), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.edit, color: Colors.white, size: 20)), const SizedBox(width: 12), const Text('공지사항 작성', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800))]),
        const SizedBox(height: 24),
        const Text('분류', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)), const SizedBox(height: 8),
        Row(children: ['공지', '교육', '행사'].map((c) { final sel = c == cat; return Padding(padding: const EdgeInsets.only(right: 8), child: InkWell(onTap: () => ss(() => cat = c), child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: sel ? _getCategoryColor(c) : _getCategoryColor(c).withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: _getCategoryColor(c))), child: Text(c, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: sel ? Colors.white : _getCategoryColor(c)))))); }).toList()),
        const SizedBox(height: 16), _dlgField(nc, '작성자 닉네임', Icons.person, false), const SizedBox(height: 12), _dlgField(tc, '제목', Icons.title, false), const SizedBox(height: 12),
        TextField(controller: cc, maxLines: 8, decoration: InputDecoration(labelText: '내용', alignLabelWithHint: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.secondary, width: 2)))),
        const SizedBox(height: 16),
        Row(children: [const Text('파일 첨부', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)), const SizedBox(width: 6), Text('(최대 5개)', style: TextStyle(fontSize: 11, color: AppColors.textMuted))]),
        const SizedBox(height: 8),
        InkWell(onTap: () async { final r = await FilePicker.platform.pickFiles(allowMultiple: true, type: FileType.any); if (r != null) ss(() { if (files.length + r.files.length <= 5) files.addAll(r.files); }); },
          child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.cloud_upload_outlined, color: AppColors.secondary, size: 20), SizedBox(width: 8), Text('파일 선택', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.secondary))]))),
        ...files.asMap().entries.map((e) => Container(margin: const EdgeInsets.only(top: 4), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
          child: Row(children: [Icon(_getFileIcon(e.value.extension ?? ''), size: 16, color: AppColors.secondary), const SizedBox(width: 6), Expanded(child: Text(e.value.name, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)), Text(_formatFileSize(e.value.size), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)), const SizedBox(width: 6), InkWell(onTap: () => ss(() => files.removeAt(e.key)), child: const Icon(Icons.close, size: 16, color: AppColors.error))]))),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.of(ctx).pop(), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), side: const BorderSide(color: AppColors.border)), child: const Text('취소', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600)))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(onPressed: () async {
            if (tc.text.isEmpty || cc.text.isEmpty) { ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('제목과 내용을 입력해주세요.'), backgroundColor: AppColors.error)); return; }
            try {
              final user = supabase.auth.currentUser; if (user == null) { ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.'), backgroundColor: AppColors.error)); return; }
              List<String> urls = [], names = [];
              for (var f in files) { try { if (f.bytes == null) continue; final ts = DateTime.now().millisecondsSinceEpoch; final safe = f.name.replaceAll(RegExp(r'[^\w\s\.-]'), '').replaceAll(RegExp(r'\s+'), '_'); final p = '${user.id}/$ts-$safe'; await supabase.storage.from('notice-files').uploadBinary(p, f.bytes!); urls.add(supabase.storage.from('notice-files').getPublicUrl(p)); names.add(f.name); } catch (_) {} }
              final resp = await supabase.from('notices').insert({'title': tc.text, 'content': cc.text, 'author': nc.text.isNotEmpty ? nc.text : '관리자', 'author_id': user.id, 'category': cat, 'views': 0, 'is_new': true, 'file_urls': urls, 'file_names': names}).select();
              if (resp.isNotEmpty) { setState(() => _notices.insert(0, Notice.fromJson(resp.first))); Navigator.of(ctx).pop(); ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: const Text('공지사항이 등록되었습니다.'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))); }
            } catch (e) { ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('등록 실패: $e'), backgroundColor: AppColors.error)); }
          }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
            child: const Text('등록', style: TextStyle(fontWeight: FontWeight.w700)))),
        ]),
      ]))))));
  }

  void _showWriteGalleryDialog() {
    final tc = TextEditingController(); final dc = TextEditingController();
    List<PlatformFile> images = [];
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, ss) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(width: 540, padding: const EdgeInsets.all(32), child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.accentWarm, AppColors.accentWarm.withOpacity(0.7)]), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.add_photo_alternate, color: Colors.white, size: 20)), const SizedBox(width: 12), const Text('갤러리 등록', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800))]),
        const SizedBox(height: 24),
        _dlgField(tc, '제목', Icons.title, false), const SizedBox(height: 12),
        TextField(controller: dc, maxLines: 4, decoration: InputDecoration(labelText: '설명 (선택)', alignLabelWithHint: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.secondary, width: 2)))),
        const SizedBox(height: 16),
        const Text('이미지 첨부', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)), const SizedBox(height: 8),
        InkWell(onTap: () async { final r = await FilePicker.platform.pickFiles(allowMultiple: true, type: FileType.image); if (r != null) ss(() { if (images.length + r.files.length <= 10) images.addAll(r.files); }); },
          child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.image_outlined, color: AppColors.secondary, size: 20), SizedBox(width: 8), Text('이미지 선택 (최대 10장)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.secondary))]))),
        if (images.isNotEmpty) ...[const SizedBox(height: 8), Wrap(spacing: 6, runSpacing: 6, children: images.asMap().entries.map((e) => Chip(label: Text(e.value.name, style: const TextStyle(fontSize: 11)), deleteIcon: const Icon(Icons.close, size: 14), onDeleted: () => ss(() => images.removeAt(e.key)))).toList())],
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.of(ctx).pop(), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), side: const BorderSide(color: AppColors.border)), child: const Text('취소', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600)))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(onPressed: () async {
            if (tc.text.isEmpty) { ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('제목을 입력해주세요.'), backgroundColor: AppColors.error)); return; }
            if (images.isEmpty) { ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('이미지를 1장 이상 첨부해주세요.'), backgroundColor: AppColors.error)); return; }
            try {
              final user = supabase.auth.currentUser; if (user == null) return;
              List<String> urls = [];
              for (var f in images) { try { if (f.bytes == null) continue; final ts = DateTime.now().millisecondsSinceEpoch; final safe = f.name.replaceAll(RegExp(r'[^\w\s\.-]'), '').replaceAll(RegExp(r'\s+'), '_'); final p = '${user.id}/$ts-$safe'; await supabase.storage.from('gallery-images').uploadBinary(p, f.bytes!); urls.add(supabase.storage.from('gallery-images').getPublicUrl(p)); } catch (_) {} }
              final resp = await supabase.from('gallery').insert({'title': tc.text, 'description': dc.text, 'author': '관리자', 'author_id': user.id, 'image_urls': urls}).select();
              if (resp.isNotEmpty) { setState(() => _galleryItems.insert(0, Gallery.fromJson(resp.first))); Navigator.of(ctx).pop(); ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: const Text('갤러리가 등록되었습니다.'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))); }
            } catch (e) { ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('등록 실패: $e'), backgroundColor: AppColors.error)); }
          }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
            child: const Text('등록', style: TextStyle(fontWeight: FontWeight.w700)))),
        ]),
      ]))))));
  }

  void _showWritePressReleaseDialog() {
    final tc = TextEditingController(); final cc = TextEditingController();
    List<PlatformFile> files = [];
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, ss) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(width: 540, padding: const EdgeInsets.all(32), child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.accent, AppColors.accent.withOpacity(0.7)]), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.newspaper, color: Colors.white, size: 20)), const SizedBox(width: 12), const Text('보도자료 작성', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800))]),
        const SizedBox(height: 24),
        _dlgField(tc, '제목', Icons.title, false), const SizedBox(height: 12),
        TextField(controller: cc, maxLines: 8, decoration: InputDecoration(labelText: '내용', alignLabelWithHint: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.secondary, width: 2)))),
        const SizedBox(height: 16),
        Row(children: [const Text('파일 첨부', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)), const SizedBox(width: 6), Text('(선택, 최대 5개)', style: TextStyle(fontSize: 11, color: AppColors.textMuted))]),
        const SizedBox(height: 8),
        InkWell(onTap: () async { final r = await FilePicker.platform.pickFiles(allowMultiple: true, type: FileType.any); if (r != null) ss(() { if (files.length + r.files.length <= 5) files.addAll(r.files); }); },
          child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.cloud_upload_outlined, color: AppColors.secondary, size: 20), SizedBox(width: 8), Text('파일 선택', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.secondary))]))),
        ...files.asMap().entries.map((e) => Container(margin: const EdgeInsets.only(top: 4), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
          child: Row(children: [Icon(_getFileIcon(e.value.extension ?? ''), size: 16, color: AppColors.secondary), const SizedBox(width: 6), Expanded(child: Text(e.value.name, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)), Text(_formatFileSize(e.value.size), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)), const SizedBox(width: 6), InkWell(onTap: () => ss(() => files.removeAt(e.key)), child: const Icon(Icons.close, size: 16, color: AppColors.error))]))),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.of(ctx).pop(), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), side: const BorderSide(color: AppColors.border)), child: const Text('취소', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600)))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(onPressed: () async {
            if (tc.text.isEmpty || cc.text.isEmpty) { ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('제목과 내용을 입력해주세요.'), backgroundColor: AppColors.error)); return; }
            try {
              final user = supabase.auth.currentUser; if (user == null) return;
              List<String> urls = [], names = [];
              for (var f in files) { try { if (f.bytes == null) continue; final ts = DateTime.now().millisecondsSinceEpoch; final safe = f.name.replaceAll(RegExp(r'[^\w\s\.-]'), '').replaceAll(RegExp(r'\s+'), '_'); final p = '${user.id}/$ts-$safe'; await supabase.storage.from('press-files').uploadBinary(p, f.bytes!); urls.add(supabase.storage.from('press-files').getPublicUrl(p)); names.add(f.name); } catch (_) {} }
              final resp = await supabase.from('press_releases').insert({'title': tc.text, 'content': cc.text, 'author': '관리자', 'author_id': user.id, 'file_urls': urls, 'file_names': names}).select();
              if (resp.isNotEmpty) { setState(() => _pressReleases.insert(0, PressRelease.fromJson(resp.first))); Navigator.of(ctx).pop(); ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: const Text('보도자료가 등록되었습니다.'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))); }
            } catch (e) { ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('등록 실패: $e'), backgroundColor: AppColors.error)); }
          }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
            child: const Text('등록', style: TextStyle(fontWeight: FontWeight.w700)))),
        ]),
      ]))))));
  }

  Widget _dlgField(TextEditingController c, String label, IconData icon, bool obscure, {VoidCallback? onSubmit}) {
    return TextField(controller: c, obscureText: obscure, keyboardType: obscure ? null : TextInputType.emailAddress, onSubmitted: onSubmit != null ? (_) => onSubmit() : null,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: AppColors.secondary, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.secondary, width: 2)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)));
  }

  Future<void> _handleLogin(String email, String pw, BuildContext ctx, StateSetter ss, Function(bool) setL) async {
    if (email.isEmpty || pw.isEmpty) { ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('이메일과 비밀번호를 입력해주세요.'), backgroundColor: AppColors.error)); return; }
    setL(true);
    try {
      final r = await supabase.auth.signInWithPassword(email: email, password: pw);
      if (r.user != null) { setState(() { _isLoggedIn = true; _loggedInUser = r.user!.email ?? ''; }); Navigator.of(ctx).pop(); ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('환영합니다, ${r.user!.email}님!'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))); }
    } on AuthException catch (e) { ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('로그인 실패: ${e.message}'), backgroundColor: AppColors.error));
    } catch (e) { ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('오류: $e'), backgroundColor: AppColors.error));
    } finally { setL(false); }
  }

  Future<void> _handleSignup(String email, String pw, String confirm, BuildContext ctx, StateSetter ss, Function(bool) setL) async {
    if (email.isEmpty || pw.isEmpty || confirm.isEmpty) { ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('모든 필드를 입력해주세요.'), backgroundColor: AppColors.error)); return; }
    if (pw != confirm) { ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('비밀번호가 일치하지 않습니다.'), backgroundColor: AppColors.error)); return; }
    if (pw.length < 6) { ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('비밀번호는 최소 6자 이상이어야 합니다.'), backgroundColor: AppColors.error)); return; }
    setL(true);
    try {
      final r = await supabase.auth.signUp(email: email, password: pw);
      if (r.user != null) { Navigator.of(ctx).pop(); ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('회원가입 완료! 로그인해주세요.'), backgroundColor: AppColors.success, duration: Duration(seconds: 3))); Future.delayed(const Duration(milliseconds: 500), _showLoginDialog); }
    } on AuthException catch (e) { ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('회원가입 실패: ${e.message}'), backgroundColor: AppColors.error));
    } catch (e) { ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('오류: $e'), backgroundColor: AppColors.error));
    } finally { setL(false); }
  }

  // ═══════════════════════════════════════════
  //  UTILITY
  // ═══════════════════════════════════════════
  IconData _getFileIcon(String ext) {
    switch (ext.toLowerCase()) { case 'pdf': return Icons.picture_as_pdf; case 'doc': case 'docx': return Icons.description; case 'xls': case 'xlsx': return Icons.table_chart; case 'jpg': case 'jpeg': case 'png': case 'gif': return Icons.image; case 'zip': case 'rar': return Icons.folder_zip; default: return Icons.insert_drive_file; }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

// ═══════════════════════════════════════════
//  ANIMATION WIDGETS
// ═══════════════════════════════════════════
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 700),
    this.offset = const Offset(0, 30),
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnim;
  late Animation<Offset> _offsetAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    final curve = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _opacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(curve);
    _offsetAnim = Tween<Offset>(begin: widget.offset, end: Offset.zero).animate(curve);

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(
        opacity: _opacityAnim.value,
        child: Transform.translate(
          offset: _offsetAnim.value,
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

class HoverScaleCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final BorderRadius borderRadius;

  const HoverScaleCard({
    super.key,
    required this.child,
    required this.onTap,
    this.borderRadius = BorderRadius.zero,
  });

  @override
  State<HoverScaleCard> createState() => _HoverScaleCardState();
}

class _HoverScaleCardState extends State<HoverScaleCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()..scale(_isHovered ? 1.04 : 1.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            boxShadow: _isHovered ? AppShadows.medium : AppShadows.soft,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
