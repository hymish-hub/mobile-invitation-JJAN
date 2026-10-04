# 모바일 초대장 — 실제 공유 링크 버전

이 폴더(`web`)를 그대로 배포하면 됩니다. 빌드 과정이 없는 정적 사이트 + Supabase(로그인·DB) 구조입니다.

- `/` : list 화면 → 템플릿 선택 → `#edit` 편집 화면 (Google 로그인, 자동 저장, 공유 링크 발급)
- `/i/<링크코드>` : 참석자 화면 (로그인 없이 열람·참석 응답)

## 1. 파일
| 파일 | 역할 |
| --- | --- |
| index.html | 화면 전체 (list · 편집 · 참석자) |
| config.js | Supabase / 카카오 키를 넣는 곳 |
| vercel.json | `/i/코드` 주소를 index.html로 연결 |
| supabase/schema.sql | DB 테이블과 보안 규칙 |
| og.png | 링크 미리보기 이미지 |

## 2. Supabase 만들기 (약 5분)
1. https://supabase.com 가입 → New project (Region: Northeast Asia (Seoul))
2. 왼쪽 **SQL Editor** → New query → `supabase/schema.sql` 내용 전체 붙여넣기 → **Run**
3. **Project Settings → API** 에서 `Project URL`, `anon public` 키를 복사해 `config.js`에 넣기

## 3. Google 로그인 켜기 (약 10분)
1. https://console.cloud.google.com → 새 프로젝트 → **API 및 서비스 → OAuth 동의 화면** 설정(외부, 앱 이름·이메일만)
2. **사용자 인증 정보 → OAuth 클라이언트 ID** 만들기 (웹 애플리케이션)
   - 승인된 리디렉션 URI: `https://<프로젝트ID>.supabase.co/auth/v1/callback`
3. 받은 Client ID / Secret을 Supabase **Authentication → Sign In / Providers → Google** 에 넣고 켜기
4. Supabase **Authentication → URL Configuration**
   - Site URL: 배포 주소 (예: `https://my-invite.vercel.app`)
   - Redirect URLs: `https://my-invite.vercel.app/**`, `http://localhost:3000/**`

## 4. 배포 (Vercel)
1. https://vercel.com 가입
2. 터미널에서 이 폴더로 이동 후 `npx vercel` → 질문에 Enter → 미리보기 주소가 나옴
3. 확인 후 `npx vercel --prod` 로 실제 주소 배포
4. 나온 주소를 3-4단계의 Site URL / Redirect URLs에 넣었는지 확인

> Vercel 무료(Hobby) 플랜은 비상업용입니다. 결제를 붙여 판매를 시작하면 Pro로 바꿔야 합니다.

## 5. (선택) 카카오톡 공유
1. https://developers.kakao.com → 내 애플리케이션 → 앱 만들기
2. **앱 키 → JavaScript 키**를 `config.js`의 `kakaoJsKey`에
3. **플랫폼 → Web**에 배포 주소 등록
키가 없으면 [카카오톡으로 보내기]는 링크 복사로 대신 동작합니다.

## 6. 로컬에서 확인
- `npx vercel dev` (권장, `/i/코드` 주소까지 동작) 후 http://localhost:3000
- `config.js`가 비어 있으면 서버 없이 화면 미리보기만 동작합니다.

## 동작 요약
- 편집 화면에서 입력하면 0.8초 뒤 자동 저장 (로그인 필요)
- [공유 링크 만들기] → 링크 발급(`/i/8자리코드`), 이후 내용을 고치면 같은 링크에 바로 반영
- 공개 기간: 행사일 + 7일(무료) / +30일 / +1년. 지나면 참석자 화면에 '기간이 끝난 초대장' 표시
- 참석자는 이름 + 참석/미참석만 입력, 같은 기기에서 다시 누르면 응답이 바뀜
- 참석자에게는 인원 수만, 초대자에게는 이름 목록까지 보임

## 아직 안 된 것
- 결제(토스페이먼츠): 지금은 링크가 무료로 발급됨. 유료 연출·기간 연장 결제 시 발급하도록 붙여야 함
- 초대장별 링크 미리보기 이미지: 지금은 공통 og.png. 카카오톡 공유 버튼은 초대장 제목·날짜가 들어감
- 사진 업로드(유료 기능), 초대장 여러 개 관리(지금은 계정당 최근 1개를 편집)
