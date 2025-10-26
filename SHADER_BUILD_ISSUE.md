# 🔴 Shader Compilation 오류 해결 방법

## 문제 상황

Flutter 3.32.7에서 `ink_sparkle.frag` 셰이더 컴파일 시 `impellerc`가 크래시하는 이슈가 발생하고 있습니다.

```
ShaderCompilerException: Shader compilation of "ink_sparkle.frag" failed with exit code -1073741819
```

이것은 **Flutter SDK 버그**로, Windows 환경에서 발생하는 알려진 문제입니다.

---

## 해결 방법

### 방법 1: GitHub Actions로 빌드 (추천)

Vercel은 GitHub Actions와 통합되므로, GitHub Actions에서 빌드한 후 Vercel에 배포할 수 있습니다.

#### 1단계: `.github/workflows/build.yml` 생성

프로젝트 루트에 다음 파일을 생성:

```yaml
name: Build Flutter Web

on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
          channel: 'stable'

      - name: Install dependencies
        run: flutter pub get

      - name: Build web
        run: flutter build web --release

      - name: Commit build files
        run: |
          git config --local user.email "github-actions[bot]@users.noreply.github.com"
          git config --local user.name "github-actions[bot]"
          git add build/web -f
          git commit -m "Build: Update web build files [skip ci]" || echo "No changes to commit"
          git push
```

#### 2단계: .gitignore 수정

`build/web`를 Git에 포함시키기 위해 `.gitignore` 수정:

```bash
# .gitignore에서 다음을 찾아서:
/build/

# 다음으로 변경:
/build/*
!/build/web/
```

#### 3단계: GitHub에 푸시

```bash
git add .github/workflows/build.yml .gitignore
git commit -m "Add GitHub Actions workflow for building"
git push
```

GitHub Actions가 자동으로 빌드를 수행하고 `build/web` 폴더를 커밋합니다.

---

### 방법 2: Flutter SDK 다운그레이드

Flutter 3.24.0으로 다운그레이드하면 문제가 해결될 수 있습니다:

```bash
# Flutter를 3.24.0으로 변경
flutter downgrade 3.24.0

# 캐시 정리
flutter clean

# 빌드
flutter build web --release
```

---

### 방법 3: Flutter SDK 업그레이드

최신 버전에서 이슈가 수정되었을 수 있습니다:

```bash
# Flutter를 최신 stable로 업그레이드
flutter upgrade

# 캐시 정리
flutter clean

# 빌드
flutter build web --release
```

---

### 방법 4: WSL (Windows Subsystem for Linux) 사용

Windows에서 WSL을 사용하여 Linux 환경에서 빌드:

```bash
# WSL 설치 (PowerShell 관리자 권한)
wsl --install

# WSL에서 Flutter 설치
# https://docs.flutter.dev/get-started/install/linux

# WSL에서 빌드
cd /mnt/c/Users/장우림/Desktop/FlutterProjects/sunrise
flutter build web --release
```

---

### 방법 5: Docker로 빌드

Docker를 사용하여 빌드:

```bash
# Dockerfile 생성
FROM cirrusci/flutter:3.24.0

WORKDIR /app
COPY . .

RUN flutter pub get
RUN flutter build web --release
```

```bash
# 빌드 실행
docker build -t sunrise-builder .
docker create --name sunrise-build sunrise-builder
docker cp sunrise-build:/app/build/web ./build/
```

---

## 임시 해결 방법: 다른 컴퓨터나 환경 사용

- **Mac이나 Linux 컴퓨터**가 있다면 그곳에서 빌드
- **클라우드 개발 환경** (GitHub Codespaces, Gitpod 등)에서 빌드
- **친구/동료 컴퓨터**에서 빌드

---

## 권장 사항

**방법 1 (GitHub Actions)을 강력히 권장합니다** 이유:

1. ✅ 자동화: 코드 푸시할 때마다 자동 빌드
2. ✅ 일관성: 동일한 환경에서 항상 빌드
3. ✅ 무료: GitHub Actions는 공개 저장소에서 무료
4. ✅ 배포 간편: Vercel이 자동으로 감지하고 배포

---

## 추가 정보

- Flutter Issue Tracker: https://github.com/flutter/flutter/issues
- GitHub Actions Flutter: https://github.com/marketplace/actions/flutter-action
- Vercel + GitHub: https://vercel.com/docs/git/vercel-for-github
