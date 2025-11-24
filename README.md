# Wesnoth Chess – 공개SW 실무 7조

Battle for Wesnoth 오픈소스를 기반으로 한 **8×8 체스 규칙 기반 미니게임 Add-on** 프로젝트입니다.  
본 프로젝트는 C++, WML, Lua 분석을 통해 기존 엔진 구조를 이해하고  
Add-on 방식으로 새로운 규칙과 게임 모드를 구현하는 것을 목표로 합니다.

---

## 프로젝트 개요
- 원본 오픈소스: The Battle for Wesnoth  
- 방식: Add-on 기반 시나리오 + Lua AI + 체스 규칙 구현
- 지도교수: 류연승 교수
- 팀명: 7조
- 과목: 공개SW 실무

---

## 주요 기능
### 1) 8×8 체스보드 맵
- Re / Ds 지형을 번갈아 사용하여 실제 체스보드 패턴 구현  
- 정사각형 8×8 + 테두리

### 2) 체스 말 이동 규칙(Lua)
- 룩: 직선 무한 이동
- 비숍: 대각선 무한 이동
- 퀸: 직선 + 대각선
- 나이트: L자 이동
- 킹: 8방향 1칸
- 폰: 전진 1칸 + 대각선 공격
- AI는 적 King을 우선 추적 및 공격

### 3) WML 기반 시나리오 구성
- 지도 로드
- 팀(White/Black) 설정
- Lua AI 로드

### 4) 승리 조건(킹 사망 시 즉시 종료)
- White King이 죽으면 패배
- Black King이 죽으면 즉시 승리

---

## 디렉토리 구조
wesnoth-chess-7team/
├─ addons/
│ └─ wesnoth-chess/
│ ├─ _main.cfg
│ ├─ scenarios/
│ │ └─ chess_scenario.cfg
│ ├─ maps/
│ │ └─ chess_8x8.map
│ ├─ units/
│ │ └─ chess_units.cfg
│ ├─ lua/
│ │ └─ chess_logic.lua
│ └─ images/ (기물 이미지는 사용자가 추가)
└─ README.md


---

## 설치 방법 (로컬에서 Add-on 실행)
1. Wesnoth 설치
2. 아래 경로에 Add-on 폴더 복사  
   Windows:  C:\Users<사용자>\Documents\My Games\Wesnoth1.16\data\add-ons\
3. 게임 실행 → User Add-ons → "Wesnoth Chess" 선택

---

## 실행 방법
1. Add-on “Wesnoth Chess” 선택  
2. "Wesnoth Chess 8×8" 시나리오 시작  
3. White(플레이어) vs Black(AI) 체스 규칙 기반 전투 진행  

---

## 팀원
- 최지환  
- 김도윤  
- 장호정  
- 김세정  

---

## 라이선스
원본 오픈소스 Wesnoth는 GPL-2.0  
본 프로젝트 Add-on은 동일하게 GPL 라이선스를 따릅니다.
