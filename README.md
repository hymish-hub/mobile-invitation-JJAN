# JJAN — mobile invitation

열어보는 순간이 기억되는 모바일 초대장. 링크를 연 사람 앞에서 리본이 풀리고 커튼이 걷힙니다.

## 폴더
| 경로 | 내용 |
| --- | --- |
| `web/` | 배포용 사이트 (list → 편집 → 참석자 화면, Supabase 연동). Vercel Root Directory로 지정 |
| `web/supabase/schema.sql` | DB 테이블과 보안 규칙 |
| `SPEC.md` | 서비스 기획서 |
| `invite-editor.html` | 서버 없이 단독으로 열어보는 화면 미리보기 버전 |
| `poster-prototype.html` | 초기 오프닝 애니메이션 프로토타입 |
| `source/` | 템플릿별 일러스트 소스 |

배포와 설정 방법은 `web/README.md`를 보세요.
