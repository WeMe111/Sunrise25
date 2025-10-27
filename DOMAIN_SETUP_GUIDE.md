# 🌐 도메인 연결 가이드

Vercel에 배포된 웹사이트에 커스텀 도메인(예: www.yourdomain.com)을 연결하는 방법입니다.

---

## 📋 사전 준비

1. **도메인 구매 필요**
   - 가비아 (gabia.com)
   - 후이즈 (whois.co.kr)
   - 카페24
   - GoDaddy
   - Namecheap 등

2. **Vercel 프로젝트 배포 완료**
   - 현재 배포된 URL: `https://sunrise25.vercel.app`

---

## 🎯 도메인 연결 단계

### 1단계: Vercel에서 도메인 추가

1. **Vercel 대시보드 접속**
   - https://vercel.com/dashboard
   - "Sunrise25" 프로젝트 클릭

2. **Settings 탭으로 이동**
   - 상단 메뉴에서 "Settings" 클릭

3. **Domains 섹션으로 이동**
   - 왼쪽 사이드바에서 "Domains" 클릭

4. **도메인 추가**
   - 입력란에 도메인 입력:
     - 예: `yourdomain.com`
     - 또는: `www.yourdomain.com`
   - "Add" 버튼 클릭

5. **DNS 설정 정보 확인**
   Vercel이 제공하는 DNS 설정 정보가 표시됩니다:
   ```
   Type: A
   Name: @
   Value: 76.76.21.21

   Type: CNAME
   Name: www
   Value: cname.vercel-dns.com
   ```

---

### 2단계: 도메인 등록업체에서 DNS 설정

#### 가비아 (Gabia) 예시:

1. **가비아 로그인**
   - https://www.gabia.com 접속
   - My가비아 로그인

2. **도메인 관리로 이동**
   - "서비스 관리" → "도메인"
   - 연결할 도메인 선택

3. **DNS 정보 수정**
   - "DNS 관리" 또는 "DNS 설정" 클릭
   - "DNS 관리 도구" 실행

4. **레코드 추가**

   **A 레코드 추가:**
   ```
   호스트: @
   값/위치: 76.76.21.21
   TTL: 3600 (또는 기본값)
   ```

   **CNAME 레코드 추가:**
   ```
   호스트: www
   값/위치: cname.vercel-dns.com
   TTL: 3600 (또는 기본값)
   ```

5. **저장**
   - "적용" 또는 "저장" 버튼 클릭

---

#### 후이즈 (Whois) 예시:

1. **후이즈 로그인**
   - https://www.whois.co.kr 접속

2. **나의 서비스 관리**
   - "도메인 관리" 선택

3. **네임서버 설정**
   - 해당 도메인 선택
   - "네임서버 설정" 또는 "DNS 설정"

4. **레코드 추가**
   - A 레코드: `@` → `76.76.21.21`
   - CNAME 레코드: `www` → `cname.vercel-dns.com`

---

#### 카페24 예시:

1. **카페24 로그인**
   - https://www.cafe24.com

2. **도메인 관리**
   - "나의 서비스 관리"
   - "도메인 관리"

3. **DNS 관리**
   - "부가서비스 설정"
   - "DNS 레코드 관리"

4. **레코드 추가**
   - A 레코드와 CNAME 레코드 추가 (위와 동일)

---

### 3단계: DNS 전파 대기

DNS 설정 후 **전 세계에 반영되는 데 시간이 걸립니다**:

- **최소 시간**: 10분 ~ 1시간
- **최대 시간**: 24 ~ 48시간
- **평균 시간**: 2 ~ 4시간

#### DNS 전파 확인 방법:

1. **온라인 도구 사용**
   - https://dnschecker.org
   - 도메인 입력 후 A 레코드 확인
   - 전 세계 DNS 서버에서 반영 상태 확인

2. **명령어로 확인**
   ```bash
   # Windows
   nslookup yourdomain.com

   # Mac/Linux
   dig yourdomain.com
   ```

---

### 4단계: Vercel에서 SSL 인증서 확인

DNS가 정상적으로 연결되면:

1. **Vercel 대시보드**
   - Domains 페이지 새로고침

2. **SSL 자동 발급**
   - Vercel이 자동으로 Let's Encrypt SSL 인증서 발급
   - 상태가 "Valid"로 변경됨
   - 🟢 초록색 체크 표시

3. **HTTPS 자동 적용**
   - `http://yourdomain.com` → `https://yourdomain.com` 자동 리다이렉트

---

## 🔧 고급 설정

### 여러 도메인 연결

하나의 Vercel 프로젝트에 여러 도메인 연결 가능:

```
yourdomain.com          (Primary)
www.yourdomain.com      (Redirect to Primary)
subdomain.yourdomain.com
```

### 서브도메인 추가

예: `admin.yourdomain.com`

**Vercel:**
1. Domains에서 `admin.yourdomain.com` 추가

**DNS 설정:**
```
Type: CNAME
Name: admin
Value: cname.vercel-dns.com
```

### WWW 리다이렉트 설정

**방법 1: Vercel에서 자동 설정**
- `yourdomain.com`과 `www.yourdomain.com` 둘 다 추가
- Primary Domain 선택

**방법 2: DNS에서 설정**
- A 레코드와 CNAME 둘 다 추가 (위에서 설명한 대로)

---

## ❌ 문제 해결

### 문제 1: "Invalid Configuration" 에러

**원인**: DNS 설정이 잘못됨

**해결:**
1. Vercel이 제공한 DNS 정보 다시 확인
2. DNS 레코드 값 정확히 입력했는지 확인
3. TTL 값이 너무 높지 않은지 확인 (3600 권장)

---

### 문제 2: DNS가 전파되지 않음

**해결:**
1. DNS 설정 후 최소 1시간 대기
2. 브라우저 캐시 삭제
   ```
   Chrome: Ctrl + Shift + Delete
   ```
3. DNS 캐시 플러시
   ```bash
   # Windows
   ipconfig /flushdns

   # Mac
   sudo dscacheutil -flushcache
   ```

---

### 문제 3: SSL 인증서 발급 실패

**원인**: DNS가 올바르게 설정되지 않음

**해결:**
1. DNS 전파 완료 대기 (dnschecker.org에서 확인)
2. Vercel Domains 페이지에서 "Refresh" 클릭
3. 필요시 도메인 제거 후 다시 추가

---

### 문제 4: www 있는 주소와 없는 주소가 다르게 보임

**해결:**
- Vercel Domains에서 Primary Domain 설정
- 나머지 도메인은 자동으로 Primary로 리다이렉트됨

---

## 📊 도메인 설정 예시

### 예시 1: 기본 설정

```
도메인 구매: example.org

Vercel에 추가:
- example.org (Primary)
- www.example.org (Redirect to example.org)

DNS 설정:
Type    Name    Value
A       @       76.76.21.21
CNAME   www     cname.vercel-dns.com

결과:
- https://example.org → 작동
- https://www.example.org → https://example.org로 리다이렉트
```

---

### 예시 2: 서브도메인 포함

```
도메인: mysite.com

Vercel에 추가:
- mysite.com
- www.mysite.com
- admin.mysite.com

DNS 설정:
Type    Name    Value
A       @       76.76.21.21
CNAME   www     cname.vercel-dns.com
CNAME   admin   cname.vercel-dns.com

결과:
- https://mysite.com → 메인 사이트
- https://www.mysite.com → 메인 사이트로 리다이렉트
- https://admin.mysite.com → 메인 사이트 (같은 프로젝트)
```

---

## 🎉 완료 확인

도메인 연결이 성공하면:

1. ✅ 브라우저에서 `https://yourdomain.com` 접속 가능
2. ✅ SSL 인증서 (자물쇠 아이콘) 표시
3. ✅ Vercel 대시보드에서 "Valid" 상태
4. ✅ DNS 체커에서 A 레코드가 `76.76.21.21`로 표시

---

## 📞 추가 도움

- **Vercel 문서**: https://vercel.com/docs/concepts/projects/domains
- **DNS 체커**: https://dnschecker.org
- **SSL 체커**: https://www.ssllabs.com/ssltest/

---

## 💡 팁

1. **도메인 구매 전 체크사항**
   - .com, .kr, .net 등 원하는 확장자 선택
   - 연간 비용 확인 (보통 1만원 ~ 3만원)
   - WHOIS 정보 공개 여부 확인

2. **비용 절감 팁**
   - 가비아, 후이즈 등 국내 업체 비교
   - 첫 해 할인 프로모션 활용
   - 개인정보 보호 서비스 (선택사항)

3. **추천 도메인 구조**
   ```
   단체/기업: yourorg.or.kr, yourorg.co.kr
   일반: yoursite.com, yoursite.kr
   ```
