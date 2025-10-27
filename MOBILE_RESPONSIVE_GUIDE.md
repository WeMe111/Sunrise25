# 모바일 반응형 디자인 개선 가이드

현재 웹사이트의 모바일 가독성을 개선하기 위한 작업이 필요합니다.

## 현재 문제점

1. 고정된 padding 값 (60px)으로 인해 모바일에서 콘텐츠가 너무 작음
2. 고정된 font size로 인해 모바일에서 텍스트가 작아 읽기 어려움
3. 네비게이션 바가 모바일에 최적화되지 않음
4. 이미지와 컨테이너의 크기가 고정되어 있음

## 해결 방법

### 1. 반응형 헬퍼 메서드 추가

`_LandingPageState` 클래스에 다음 메서드 추가:

```dart
// 화면 크기 확인
bool get _isMobile => MediaQuery.of(context).size.width < 768;
bool get _isTablet => MediaQuery.of(context).size.width >= 768 && MediaQuery.of(context).size.width < 1024;
bool get _isDesktop => MediaQuery.of(context).size.width >= 1024;

// 반응형 padding
double get _responsivePadding {
  if (_isMobile) return 16.0;
  if (_isTablet) return 40.0;
  return 60.0;
}

// 반응형 font size
double _responsiveFontSize(double baseSize) {
  if (_isMobile) return baseSize * 0.8;
  if (_isTablet) return baseSize * 0.9;
  return baseSize;
}
```

### 2. Container padding 수정

모든 페이지의 Container padding을 수정:

**변경 전:**
```dart
Container(
  padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 60),
  child: Column(...)
)
```

**변경 후:**
```dart
Container(
  padding: EdgeInsets.symmetric(
    vertical: _responsivePadding,
    horizontal: _responsivePadding,
  ),
  child: Column(...)
)
```

### 3. 텍스트 크기 수정

모든 Text 위젯의 fontSize를 반응형으로 변경:

**변경 전:**
```dart
Text(
  '법인 소개',
  style: TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.bold,
  ),
)
```

**변경 후:**
```dart
Text(
  '법인 소개',
  style: TextStyle(
    fontSize: _responsiveFontSize(36),
    fontWeight: FontWeight.bold,
  ),
)
```

### 4. 네비게이션 바 반응형 처리

현재 코드의 `_buildNavBar()` 메서드를 수정:

```dart
Widget _buildNavBar() {
  return Container(
    height: _isMobile ? 60 : 80,
    padding: EdgeInsets.symmetric(horizontal: _responsivePadding),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 로고
        GestureDetector(
          onTap: () => setState(() => _currentPage = 0),
          child: Row(
            children: [
              Image.asset(
                'assets/images/logo.png',
                height: _isMobile ? 35 : 50,
              ),
              if (!_isMobile) ...[
                const SizedBox(width: 16),
                Text(
                  '인천장애인능력개발협회',
                  style: TextStyle(
                    fontSize: _responsiveFontSize(20),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
        // 메뉴
        if (_isMobile)
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => setState(() => _isMobileMenuOpen = !_isMobileMenuOpen),
          )
        else
          Row(
            children: [
              _buildNavItem('협회소개'),
              _buildNavItem('공지사항'),
              _buildNavItem('활동갤러리'),
              _buildNavItem('보도자료'),
              _buildNavItem('후원하기'),
              // 로그인 버튼
            ],
          ),
      ],
    ),
  );
}
```

### 5. 모바일 메뉴 드로어 추가

```dart
Widget _buildMobileMenu() {
  if (!_isMobileMenuOpen) return const SizedBox.shrink();

  return Container(
    color: Colors.white,
    child: Column(
      children: [
        ListTile(
          title: const Text('협회소개'),
          onTap: () {
            setState(() {
              _currentPage = 1;
              _isMobileMenuOpen = false;
            });
          },
        ),
        ListTile(
          title: const Text('공지사항'),
          onTap: () {
            setState(() {
              _currentPage = 2;
              _isMobileMenuOpen = false;
            });
          },
        ),
        // 나머지 메뉴 항목들...
      ],
    ),
  );
}
```

### 6. 그리드 레이아웃 반응형 처리

갤러리나 카드 그리드의 경우:

```dart
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: _isMobile ? 1 : (_isTablet ? 2 : 3),
    childAspectRatio: _isMobile ? 1.5 : 1.0,
    crossAxisSpacing: 20,
    mainAxisSpacing: 20,
  ),
  itemBuilder: (context, index) => _buildCard(items[index]),
)
```

### 7. 테이블 레이아웃 모바일 최적화

보도자료나 공지사항 테이블:

```dart
if (_isMobile)
  // 모바일: 카드 형식으로 표시
  ListView.builder(
    itemCount: items.length,
    itemBuilder: (context, index) => Card(
      child: ListTile(
        title: Text(items[index].title),
        subtitle: Text(items[index].date),
        trailing: Icon(Icons.arrow_forward_ios),
      ),
    ),
  )
else
  // 데스크톱: 테이블 형식으로 표시
  Table(...)
```

## 수정이 필요한 주요 위치

### lib/main.dart 파일에서:

1. **라인 210-280**: `_buildNavBar()` - 네비게이션 바
2. **라인 595-750**: `_buildLandingPage()` - 랜딩 페이지
3. **라인 1650-1950**: `_buildGalleryPage()` - 활동갤러리
4. **라인 1951-2100**: `_buildPressReleasePage()` - 보도자료
5. **라인 3066-3200**: `_buildAboutPage()` - 협회소개
6. **라인 3300-3600**: 공지사항 목록 및 상세

## 적용 순서

1. 먼저 반응형 헬퍼 메서드 추가
2. 네비게이션 바 수정
3. 랜딩 페이지 수정
4. 각 페이지별로 순차적으로 수정
5. 테스트 (Chrome 개발자 도구의 모바일 뷰로 확인)

## 테스트 방법

Chrome에서:
1. F12 → 개발자 도구 열기
2. Ctrl+Shift+M → 모바일 뷰 토글
3. 다양한 디바이스 선택 (iPhone SE, iPad, Galaxy S9 등)
4. 각 페이지 확인

## 추가 개선사항

1. **이미지 최적화**:
   - 큰 이미지는 모바일에서 크기 축소
   - BoxFit.contain 또는 BoxFit.cover 사용

2. **터치 영역 확대**:
   - 버튼 최소 크기: 48x48
   - ListTile 사용 권장

3. **스크롤 성능**:
   - ListView.builder 사용
   - physics: const BouncingScrollPhysics()

4. **로딩 인디케이터**:
   - 긴 로딩 시간에 CircularProgressIndicator 표시

## 빠른 적용을 위한 전역 스타일

```dart
class ResponsiveWidget extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveWidget({
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 768) {
          return mobile;
        } else if (constraints.maxWidth < 1024) {
          return tablet ?? desktop;
        } else {
          return desktop;
        }
      },
    );
  }
}
```

사용 예:
```dart
ResponsiveWidget(
  mobile: _buildMobileLayout(),
  desktop: _buildDesktopLayout(),
)
```

## 다음 세션에서 진행할 작업

위 가이드를 참고하여 단계별로 모바일 반응형 작업을 진행하겠습니다.
현재 세션은 토큰 제한으로 인해 전체 작업을 완료하기 어렵습니다.
