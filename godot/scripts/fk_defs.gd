extends RefCounted
## 포 더 킹식 전투 데이터 (docs/05-combat.md 2부).
## 행동마다 판정 칸이 있고, 칸마다 d20 + 능력치 ≥ 난이도면 성공. 성공한 칸 비율만큼 효과가 나고, 전부 성공하면 완벽 성공 보너스.

const STAT := {"str": "힘", "dex": "민첩", "int": "지능", "cha": "매력"}

const STATUS := {
	"stun": "기절", "burn": "화상", "taunt": "도발됨", "guard": "방어", "stealth": "은신",
	"bless": "축복", "oath": "맹세", "smoke": "연막", "cover": "엄폐",
}

const HEROES := {
	"lina": {
		"name": "리나", "role": "탱커", "art": "C01_lina", "color": Color(0.80, 0.28, 0.30),
		"hp": 26, "def": 15, "spd": 2, "mod": {"str": 5, "dex": 0, "int": -1, "cha": 2},
		"skills": ["lina_basic", "lina_bash", "lina_taunt"], "ult": "lina_ult",
	},
	"cecile": {
		"name": "세실", "role": "근접 딜러", "art": "C02_cecile", "color": Color(0.45, 0.36, 0.70),
		"hp": 17, "def": 14, "spd": 5, "mod": {"str": 0, "dex": 5, "int": 1, "cha": 1},
		"skills": ["cecile_basic", "cecile_ambush", "cecile_smoke"], "ult": "cecile_ult",
	},
	"adelheid": {
		"name": "아델하이트", "role": "마법 딜러", "art": "C03_adelheid", "color": Color(0.25, 0.48, 0.85),
		"hp": 14, "def": 12, "spd": 3, "mod": {"str": -1, "dex": 1, "int": 5, "cha": 1},
		"skills": ["adel_basic", "adel_fire", "adel_frost"], "ult": "adel_ult",
	},
	"miriam": {
		"name": "미리엄", "role": "서포터", "art": "C04_miriam", "color": Color(0.85, 0.70, 0.30),
		"hp": 17, "def": 13, "spd": 3, "mod": {"str": 0, "dex": 0, "int": 1, "cha": 5},
		"skills": ["miriam_basic", "miriam_heal", "miriam_bless"], "ult": "miriam_ult",
	},
}

## atk: 명중 보너스, power: 칸을 전부 성공했을 때 피해, slots: 판정 칸 수
const ENEMIES := {
	"bandit": {"name": "도적", "hp": 15, "def": 12, "spd": 2, "atk": 4, "power": 7, "slots": 2, "color": Color(0.55, 0.30, 0.22)},
	"archer": {"name": "도적 궁수", "hp": 11, "def": 12, "spd": 4, "atk": 4, "power": 7, "slots": 2, "color": Color(0.45, 0.40, 0.20)},
	"wolf": {"name": "늑대", "hp": 12, "def": 13, "spd": 5, "atk": 4, "power": 6, "slots": 2, "color": Color(0.40, 0.40, 0.45)},
	"redbeard": {"name": "붉은 수염", "hp": 60, "def": 14, "spd": 2, "atk": 5, "power": 11, "slots": 3, "boss": true, "color": Color(0.62, 0.10, 0.10)},
}

## target: enemy / ally / ally_any(쓰러진 아군 포함) / self / all_enemies / all_allies
## fire: 불붙는 환경(기름 항아리, 방책, 술통)도 대상으로 고를 수 있다
## perfect: 칸을 전부 성공했을 때 덤 효과
const SKILLS := {
	"lina_basic": {"name": "롱소드", "stat": "str", "slots": 2, "power": 8, "target": "enemy", "desc": "피해 8"},
	"lina_bash": {"name": "방패 강타", "stat": "str", "slots": 3, "power": 7, "cd": 2, "target": "enemy", "perfect": "stun", "desc": "피해 7 · 완벽: 기절"},
	"lina_taunt": {"name": "도발", "stat": "cha", "slots": 2, "cd": 3, "target": "self", "effect": "taunt", "desc": "적 전원이 리나를 노린다 (성공 칸 수만큼 턴) + 방어"},
	"lina_ult": {"name": "기사의 맹세", "target": "self", "effect": "oath", "desc": "2라운드 동안 동료가 받을 공격을 대신 받고, 받는 피해 절반"},
	"cecile_basic": {"name": "쌍단검", "stat": "dex", "slots": 2, "power": 8, "target": "enemy", "desc": "피해 8"},
	"cecile_ambush": {"name": "기습", "stat": "dex", "slots": 3, "power": 13, "cd": 2, "target": "enemy", "desc": "피해 13 · 은신 중이면 1칸 확정"},
	"cecile_smoke": {"name": "연막탄", "stat": "dex", "slots": 2, "cd": 3, "target": "self", "effect": "smoke", "desc": "1칸: 세실 은신 · 2칸: 동료 전원 방어 +3"},
	"cecile_ult": {"name": "그림자 난무", "target": "all_enemies", "power": 9, "desc": "적 전원 피해 9 (판정 없음)"},
	"adel_basic": {"name": "마력탄", "stat": "int", "slots": 2, "power": 8, "target": "enemy", "desc": "피해 8"},
	"adel_fire": {"name": "불꽃 화살", "stat": "int", "slots": 3, "power": 9, "cd": 2, "target": "enemy", "fire": true, "desc": "피해 9 + 화상 · 기름 항아리·방책·술통에 불을 붙일 수 있다"},
	"adel_frost": {"name": "서리 사슬", "stat": "int", "slots": 2, "power": 5, "cd": 3, "target": "enemy", "perfect": "stun", "desc": "피해 5 · 완벽: 기절"},
	"adel_ult": {"name": "금서 해방", "target": "all_enemies", "power": 14, "desc": "적 전원 피해 14 (판정 없음)"},
	"miriam_basic": {"name": "지팡이", "stat": "cha", "slots": 2, "power": 5, "target": "enemy", "desc": "피해 5"},
	"miriam_heal": {"name": "치유의 손", "stat": "cha", "slots": 3, "power": 12, "cd": 2, "target": "ally_any", "effect": "heal", "desc": "회복 12, 쓰러진 동료도 일으킨다"},
	"miriam_bless": {"name": "순례자의 축복", "stat": "cha", "slots": 2, "cd": 2, "target": "ally", "effect": "bless", "desc": "2턴 동안 판정 +3 · 완벽: 방어도"},
	"miriam_ult": {"name": "빛의 기둥", "target": "all_allies", "power": 14, "effect": "heal", "desc": "동료 전원 회복 14 + 상태이상 해제, 쓰러진 동료도 일으킨다"},
}

## 주변 환경. 행동 목록에는 안 나오고, 플레이어가 무대에서 직접 눌러 찾아야 한다.
## who: 이 방법을 쓸 수 있는 동료 (동료마다 환경을 쓰는 범위가 다르다)
## skill: 그 동료의 스킬로 불을 붙인다 (판정은 그 스킬로, 성공하면 fire 효과)
## acts 의 판정은 난이도(diff)가 정해져 있다. 한 번 쓰면 사라진다 (reuse 제외)
## effect: explode(적 전원 피해 + 화상) / crush(고른 적 피해, splash 면 옆 적도, 완벽: 기절)
##         break_cover(엄폐 없앰, 완벽: 기절) / hide(은신) / cover_self(방어 +4)
## fire: 불꽃 화살이 닿으면 판정 없이 일어나는 일
const OBJECTS := {
	"bush": {"name": "덤불", "reuse": true, "acts": [
		{"name": "덤불에 숨기", "who": ["cecile", "miriam"], "stat": "dex", "slots": 1, "diff": 8, "effect": "hide"},
	]},
	"oil_jar": {"name": "기름 항아리", "fire": "explode", "power": 6, "acts": [
		{"name": "항아리 던지기", "who": ["cecile"], "stat": "dex", "slots": 2, "diff": 10, "effect": "explode", "power": 6},
		{"name": "불꽃 화살로 불붙이기", "who": ["adelheid"], "skill": "adel_fire"},
	]},
	"dead_tree": {"name": "썩은 고목", "acts": [
		{"name": "고목 쓰러뜨리기", "who": ["lina"], "stat": "str", "slots": 3, "diff": 11, "effect": "crush", "power": 12, "splash": true},
	]},
	"barricade": {"name": "나무 방책", "fire": "burn_cover", "acts": [
		{"name": "방책 부수기", "who": ["lina"], "stat": "str", "slots": 2, "diff": 11, "effect": "break_cover"},
		{"name": "불꽃 화살로 태우기", "who": ["adelheid"], "skill": "adel_fire"},
	]},
	"chandelier": {"name": "샹들리에", "acts": [
		{"name": "단검 던져 밧줄 끊기", "who": ["cecile"], "stat": "dex", "slots": 2, "diff": 12, "effect": "crush", "power": 15},
		{"name": "마력탄으로 밧줄 끊기", "who": ["adelheid"], "stat": "int", "slots": 2, "diff": 13, "effect": "crush", "power": 15},
	]},
	"ale_cask": {"name": "독한 술통", "fire": "explode", "power": 7, "acts": [
		{"name": "술통 굴리기", "who": ["lina"], "stat": "str", "slots": 2, "diff": 10, "effect": "explode", "power": 6},
		{"name": "불꽃 화살로 불붙이기", "who": ["adelheid"], "skill": "adel_fire"},
	]},
	"table": {"name": "무너진 탁자", "reuse": true, "acts": [
		{"name": "탁자 엎고 숨기", "who": ["lina", "miriam"], "stat": "str", "slots": 1, "diff": 7, "effect": "cover_self"},
	]},
}

## 전투 장면. 오브젝트 x, y 는 무대 안 비율 위치. cover 는 엄폐받는 적의 순서(enemies 배열 index)
const BATTLES := [
	{
		"name": "숲속 공터", "desc": "도적 무리 매복. 궁수는 나무 방책 뒤에 숨어 있다",
		"bg": "backgrounds/battle/bt_ch1_forest_clearing_side.png",
		"enemies": ["wolf", "bandit", "bandit", "archer"],
		"objects": [
			{"key": "bush", "x": 0.05, "y": 0.86},
			{"key": "oil_jar", "x": 0.555, "y": 0.80},
			{"key": "dead_tree", "x": 0.74, "y": 0.40},
			{"key": "barricade", "x": 0.905, "y": 0.86, "cover": 3},
		],
		"event": {"round": 3, "alive": "archer", "spawn": ["bandit"], "warn": "3라운드 끝: 궁수가 살아 있으면 나팔 → 도적 증원", "text": "궁수가 나팔을 불었다! 도적이 1명 더 나타났다"},
	},
	{
		"name": "무너진 길드 회관", "desc": "붉은 수염 일당이 회관을 차지했다 (보스)",
		"bg": "backgrounds/scene/bg_guildhall_ruined.png",
		"enemies": ["bandit", "redbeard", "bandit"],
		"objects": [
			{"key": "table", "x": 0.06, "y": 0.86},
			{"key": "chandelier", "x": 0.71, "y": 0.10},
			{"key": "ale_cask", "x": 0.555, "y": 0.82},
		],
	},
]
