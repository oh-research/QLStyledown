# qlstyledown

> CSS로 Quick Look을 커스터마이즈하는 Markdown 렌더러

macOS Finder에서 `.md` 파일을 선택하고 Space를 누르면, 사용자가 정의한 CSS로 스타일링된 Markdown 미리보기를 보여줍니다.

## 특징

- **GitHub 스타일** 기본 테마 (다크모드 자동 전환)
- **코드 구문 하이라이팅** (highlight.js)
- **커스텀 CSS 테마** 지원
- **CLI로 테마 전환** - 앱 상주 불필요
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

기본 제공 테마(`github.css`, `minimal.css`)를 참고하여 작성하세요.

### CSS 우선순위

```
항상 적용: default.css (GitHub 테마, 기본 스타일)
  ↓ 위에 덮어쓰기 (cascade)
사용자 CSS: CLI로 설정한 글로벌 테마
```

`default.css`가 항상 적용되고, 사용자 CSS가 위에 덮어씁니다.
전체 테마를 다시 쓸 필요 없이 변경하고 싶은 속성만 작성하면 됩니다.

## 요구 사항

- macOS Tahoe 26.0+

## 삭제

### Homebrew

```bash
brew uninstall --cask qlstyledown
```

### 수동 삭제

```bash
# Extension 등록 해제
pluginkit -e ignore -i com.ohresearch.qlstyledown.qlstyledownPreview

# 파일 삭제
rm -rf /Applications/qlstyledown.app
rm -rf ~/.qlstyledown
rm -f /usr/local/bin/qlstyledown
```

## 기술 스택

- **WKWebView** - 렌더링 엔진
- **markdown-it** - Markdown → HTML 변환
- **highlight.js** - 코드 구문 하이라이팅
- **Swift / SwiftUI** - 앱 및 Extension

## 라이선스

MIT License
