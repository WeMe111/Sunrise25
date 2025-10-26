# 🚀 Vercel 배포 가이드

인천장애인능력개발협회 웹사이트를 Vercel에 배포하는 방법입니다.

---

## 📋 사전 준비

### ✅ 필요한 것
1. **GitHub 계정** (https://github.com)
2. **Vercel 계정** (https://vercel.com)
3. **Git 설치** (https://git-scm.com)

---

## 🚨 중요: Shader Compilation 오류

현재 로컬 Windows 환경에서 `flutter build web`을 실행하면 `ink_sparkle.frag` 셰이더 컴파일 오류가 발생합니다.

이는 Flutter 3.32.7의 알려진 버그이며, **GitHub Actions를 사용하여 자동으로 빌드하는 방식으로 해결**했습니다.

자세한 내용은 [SHADER_BUILD_ISSUE.md](SHADER_BUILD_ISSUE.md)를 참고하세요.

---

## 🎯 배포 단계

### **1단계: GitHub 저장소 생성 및 설정**

GitHub Actions가 자동으로 빌드를 수행하도록 설정되어 있습니다.

---

### **2단계: GitHub 저장소 생성**

1. **GitHub에 로그인**
   - https://github.com 접속

2. **새 저장소 생성**
   - 오른쪽 상단 "+" → "New repository" 클릭
   - Repository name: `sunrise` (또는 원하는 이름)
   - Public 선택 (무료)
   - "Create repository" 클릭

3. **저장소 URL 복사**
   ```
   https://github.com/[사용자명]/sunrise.git
   ```

---

### **3단계: Git 초기화 및 푸시**

프로젝트 폴더에서 다음 명령어를 실행하세요:

```bash
# 1. Git 초기화
cd c:\Users\장우림\Desktop\FlutterProjects\sunrise
git init

# 2. 모든 파일 추가 (빌드 결과물 포함!)
git add .

# 3. 첫 커밋 생성
git commit -m "Initial commit: 인천장애인능력개발협회 웹사이트"

# 4. 기본 브랜치를 main으로 설정
git branch -M main

# 5. GitHub 저장소 연결 (위에서 복사한 URL 사용)
git remote add origin https://github.com/[사용자명]/sunrise.git

# 6. GitHub에 푸시
git push -u origin main
```

**GitHub 로그인 요청 시:**
- 사용자명: GitHub 사용자명 입력
- 비밀번호: Personal Access Token 입력 (비밀번호 아님!)

**Personal Access Token 생성 방법:**
1. GitHub → Settings → Developer settings
2. Personal access tokens → Tokens (classic)
3. Generate new token → repo 권한 선택
4. 생성된 토큰 복사 (다시 볼 수 없으니 안전하게 보관)

---

### **4단계: Vercel 배포**

#### **방법 1: Vercel 웹사이트 (추천)**

1. **Vercel 가입/로그인**
   - https://vercel.com 접속
   - "Sign Up" → "Continue with GitHub" 선택

2. **프로젝트 가져오기**
   - 대시보드에서 "Add New" → "Project" 클릭
   - GitHub 저장소 목록에서 `sunrise` 선택
   - "Import" 클릭

3. **프로젝트 설정**
   ```
   Framework Preset: Other
   Build Command: (비워두기 또는 echo "Using pre-built files")
   Output Directory: build/web
   Install Command: (비워두기)
   ```

4. **환경 변수 설정** (선택사항)
   - "Environment Variables" 섹션에서 Supabase 키 추가 가능
   - 하지만 현재 코드는 하드코딩되어 있으므로 생략 가능

5. **Deploy 클릭**

---

#### **방법 2: Vercel CLI**

```bash
# 1. Vercel CLI 설치
npm install -g vercel

# 2. Vercel 로그인
vercel login

# 3. 프로젝트 배포
cd c:\Users\장우림\Desktop\FlutterProjects\sunrise
vercel --prod

# 4. 질문에 답변
# - Set up and deploy? Y
# - Which scope? (계정 선택)
# - Link to existing project? N
# - Project name? sunrise
# - Directory? ./
# - Want to override settings? Y
#   - Output Directory? build/web
```

---

## 🔄 업데이트 배포 절차

코드를 수정한 후 다시 배포하려면:

```bash
# Git에 커밋 및 푸시만 하면 됩니다!
git add .
git commit -m "업데이트: [수정 내용 설명]"
git push

# → GitHub Actions가 자동으로 빌드
# → 빌드 완료 후 Vercel이 자동으로 재배포
```

**참고**: `.github/workflows/build.yml` 파일로 인해 코드를 푸시하면:
1. GitHub Actions가 Ubuntu 환경에서 자동으로 `flutter build web` 실행
2. 빌드 결과물을 `build/web` 폴더에 커밋
3. Vercel이 변경사항을 감지하고 자동 배포

---

## ⚙️ 고급 설정 (선택사항)

### **커스텀 도메인 연결**

1. Vercel 프로젝트 → Settings → Domains
2. 도메인 입력 후 Add
3. DNS 설정 (제공되는 안내 따르기)

### **환경 변수 관리**

Supabase URL과 Key는 환경 변수로 관리하는 것이 좋습니다:

1. Vercel 프로젝트 → Settings → Environment Variables
2. 추가:
   ```
   SUPABASE_URL = https://ewzwuyzxgkxwvbhlajmf.supabase.co
   SUPABASE_ANON_KEY = [Supabase Anon Key]
   ```

---

## 🔧 문제 해결

### ❌ 빌드 실패: "flutter: 명령을 찾을 수 없습니다"

**원인:** Vercel이 Flutter를 직접 빌드할 수 없음
**해결:** 로컬에서 빌드 후 `build/web` 폴더를 Git에 포함

```bash
# 로컬에서 빌드
flutter build web --release --web-renderer html

# build/web 폴더가 .gitignore에 있다면 제거
# .gitignore 파일에서 /build/ 라인 주석 처리 또는 삭제

# Git에 추가
git add build/web
git commit -m "Add production build files"
git push
```

### ❌ 404 에러

**원인:** 라우팅 설정 문제
**해결:** `vercel.json` 파일 확인

```json
{
  "routes": [
    {
      "src": "/(.*)",
      "dest": "/index.html"
    }
  ]
}
```

### ❌ 파일 업로드 안됨

**원인:** CORS 설정
**해결:** Supabase Storage CORS 설정 확인

### ❌ build/web 폴더가 Git에 추가 안됨

**원인:** .gitignore에서 build 폴더 제외
**해결:** .gitignore 수정

```bash
# .gitignore 파일에서 다음 라인을 찾아서 주석 처리:
# /build/  →  # /build/

# 또는 build/web만 허용:
/build/*
!/build/web/
```

---

## 📊 배포 완료 확인

배포가 성공하면:

1. ✅ Vercel이 URL 제공 (예: `https://sunrise-xxx.vercel.app`)
2. ✅ 자동 HTTPS 인증서 발급
3. ✅ GitHub push할 때마다 자동 재배포
4. ✅ 전 세계 CDN 배포

---

## 🎉 완료!

이제 `https://[프로젝트명].vercel.app`에서 웹사이트를 확인할 수 있습니다!

**자동 배포 흐름:**
```bash
# 1. 코드 수정
# 2. 로컬 빌드
flutter build web --release --web-renderer html

# 3. Git 푸시
git add .
git commit -m "업데이트 내용"
git push

# → Vercel이 자동으로 감지하고 재배포
```

---

## 📞 추가 도움말

- Vercel 문서: https://vercel.com/docs
- Flutter Web 배포: https://docs.flutter.dev/deployment/web
- GitHub 문서: https://docs.github.com
