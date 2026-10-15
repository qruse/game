extends RefCounted
## 전투 프로토타입 데이터. 수치는 docs/05-combat.md 10~11절을 그대로 옮겼다.

const ABIL := {"str": "힘", "dex": "민첩", "int": "지능", "cha": "매력"}

const STATUS := {
	"burn": "화상", "stun": "기절", "root": "속박", "sleep": "수면", "prone": "넘어짐",
	"taunt": "도발됨", "bless": "축복", "guard": "방어", "oath": "맹세", "stealth": "은신",
}

const TRAITS := {
	"iron_wall": "철벽: 밀치기·넘어짐에 걸리지 않음",
	"guardian": "수호: 인접 아군 방어 +1",
	"slip": "빠져나가기: 빈틈 공격을 받지 않음",
	"bush_stealth": "덤불에 들어가면 은신",
	"guide": "인도: 이동 대신 인접 아군과 자리 바꾸기",
}

const ALLIES := {
	"lina": {
		"name": "리나", "short": "리", "role": "탱커", "color": Color(0.80, 0.28, 0.30), "art": "C01_lina",
		"hp": 22, "ac": 16, "move": 3, "atk": 5, "melee": true,
		"saves": {"str": 5, "dex": 0, "int": -1, "cha": 1},
		"traits": ["iron_wall", "guardian"],
		"actions": ["lina_basic", "lina_bash", "lina_taunt"], "ult": "lina_ult",
	},
	"cecile": {
		"name": "세실", "short": "세", "role": "근접 딜러", "color": Color(0.45, 0.36, 0.70), "art": "C02_cecile",
		"hp": 16, "ac": 14, "move": 5, "atk": 5, "melee": true,
		"saves": {"str": 0, "dex": 5, "int": 1, "cha": 1},
		"traits": ["slip", "bush_stealth"],
		"actions": ["cecile_basic", "cecile_ambush", "cecile_smoke"], "ult": "cecile_ult",
	},
	"adelheid": {
		"name": "아델하이트", "short": "아", "role": "마법 딜러", "color": Color(0.25, 0.48, 0.85), "art": "C03_adelheid",
		"hp": 12, "ac": 12, "move": 2, "atk": 5, "melee": false,
		"saves": {"str": -1, "dex": 1, "int": 5, "cha": 1},
		"traits": [],
		"actions": ["adel_basic", "adel_fire", "adel_frost"], "ult": "adel_ult",
	},
	"miriam": {
		"name": "미리엄", "short": "미", "role": "서포터", "color": Color(0.85, 0.70, 0.30), "art": "C04_miriam",
		"hp": 16, "ac": 13, "move": 3, "atk": 3, "melee": true,
		"saves": {"str": 0, "dex": 0, "int": 1, "cha": 5},
		"traits": ["guide"],
		"actions": ["miriam_basic", "miriam_heal", "miriam_bless"], "ult": "miriam_ult",
	},
}

const ENEMIES := {
	"bandit": {
		"name": "도적", "short": "도", "hp": 11, "ac": 12, "move": 3, "atk": 4,
		"dmg": "1d6+2", "range": 1, "ai": "melee",
		"saves": {"str": 1, "dex": 2, "int": -1, "cha": -1},
	},
	"archer": {
		"name": "도적 궁수", "short": "궁", "hp": 9, "ac": 12, "move": 3, "atk": 4,
		"dmg": "1d8+2", "range": 4, "ai": "ranged",
		"saves": {"str": 0, "dex": 2, "int": 0, "cha": -1},
	},
	"wolf": {
		"name": "늑대", "short": "늑", "hp": 9, "ac": 13, "move": 5, "atk": 4,
		"dmg": "1d6+2", "range": 1, "ai": "beast",
		"saves": {"str": 2, "dex": 2, "int": -4, "cha": -2},
	},
	"redbeard": {
		"name": "붉은 수염", "short": "붉", "hp": 48, "ac": 14, "move": 3, "atk": 5,
		"dmg": "1d12+4", "range": 1, "ai": "boss", "boss": true, "color": Color(0.62, 0.10, 0.10),
		"saves": {"str": 5, "dex": 1, "int": 0, "cha": 2},
	},
}

## target: enemy(적 또는 부술 수 있는 물체) / ally / ally_down(쓰러진 아군 포함) / tile / self
## attack: 운명 주사위를 놓을 수 있는 공격 굴림 · obj: 엄폐물과 기름 항아리도 칠 수 있음
const SKILLS := {
	"lina_basic": {"name": "롱소드", "cd": 0, "target": "enemy", "range": 1, "dmg": "1d8+3", "attack": true, "obj": true, "desc": "근접 1d8+3"},
	"lina_bash": {"name": "방패 강타", "cd": 2, "target": "enemy", "range": 1, "dmg": "1d6+3", "attack": true, "desc": "근접 1d6+3, 밀치기 1칸 (저항: 힘)"},
	"lina_taunt": {"name": "도발", "cd": 3, "target": "self", "range": 0, "desc": "반경 2칸 적 도발 1턴 (저항: 매력)"},
	"lina_ult": {"name": "기사의 맹세", "target": "self", "range": 0, "desc": "2턴 동안 인접 아군 피해를 대신 받고, 받는 피해 절반"},
	"cecile_basic": {"name": "쌍단검", "cd": 0, "target": "enemy", "range": 1, "dmg": "1d4+3", "hits": 2, "attack": true, "obj": true, "desc": "근접 1d4+3 × 2회"},
	"cecile_ambush": {"name": "기습", "cd": 2, "target": "enemy", "range": 1, "dmg": "1d4+3+2d6", "adv": true, "attack": true, "desc": "근접 1회, 유리 굴림, 1d4+3+2d6"},
	"cecile_smoke": {"name": "연막탄", "cd": 3, "target": "tile", "range": 3, "desc": "3×3 연기 2라운드. 안의 아군 은신, 안을 노린 공격 불리"},
	"cecile_ult": {"name": "그림자 난무", "target": "self", "range": 0, "dmg": "2d4+3", "desc": "4칸 안의 적 최대 3명에게 1회씩 공격"},
	"adel_basic": {"name": "마력탄", "cd": 0, "target": "enemy", "range": 4, "ranged": true, "dmg": "1d10+3", "attack": true, "obj": true, "desc": "원거리 4칸 1d10+3"},
	"adel_fire": {"name": "불꽃 화살", "cd": 2, "target": "tile", "range": 4, "ranged": true, "dmg": "2d6", "attack": true, "desc": "원거리 2d6 + 대상 칸에 불 (기름·덤불·항아리·건초에 번진다)"},
	"adel_frost": {"name": "서리 사슬", "cd": 3, "target": "enemy", "range": 4, "ranged": true, "dmg": "1d6", "attack": true, "desc": "원거리 1d6 + 속박 2턴 (저항: 힘)"},
	"adel_ult": {"name": "금서 해방", "target": "tile", "range": 4, "dmg": "4d6", "desc": "3×3 적에게 4d6 (저항: 민첩, 성공 시 절반)"},
	"miriam_basic": {"name": "지팡이", "cd": 0, "target": "enemy", "range": 1, "dmg": "1d6+1", "attack": true, "obj": true, "desc": "근접 1d6+1"},
	"miriam_heal": {"name": "치유의 손", "cd": 2, "target": "ally_down", "range": 2, "dmg": "2d8+3", "desc": "2칸 안 아군 2d8+3 회복, 쓰러진 아군도 일으킴"},
	"miriam_bless": {"name": "순례자의 축복", "cd": 2, "target": "ally", "range": 2, "desc": "아군 1명 축복(굴림 +1d4) + 방어 +2, 2턴"},
	"miriam_ult": {"name": "빛의 기둥", "target": "self", "range": 0, "dmg": "3d8", "desc": "아군 전원 3d8 회복 + 상태이상 해제, 쓰러진 아군도 일으킴"},
}
