# qlstyledown 테스트

이 파일은 Quick Look Extension의 **Markdown 렌더링**을 테스트합니다.

## 텍스트 스타일

일반 텍스트, **굵은 글씨**, *이탤릭*, ~~취소선~~, `인라인 코드`

## 링크

[GitHub](https://github.com)

## 리스트

### 순서 없는 리스트
- 항목 1
- 항목 2
  - 하위 항목 A
  - 하위 항목 B
- 항목 3

### 순서 있는 리스트
1. 첫 번째
2. 두 번째
3. 세 번째

### 체크리스트
- [x] 완료된 작업
- [ ] 미완료 작업
- [ ] 또 다른 작업

## 인용

> 인용문 예시입니다.
> 여러 줄도 가능합니다.

## 코드 블록

```swift
func greet(name: String) -> String {
    return "Hello, \(name)!"
}
```

```javascript
const md = window.markdownit({ html: false });
console.log(md.render("# Hello"));
```

## 테이블

| 기능 | 상태 | 비고 |
|------|------|------|
| Markdown 렌더링 | ✅ | markdown-it |
| CSS 적용 | ✅ | GitHub 테마 |
| 다크모드 | ✅ | 자동 전환 |
| 코드 하이라이팅 | ⏳ | Phase 3 |

## 수평선

---

## 이미지 (상대경로 테스트)

로컬 이미지가 있다면 아래에 표시됩니다:

![테스트 이미지](./test-image.png)

## 특수 문자 테스트

백틱: `` ` ``
달러 기호: `${variable}`
백슬래시: `C:\Users\path`

## 한국어 테스트

가나다라마바사아자차카타파하
ㄱㄴㄷㄹㅁㅂㅅㅇㅈㅊㅋㅌㅍㅎ
