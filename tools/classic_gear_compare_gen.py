#!/usr/bin/env python3
# Builds Data.lua for Dalorrian's Classic Gear Compare from game data on wago.tools:
#   Classic Era (wow_classic_era) = what an item did in Classic
#   Forever (wow_classic_beta)    = what it does in Forever, for the item effects only
# Stats are compared live in game (Forever's stats come from item level budgets, not stored numbers).
import csv, re, sys, collections, os
csv.field_size_limit(10**9)
D = sys.argv[1] if len(sys.argv) > 1 else '/tmp/cgc'
OUT = sys.argv[2] if len(sys.argv) > 2 else 'Data.lua'
ERA, FOR = 'wow_classic_era', 'wow_classic_beta'
LOCS = ['enUS', 'deDE', 'frFR', 'esES', 'ptBR', 'itIT', 'ruRU', 'koKR', 'zhCN', 'zhTW']

def rows(name):
    with open(os.path.join(D, name), encoding='utf-8') as f:
        return list(csv.DictReader(f))

def I(x):
    try: return int(float(x))
    except: return 0
def F(x):
    try: return float(x)
    except: return 0.0

class Branch:
    def __init__(self, b):
        self.b = b
        self.eff = collections.defaultdict(dict)        # spell -> index -> row
        for r in rows(f'SpellEffect_{b}.csv'):
            if I(r['DifficultyID']) != 0: continue
            self.eff[I(r['SpellID'])][I(r['EffectIndex'])] = r
        dur = {I(r['ID']): I(r['Duration']) for r in rows(f'SpellDuration_{b}.csv')}
        self.dur = {}
        for r in rows(f'SpellMisc_{b}.csv'):
            if I(r['DifficultyID']) != 0: continue
            self.dur[I(r['SpellID'])] = dur.get(I(r['DurationIndex']), 0)
        self.proc = {}
        for r in rows(f'SpellAuraOptions_{b}.csv'):
            if I(r.get('DifficultyID', 0)) != 0: continue
            self.proc[I(r['SpellID'])] = I(r['ProcChance'])
        self.desc = {}
        for loc in LOCS:
            name = f'Spell_{b}.csv' if loc == 'enUS' else f'Spell_{loc}_{b}.csv'
            self.desc[loc] = {I(r['ID']): r['Description_lang'] for r in rows(name)}

    def value(self, spell, idx):
        e = self.eff.get(spell, {}).get(idx)
        if not e: return None
        if 'EffectBasePoints' not in e:   # Forever: the value itself, as a decimal
            v = F(e['EffectBasePointsF'])
            return int(v) if v == int(v) else round(v, 2)
        bp, ds = I(e['EffectBasePoints']), I(e['EffectDieSides'])
        if ds > 1: return (bp + 1, bp + ds)
        return bp + ds if ds else bp

    def period(self, spell, idx):
        e = self.eff.get(spell, {}).get(idx)
        return I(e['EffectAuraPeriod']) if e else 0

DUR_WORDS = {
    'enUS': ('sec', 'min', 'hrs', 'hr'), 'deDE': ('Sek.', 'Min.', 'Std.', 'Std.'), 'frFR': ('s', 'min', 'h', 'h'),
    'esES': ('s', 'min', 'h', 'h'), 'ptBR': ('s', 'min', 'h', 'h'), 'itIT': ('s', 'min', 'h', 'h'),
    'ruRU': ('сек.', 'мин.', 'ч.', 'ч.'), 'koKR': ('초', '분', '시간', '시간'), 'zhCN': ('秒', '分钟', '小时', '小时'),
    'zhTW': ('秒', '分鐘', '小時', '小時'),
}
def Dur(ms, loc):
    s, m, hs, h1 = DUR_WORDS[loc]
    sec = ms / 1000
    if sec >= 3600: n = round(sec / 3600, 1); n = int(n) if n == int(n) else n; return f'{n} {h1 if n == 1 else hs}'
    if sec >= 60: n = round(sec / 60, 1); n = int(n) if n == int(n) else n; return f'{n} {m}'
    n = round(sec, 1); n = int(n) if n == int(n) else n
    return f'{n} {s}'

def num(v):
    if isinstance(v, tuple): return v
    return v

class Unresolved(Exception): pass

def Resolve(br, spell, text, loc):
    if not text: raise Unresolved()
    text = text.replace('\r', '').strip()
    def val(sp, kind, idx):
        sp = sp or spell
        idx = (idx or 1) - 1
        k = kind.lower()
        if k in ('s', 'm', 'w'):
            v = br.value(sp, idx)
            if v is None: raise Unresolved()
            return v
        if k == 'o':
            v = br.value(sp, idx); p = br.period(sp, idx); d = br.dur.get(sp, 0)
            if v is None or not p or not d: raise Unresolved()
            if isinstance(v, tuple): v = v[1]
            return abs(v) * (d // p)
        if k == 't':
            p = br.period(sp, idx)
            if not p: raise Unresolved()
            return round(p / 1000, 1)
        if k == 'd':
            d = br.dur.get(sp, 0)
            if not d: raise Unresolved()
            return ('dur', d)
        if k == 'h':
            return br.proc.get(sp, 0) or (_ for _ in ()).throw(Unresolved())
        if k == 'x':
            e = br.eff.get(sp, {}).get(idx)
            if not e: raise Unresolved()
            return I(e['EffectChainTargets'])
        if k == 'a':
            raise Unresolved()
        raise Unresolved()
    def fmt(v):
        if isinstance(v, tuple) and v and v[0] == 'dur': return Dur(v[1], loc)
        if isinstance(v, tuple): return f'{abs(v[0])} to {abs(v[1])}' if loc == 'enUS' else f'{abs(v[0])}-{abs(v[1])}'
        if isinstance(v, float): return str(int(v)) if v == int(v) else str(v)
        return str(abs(v))
    if '$<' in text or '$?' in text or '$@' in text or '$*' in text:
        raise Unresolved()
    last = [None]
    # ${expression} or ${expression}.N (N decimals): work the sum out
    def expr(mo):
        inner, dec = mo.group(1), mo.group(2)
        def tok(m2):
            sp = int(m2.group(1)) if m2.group(1) else None
            v = val(sp, m2.group(2), int(m2.group(3)) if m2.group(3) else None)
            if isinstance(v, tuple): raise Unresolved()
            return str(abs(v))
        e = re.sub(r'\$(\d+)?([sSmMoOtThHxXwW])(\d)?', tok, inner)
        if not re.fullmatch(r'[0-9.+\-*/() ]+', e): raise Unresolved()
        try: v = eval(e, {'__builtins__': {}})
        except Exception: raise Unresolved()
        if dec: return ('%.' + dec + 'f') % v
        return str(int(v)) if v == int(v) else str(round(v, 2))
    text = re.sub(r'\$\{([^}]*)\}(?:\.(\d))?', expr, text)
    def div(mo):
        v = val(int(mo.group(2)) if mo.group(2) else None, mo.group(3), int(mo.group(4)) if mo.group(4) else None)
        if isinstance(v, tuple): raise Unresolved()
        x = abs(v) / int(mo.group(1))
        return str(int(x)) if x == int(x) else str(round(x, 1))
    text = re.sub(r'\$/(\d+);(\d+)?([sSmM])(\d)?', div, text)
    def rep(mo):
        sp = int(mo.group(1)) if mo.group(1) else None
        v = val(sp, mo.group(2), int(mo.group(3)) if mo.group(3) else None)
        if not (isinstance(v, tuple) and v[0] == 'dur'):
            last[0] = v
        return fmt(v)
    out = re.sub(r'\$(\d+)?([sSmMoOtTdDhHxXwW])(\d)?', rep, text)
    # $lsingular:plural;  (the last number decides)
    def plural(mo):
        a, b = mo.group(1), mo.group(2)
        nums = re.findall(r'(\d+(?:\.\d+)?)', out[:mo.start()])
        n = float(nums[-1]) if nums else 2
        return a if n == 1 else b
    out = re.sub(r'\$[lL]([^:;]*):([^;]*);', plural, out)
    if '$' in out: raise Unresolved()
    return out.strip()

print('loading Classic Era...', file=sys.stderr)
era = Branch(ERA)
print('loading Forever...', file=sys.stderr)
fev = Branch(FOR)

items = {}
for r in rows(f'ItemSparse_{ERA}.csv'):
    inv = I(r['InventoryType'])
    if inv <= 0: continue
    items[I(r['ID'])] = r

# effects per item: { item: [ (trigger, spell), ... ] }
def effects_era():
    out = collections.defaultdict(list)
    for r in rows(f'ItemEffect_{ERA}.csv'):
        sp, tr = I(r['SpellID']), I(r['TriggerType'])
        if sp and tr in (0, 1, 2):
            out[I(r['ParentItemID'])].append((I(r['LegacySlotIndex']), tr, sp))
    return {k: [(t, s) for _, t, s in sorted(v)] for k, v in out.items()}
def effects_forever():
    eff = {I(r['ID']): (I(r['LegacySlotIndex']), I(r['TriggerType']), I(r['SpellID'])) for r in rows(f'ItemEffect_{FOR}.csv')}
    out = collections.defaultdict(list)
    for r in rows(f'ItemXItemEffect_{FOR}.csv'):
        e = eff.get(I(r['ItemEffectID']))
        if e and e[2] and e[1] in (0, 1, 2): out[I(r['ItemID'])].append(e)
    return {k: [(t, s) for _, t, s in sorted(v)] for k, v in out.items()}
EE, FE = effects_era(), effects_forever()
fev_items = {I(r['ID']) for r in rows(f'ItemSparse_{FOR}.csv')}

def Texts(br, effs, loc):
    out = []
    for t, s in effs:
        try:
            out.append((t, Resolve(br, s, br.desc[loc].get(s, ''), loc)))
        except Unresolved:
            out.append((t, None))
    return out

stats_out, fx_out = {}, {loc: {} for loc in LOCS}
changed_fx, unresolved = 0, 0
for iid, r in sorted(items.items()):
    parts = []
    if I(r['RandomSelect']) or I(r['ItemRandomSuffixGroupID']):
        stats_out[iid] = 'X'
        continue
    st = []
    for i in range(10):
        t, a = I(r[f'StatModifier_bonusStat_{i}']), I(r[f'StatModifier_bonusAmount_{i}'])
        if a and t in (0, 1, 3, 4, 5, 6, 7): st.append(f'{t}:{a}')
    if st: parts.append('S' + ','.join(st))
    if I(r['Resistances_0']): parts.append('A' + str(I(r['Resistances_0'])))
    res = [f'{i}:{I(r[f"Resistances_{i}"])}' for i in range(1, 7) if I(r[f'Resistances_{i}'])]
    if res: parts.append('R' + ','.join(res))
    mn, mx, dl = F(r['MinDamage_0']), F(r['MaxDamage_0']), I(r['ItemDelay'])
    if mx > 0 and dl > 0:
        parts.append('D%.1f' % (((mn + mx) / 2) / (dl / 1000)))
    # effects: compare Classic's text to Forever's, in English
    ee, fe = EE.get(iid, []), FE.get(iid, [])
    if iid in fev_items and (ee or fe):
        def norm(lst):
            out = []
            for t, s in lst:
                if s is None: out.append((t, None)); continue
                s = re.sub(r'\d+(?:\.\d+)?', lambda m: repr(float(m.group(0))), s)
                out.append((t, s))
            return out
        a = norm(Texts(era, ee, 'enUS'))
        b = norm(Texts(fev, fe, 'enUS'))
        if a != b and ee:
            changed_fx += 1
            parts.append('E')
            for loc in LOCS:
                tx = Texts(era, ee, loc)
                if loc != 'enUS':   # a language without the text falls back to English
                    en = Texts(era, ee, 'enUS')
                    tx = [(t, s or en[k][1]) for k, (t, s) in enumerate(tx)]
                lines = [(t, s) for t, s in tx if s]
                if len(lines) < len(tx): unresolved += 1
                if lines: fx_out[loc][iid] = lines
    stats_out[iid] = ';'.join(parts)

def q(s):
    return '"' + s.replace('\\', '\\\\').replace('"', '\\"').replace('\n', ' ') + '"'

with open(OUT, 'w', encoding='utf-8') as f:
    f.write('-- Dalorrian\'s Classic Gear Compare: what every piece of gear did in Classic.\n')
    f.write('-- Built from Classic Era game data (wago.tools). S = stats (type:amount), A = armor, R = resistances\n')
    f.write('-- (school:amount), D = damage per second, E = its effects changed in Forever, X = random stats (never compared).\n')
    f.write('local _, ns = ...\n')
    f.write('ns.CLASSIC = {\n')
    for iid, s in stats_out.items():
        f.write(f'[{iid}]={q(s)},\n')
    f.write('}\n')
    f.write('-- the Classic effects of gear whose effects Forever changed: { trigger (0 use, 1 equip, 2 chance on hit), text }\n')
    f.write('ns.CLASSIC_FX = {   -- one builder per language, so only the one you use is ever made\n')
    for loc in LOCS:
        f.write(f'{loc}=function() return {{\n')
        for iid, lines in sorted(fx_out[loc].items()):
            f.write(f'[{iid}]={{' + ','.join(f'{{{t},{q(s)}}}' for t, s in lines) + '},\n')
        f.write('} end,\n')
    f.write('}\n')
print(f'items {len(stats_out)}  effects changed {changed_fx}  unresolved lines {unresolved}', file=sys.stderr)
