# Vercel 흰 화면 문제 해결 가이드

## 문제 증상
Vercel 배포 후 URL에 접속하면 흰 화면만 보입니다.

---

## 해결 방법

### 방법 1: Vercel 설정 확인 및 수정

1. **Vercel 대시보드 접속**
   - https://vercel.com/dashboard
   - 배포한 프로젝트(Sunrise25) 클릭

2. **Settings → General로 이동**

3. **Build & Development Settings 확인**
   - **Framework Preset**: Other
   - **Build Command**: (비워두기 또는 삭제)
   - **Output Directory**: `build/web`
   - **Install Command**: (비워두기 또는 삭제)

4. **Root Directory**
   - 비워두거나 `.` 으로 설정

5. **Save 클릭**

6. **Deployments 탭으로 이동**
   - 가장 최근 배포에서 `...` (점 3개) 클릭
   - "Redeploy" 선택

---

### 방법 2: vercel.json 수정 및 재배포

현재 `vercel.json` 파일을 확인하고 수정:

```json
{
  "buildCommand": null,
  "outputDirectory": "build/web",
  "installCommand": null,
  "framework": null
}
```

그런 다음:

```bash
git add vercel.json
git commit -m "Fix: Update vercel.json configuration"
git push
```

---

### 방법 3: 브라우저 콘솔에서 에러 확인

1. **브라우저 개발자 도구 열기**
   - Chrome: F12 또는 Ctrl+Shift+I
   - 또는 우클릭 → "검사"

2. **Console 탭 확인**
   - 빨간색 에러 메시지가 있는지 확인
   - 특히 다음 에러들을 찾아보세요:
     - `Failed to load resource: 404`
     - `CORS policy`
     - `main.dart.js 404`

3. **Network 탭 확인**
   - 어떤 파일이 로드 실패했는지 확인
   - 특히 `main.dart.js`, `flutter.js` 등

---

### 방법 4: Base Href 문제 (가능성 낮음)

만약 Vercel 프로젝트가 서브디렉토리에 배포되었다면:

1. GitHub Actions 워크플로우 수정:
```yaml
- name: Build web
  run: flutter build web --release --base-href /
```

2. 커밋 및 푸시:
```bash
git add .github/workflows/build.yml
git commit -m "Fix: Set base-href for web build"
git push
```

---

### 방법 5: Vercel 프로젝트 삭제 후 재생성

만약 위 방법들이 모두 실패하면:

1. **Vercel에서 프로젝트 삭제**
   - Settings → General → Delete Project

2. **새 프로젝트 생성**
   - "Add New" → "Project"
   - GitHub에서 "Sunrise25" 선택
   - Import

3. **설정 확인**
   ```
   Framework Preset: Other
   Build Command: (비워두기)
   Output Directory: build/web
   Install Command: (비워두기)
   ```

4. **Deploy 클릭**

---

## 확인 체크리스트

배포 전 확인해야 할 사항:

- [ ] `build/web` 폴더가 GitHub에 푸시되어 있음
- [ ] `build/web/index.html` 파일이 존재함
- [ ] `build/web/main.dart.js` 파일이 존재함
- [ ] Vercel Output Directory가 `build/web`로 설정됨
- [ ] Vercel Build Command가 비어있음
- [ ] GitHub Actions 빌드가 성공함

---

## 가장 흔한 원인

1. **Output Directory 잘못 설정** ❌
   - 잘못: `build`, `/build/web`, `./build/web`
   - 올바름: `build/web`

2. **Build Command 설정됨** ❌
   - 잘못: `flutter build web`
   - 올바름: (비워두기)

3. **Framework Preset 잘못 설정** ❌
   - 잘못: Next.js, Create React App 등
   - 올바름: Other

---

## 디버깅 팁

### 로컬에서 빌드 결과 테스트

```bash
cd build/web
python -m http.server 8000
```

그런 다음 브라우저에서 http://localhost:8000 접속

작동하면 → Vercel 설정 문제
작동 안 하면 → 빌드 문제

---

## 추가 도움

- Vercel 문서: https://vercel.com/docs
- Vercel 서포트: https://vercel.com/support
- Flutter Web 배포: https://docs.flutter.dev/deployment/web
