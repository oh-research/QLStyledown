# qlstyledown

<p align="center">
  <img src="icon.png" width="128" alt="qlstyledown icon">
</p>

> CSS로 Quick Look을 커스터마이즈하는 Markdown 렌더러

macOS Finder에서 `.md` 파일을 선택하고 Space를 누르면, 사용자가 정의한 CSS로 스타일링된 Markdown 미리보기를 보여줍니다.

## 특징

- **GitHub 스타일** 기본 테마 (다크모드 자동 전환)
- **8개 기본 테마** + 커스텀 CSS 테마 지원
- **코드 구문 하이라이팅** (highlight.js)
- **수식 렌더링** — `$E=mc^2$` 인라인, `$$...$$` 블록 (KaTeX)
- **Mermaid 다이어그램** — ` ```mermaid ` 코드 블록
- **HTML 태그 지원** — `<br>`, `<details>`, `<mark>` 등 (DOMPurify로 XSS 방지)
- **CLI로 테마 전환** — 앱 상주 불필요
- 외부 의존성 없음 (pandoc 불필요)
- 네트워크 요청 없음 (모든 리소스 번들 내장)

## 설치

### Homebrew (추천)

```bash
brew tap oh-research/tap
brew install --cask qlstyledown
```

### 수동 설치

1. [Releases](https://github.com/oh-research/QLStyledown/releases)에서 `.dmg` 다운로드
2. `qlstyledown.app`을 `/Applications`로 드래그
3. 최초 실행 전 Gatekeeper 우회:
   ```bash
   xattr -cr /Applications/qlstyledown.app
   ```
4. 앱을 한 번 실행하면 Quick Look Extension이 등록됩니다

## 사용법

Finder에서 `.md` 파일을 선택하고 **Space**를 누르세요.

> 기존 Markdown Quick Look 플러그인(QLMarkdown 등)이 설치되어 있으면 충돌할 수 있습니다.
> ```bash
> # 기존 플러그인 비활성화
> pluginkit -e ignore -i org.sbarex.QLMarkdown.QLExtension
> ```

## 테마 관리

### CLI

```bash
# 사용 가능한 테마 목록
qlstyledown themes

# 테마 전환
qlstyledown use minimal

# 현재 활성 테마 확인
qlstyledown current
```

### 커스텀 테마 추가

`~/.qlstyledown/themes/`에 CSS 파일을 넣으면 자동으로 인식됩니다:

```bash
cp my-theme.css ~/.qlstyledown/themes/
qlstyledown use my-theme
```

### 기본 제공 테마

| 테마 | 특징 | 밝기 |
|---|---|---|
| `github` | GitHub 스타일 | 라이트/다크 자동 |
| `lapis` | 블루톤 클린 | 라이트/다크 자동 |
| `tailwind` | 모던 타이포그래피 | 라이트/다크 자동 |
| `solarized-light` | 따뜻한 크림색, 세리프 서체 | 라이트 |
| `nord` | 북극 블루 | 다크 |
| `monokai` | 비비드 에디터 컬러 | 다크 |
| `warp-gradient` | 틸 그라디언트 | 다크 |
| `minimal` | 커스텀 CSS 작성용 템플릿 | 라이트/다크 자동 |

커스텀 테마 작성 시 `minimal.css`를 참고하세요.

### CSS 우선순위

```
항상 적용: default.css (GitHub 테마, 기본 스타일)
  ↓ 위에 덮어쓰기 (cascade)
사용자 CSS: CLI로 설정한 글로벌 테마
```

`default.css`가 항상 적용되고, 사용자 CSS가 위에 덮어씁니다.
전체 테마를 다시 쓸 필요 없이 변경하고 싶은 속성만 작성하면 됩니다.

## 요구 사항

- macOS 13.0 (Ventura) 이상

## 삭제

### Homebrew

```bash
brew uninstall --cask qlstyledown
```

사용자 테마까지 완전히 제거하려면:

```bash
brew zap qlstyledown
```

### 완전 삭제 + 캐시 초기화 + 재설치

```bash
# 1. 완전 삭제
brew uninstall --cask qlstyledown 2>/dev/null
rm -rf ~/.qlstyledown

# 2. 캐시 + tap 갱신
brew cleanup --prune=all
brew update

# 3. 재설치
brew install --cask qlstyledown

# 4. 확인
qlstyledown themes
```

### 수동 삭제

```bash
# Extension 등록 해제
pluginkit -e ignore -i com.ohresearch.qlstyledown.qlstyledownPreview

# 파일 삭제
rm -rf /Applications/qlstyledown.app
rm -rf ~/.qlstyledown
```

> **참고**: 삭제 후에도 Quick Look에서 "확장 프로그램을 찾을 수 없습니다" 메시지가 나올 수 있습니다.
> 시스템 캐시가 남아있기 때문이며, **로그아웃 후 다시 로그인**하면 해결됩니다.
> ```bash
> qlmanage -r  # Quick Look 캐시 초기화
> ```

## 기술 스택

- **WKWebView** — 렌더링 엔진
- **markdown-it** — Markdown → HTML 변환 (`html: true`)
- **highlight.js** — 코드 구문 하이라이팅
- **KaTeX** + **markdown-it-texmath** — 수식 렌더링
- **DOMPurify** — HTML sanitizer (XSS 방지)
- **Mermaid** — 다이어그램 렌더링
- **Swift / SwiftUI** — 앱 및 Extension

## 라이선스

MIT License
