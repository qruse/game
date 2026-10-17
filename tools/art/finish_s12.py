"""S12 single-generation recording and authorized technical postprocessing only."""
import argparse
import csv
import io
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageOps

from decontaminate_blonde import decontaminate
from finish_s10r_cecile import key, normalize_alpha

ROOT = Path(__file__).resolve().parents[2]
SESSION = ROOT / 'art/raw/S12_session'
FINAL = ROOT / 'art/final/characters/C04_miriam'
BASE = 'art/final/characters/C04_miriam/'
COMBAT = BASE + 'C04_portrait_combat_neutral.png'
IDLE = BASE + 'C04_sd_idle.png'
STYLE = 'art/refs/style-anchor.png'
CREF = 'art/refs/C04_ref_combat.png'
HREF = 'art/refs/C04_ref_casual.png'


def change_row(asset, updates):
    manifest = ROOT / 'art/manifest.csv'
    text = manifest.read_text(encoding='utf-8-sig')
    row = next(r for r in csv.DictReader(io.StringIO(text)) if r['id'] == asset)
    old = next(line for line in text.splitlines() if line.startswith(asset + ',') or line.startswith('"' + asset + '",'))
    row.update(updates)
    buf = io.StringIO(newline='')
    csv.DictWriter(buf, fieldnames=list(row), lineterminator='').writerow(row)
    manifest.write_text(text.replace(old, buf.getvalue(), 1), encoding='utf-8', newline='')


def cleanup(path):
    count = decontaminate(path)
    subprocess.run([sys.executable, str(ROOT / 'tools/art/despill.py'), str(path)], check=True)
    print(f'{Path(path).name}: decontaminated={count}')


def prepare():
    SESSION.mkdir(parents=True, exist_ok=True)
    step = ROOT / 'art/steps/S12.md'
    feedback = ('\n- 2026-10-17 · 중간 확인 2장 C04_portrait_combat_neutral·C04_sd_idle 사용자 승인(manifest 반영). 나머지 todo 16장(전투복 표정5·일상복 기본/표정6·SD동작4·컷인1)을 각 1회 생성 후 멈춘다. 얼굴 기준은 승인된 기본·시트·미리엄 FACE. 표정은 얼굴 마스크 합성만, 일상복 기본은 새로 생성. 금발 머리끝의 분홍·장밋빛 색 오염을 안쪽 금발 색으로 복원하는 tools/art/decontaminate_blonde.py를 추가해 모든 C04 세트 투명 PNG에 적용하고 despill.py 실행. 승인된 기본·idle 2장도 사용자 허락으로 기술 후처리만 적용(내용·알파·크기·위치 유지). 자체 그림 검수·비교 시트·QA 스크립트 없이 generated 및 prompt 기록.\n')
    step.write_text(step.read_text(encoding='utf-8') + feedback, encoding='utf-8')
    readme = ROOT / 'art/steps/README.md'
    text = readme.read_text(encoding='utf-8')
    text = re.sub(r'(\| \[S12\]\(S12.md\).*\| )[^|\r\n]+( \|)', r'\g<1>진행 중\2', text)
    readme.write_text(text, encoding='utf-8')
    for asset in ('C04_portrait_combat_neutral', 'C04_sd_idle'):
        path = FINAL / (asset + '.png')
        backup = SESSION / (asset + '_before_technical.png')
        if not backup.exists():
            shutil.copy2(path, backup)
        cleanup(path)
        record = path.with_suffix('.prompt.txt')
        with record.open('a', encoding='utf-8') as f:
            f.write('\n2026-10-17 authorized technical addition: rose/blonde edge RGB decontamination from local interior blonde donors; then python tools/art/despill.py. Content, alpha, size and position retained. Backup: ' + backup.relative_to(ROOT).as_posix() + '\n')
        rows = list(csv.DictReader((ROOT / 'art/manifest.csv').open(encoding='utf-8-sig')))
        row = next(r for r in rows if r['id'] == asset)
        change_row(asset, {'notes': row['notes'] + '; 2026-10-17 사용자 허락 기술 후처리: 금발 분홍 가장자리 decontamination→despill; 승인 상태 유지'})
    guide = (ROOT / 'art/style-guide.md').read_text(encoding='utf-8')
    style = re.search(r'## 2\. STYLE_BLOCK\s*```\s*(.*?)```', guide, re.S).group(1).strip()
    negative = re.search(r'## 5\. NEGATIVE_BLOCK\s*```\s*(.*?)```', guide, re.S).group(1).strip()
    chars = (ROOT / 'art/characters.md').read_text(encoding='utf-8').split('### C04 ')[1].split('### C05 ')[0]
    blocks = {k: re.search(r'- ' + k + r': `([^`]+)`', chars).group(1) for k in ('BODY', 'COMBAT', 'CASUAL')}
    formats = {}
    for kind in ('portrait', 'sd', 'cutin'):
        formats[kind] = re.search(r'\| `' + kind + r'` \|.*?\| `([^`]+)`', guide).group(1)
    expressions = {'smile': 'warm happy smile', 'angry': 'angry, frowning, gritted teeth', 'sad': 'sad, teary eyes', 'surprised': 'surprised, wide eyes, open mouth', 'embarrassed': 'embarrassed, blushing, looking away'}
    rows = list(csv.DictReader((ROOT / 'art/manifest.csv').open(encoding='utf-8-sig')))
    jobs = []
    for row in rows:
        if row['step'] != 'S12' or row['subject'] != 'C04' or row['status'] != 'todo':
            continue
        asset, kind = row['id'], row['format']
        if kind == 'icon':
            continue
        face = row['extra'].startswith('EDIT')
        if face:
            base = BASE + f'C04_portrait_{row["outfit"]}_neutral.png'
            refs = [base, CREF, HREF, STYLE]
            expression = expressions[asset.rsplit('_', 1)[1]]
            extra = (f'Edit target is image 1. Edit only the masked face area (eyebrows, eyes, cheeks and mouth). Keep everything outside the mask pixel-identical. Change the facial expression to: {expression}. '
                     'Retain the exact face position, head angle, jaw contour, skin tone, eye color and beauty mark under her own LEFT eye (viewer-right). Do not move or repaint the hair, veil, ears, neck, body, outfit, hands, props or background. '
                     'The edit will be composited through a face-interior-only mask over image 1; therefore precise alignment of every facial feature with the base is essential. Output the same complete 1024x1536 canvas, not a close-up. Preserve transparency.')
            roles = 'Image 1 is the neutral portrait EDIT TARGET, authoritative face identity and geometry. Images 2 and 3 are approved Miriam identity references only. Image 4 is Lina: STYLE ONLY, never copy her face, hair, colors, clothes or accessories.'
        elif kind == 'portrait':
            refs = [HREF, COMBAT, CREF, STYLE]
            extra = (row['extra'] + ' Closed-mouth calm knowing half-smile, no strong emotion. Create ONE NEW casual standing portrait, no collage or reference sheet. '
                     'Use the approved CASUAL reference design: hair down, ivory off-shoulder linen dress, open back where naturally visible, side slit, thin gold waist chain, wooden holy-symbol necklace. '
                     'No veil, no cloak, no staff, no armor, no travel boots, no combat accessories. Barefoot character, with knee-up framing. Body only slightly angled, eyes at viewer, both hands inside canvas, small top margin. Preserve Miriam\'s mature face rather than another companion\'s face.')
            roles = 'Image 1: APPROVED CASUAL outfit, hair, face and body reference. Image 2: APPROVED face identity anchor; combat clothes, staff and veil are forbidden in this casual image. Image 3: face/hair/body only; do not transfer combat clothing, props or silhouette. Image 4 is Lina: STYLE AND DRAWING SCALE ONLY, never copy her face, hair, colors or outfit.'
        else:
            refs = [IDLE, COMBAT, CREF, HREF, STYLE]
            extra = row['extra']
            roles = 'Image 1: APPROVED Miriam SD design/proportions and combat outfit. Image 2: APPROVED authoritative Miriam face identity. Image 3: APPROVED combat outfit/staff reference. Image 4: face, hair and body identity ONLY, never transfer the casual outfit. Image 5 is Lina: STYLE ONLY, do not copy her face, colors, outfit, weapons or accessories.'
            if kind == 'sd':
                extra += ' One full-body sprite, about 2.5 heads tall, facing RIGHT in three-quarter view, same costume and staff as approved idle. Whole silhouette, hands, staff and both feet inside canvas; no mirroring, no ground shadow, no text or separate effects.'
                if asset.endswith('_attack'):
                    extra += ' Swing her wooden pilgrim staff forward to the right in a dynamic close-range staff strike, a clear attacking silhouette.'
                elif asset.endswith('_skill'):
                    extra += ' Hold her pilgrim staff in one hand while extending the other open hand in a gentle healing/blessing gesture; warm light confined to her palm.'
                elif asset.endswith('_hit'):
                    extra += 'Recoil backward while still facing right and gripping her staff, visibly wincing.'
                else:
                    extra += ' Kneel low, exhausted with lowered shoulders, keep the staff close alongside the body and its tip at the same bottom baseline as her feet/knees.'
            else:
                extra += ' Wide cinematic 3:1 composition, compose the face and praying hands in the central horizontal band that survives a centered 3:1 crop. Close-up Miriam, eyes peacefully lowered in prayer, warm golden-white holy pillar and speed lines. Opaque painted background, NOT magenta. No UI, icons or lettering. Keep recognizable white veil, cream cloak, shell badge, wooden holy-symbol necklace and grey-blue dress.'
        fmt = formats[kind]
        if kind in ('portrait', 'sd'):
            fmt = fmt.replace('plain flat solid #FF00FF magenta background', 'genuinely transparent background (if a background is required, use plain flat solid #FF00FF magenta)')
        dimensions = '1024x1536' if kind == 'portrait' else '1024x1024' if kind == 'sd' else '1536x1024, composed for a central 3:1 crop'
        prompt = (f'Use case: {"identity-preserve" if face else "stylized-concept"}\nAsset: {asset}. ONE finished game asset. Target canvas {dimensions}.\n\n' +
                  '\n\n'.join([style, fmt, blocks['BODY'], blocks[row['outfit'].upper()], extra, 'Input image roles (attachment order): ' + roles,
                  'Identity priority: approved C04_portrait_combat_neutral, approved Miriam references, and Miriam FACE specification. Her face is soft, rounded and mature; gentle drooping sky-blue eyes with long lashes; beauty mark beneath her own LEFT eye (viewer-right in front view); full soft lips; warm peach skin; tall graceful curvy figure. Her primary colors are ivory and golden blonde. No generic youthful pointed chin.', negative]))
        job = dict(id=asset, kind=kind, face=face, refs=refs, prompt=prompt, transparent=kind in ('portrait', 'sd'))
        (SESSION / (asset + '.txt')).write_text(prompt, encoding='utf-8')
        jobs.append(job)
    (SESSION / 'jobs.json').write_text(json.dumps(jobs, ensure_ascii=False), encoding='utf-8')
    print('Prepared', len(jobs), 'single-call jobs')


def finish(asset, source, face):
    job = next(j for j in json.loads((SESSION / 'jobs.json').read_text(encoding='utf-8')) if j['id'] == asset)
    rows = list(csv.DictReader((ROOT / 'art/manifest.csv').open(encoding='utf-8-sig')))
    row = next(r for r in rows if r['id'] == asset)
    if row['step'] != 'S12' or row['status'] != 'todo':
        raise ValueError('Only remaining S12 todo rows are authorized for generation')
    for ref in job['refs']:
        if not (ROOT / ref).is_file():
            raise FileNotFoundError(ref)
    versions = [int(m.group(1)) for p in (ROOT / 'art/raw').glob(asset + '_v*.png') if (m := re.search(r'_v(\d+)\.png$', p.name))]
    raw = ROOT / f'art/raw/{asset}_v{max(versions, default=0)+1}.png'
    shutil.copy2(source, raw)
    output = ROOT / row['output']
    if output.exists():
        raise FileExistsError(output)
    im = Image.open(raw).convert('RGBA')
    source_size = im.size
    if job['kind'] == 'portrait':
        im = im.resize((1024, 1536), Image.Resampling.LANCZOS)
        if job['face']:
            if not face:
                raise ValueError('Face polygon is required')
            base = Image.open(ROOT / job['refs'][0]).convert('RGBA')
            mask = Image.new('L', base.size)
            ImageDraw.Draw(mask).polygon([tuple(map(int, pair.split(','))) for pair in face.split(';')], fill=255)
            mask = Image.fromarray(np.minimum(np.array(mask), np.array(mask.filter(ImageFilter.GaussianBlur(2)))))
            im.putalpha(base.getchannel('A'))
            im = Image.composite(im, base, mask)
        else:
            im = normalize_alpha(key(im))
    elif job['kind'] == 'sd':
        im = normalize_alpha(key(im))
        im = im.crop(im.getbbox())
        im.thumbnail((464, 464), Image.Resampling.LANCZOS)
        im = normalize_alpha(im)
        im = im.crop(im.getbbox())
        canvas = Image.new('RGBA', (512, 512))
        canvas.paste(im, ((512 - im.width)//2, 488 - im.height))
        im = canvas
    else:
        im = ImageOps.fit(im.convert('RGB'), (1920, 640), Image.Resampling.LANCZOS)
    im.save(output)
    if job['transparent']:
        cleanup(output)
        if job['face']:
            # Neutral already received the same authorized edge cleanup. Keep its
            # exact outside-mask RGBA rather than accumulating another edge pass.
            cleaned = np.array(Image.open(output).convert('RGBA'))
            original = np.array(base)
            cleaned[np.array(mask) == 0] = original[np.array(mask) == 0]
            cleaned[..., 3] = original[..., 3]
            Image.fromarray(cleaned).save(output)
    record = (f'Asset: {asset}\nModel/tool: built-in image_gen.imagegen (underlying model ID not exposed)\nGeneration date: 2026-10-17 Asia/Seoul\n'
              f'Exactly one generation call, no regeneration or art-content self-review.\nRaw: {raw.relative_to(ROOT).as_posix()}\nOutput: {row["output"]}\n'
              f'Actual source size: {source_size}\nFinal size: {im.size}\n'
              'Postprocessing: technical canvas/alpha normalization only; transparent assets: magenta removal where needed, blonde rose-edge RGB decontamination using local interior blonde donors, then python tools/art/despill.py. SD lower baseline y=487, centered without mirroring. Cutin: central 3:1 crop, 1920x640 RGB.\n'
              f'Face mask polygon (inward feather only): {face or "none"}\n'
              'For expression variants, only face-mask RGB is composited over neutral; alpha and pixels outside face are retained. No comparison sheets or QA scripts.\n\nReferences (attachment order):\n' +
              '\n'.join(job['refs']) + '\n\nFull prompt:\n' + job['prompt'] + '\n')
    output.with_suffix('.prompt.txt').write_text(record, encoding='utf-8')
    change_row(asset, {'status': 'generated', 'refs': ';'.join(job['refs']), 'notes': row['notes'] + '; 2026-10-17 S12 내장 image_gen 1회; 얼굴 마스크 합성' if job['face'] else row['notes'] + '; 2026-10-17 S12 내장 image_gen 1회; 기술 후처리 완료'})
    print(f'{asset}: generated -> {row["output"]}')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['prepare', 'finish', 'complete'])
    parser.add_argument('--id')
    parser.add_argument('--source')
    parser.add_argument('--face')
    args = parser.parse_args()
    if args.action == 'prepare':
        prepare()
    elif args.action == 'finish':
        finish(args.id, args.source, args.face)
    else:
        rows = [r for r in csv.DictReader((ROOT / 'art/manifest.csv').open(encoding='utf-8-sig'))
                if r['step'] == 'S12' and r['subject'] == 'C04' and r['format'] in ('portrait', 'sd', 'cutin')]
        unfinished = [r for r in rows if r['status'] not in ('generated', 'approved')]
        if len(rows) != 18 or any(r['status'] != 'todo' or '생성 도구 출력 안전 필터 차단' not in r['notes'] for r in unfinished):
            raise RuntimeError('S12 still has unfinished character rows')
        path = ROOT / 'art/steps/README.md'
        text = re.sub(r'(\| \[S12\]\(S12.md\).*\| )[^|\r\n]+( \|)', r'\g<1>검토 대기\2', path.read_text(encoding='utf-8'))
        path.write_text(text, encoding='utf-8')
        print(f'S12 검토 대기; 미생성 {len(unfinished)}장; stop before S13')
