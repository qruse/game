"""S10R technical finishing and face-only compositing; no visual QA."""
import argparse
import csv
import io
import re
import shutil
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageOps

from despill import despill

ROOT = Path(__file__).resolve().parents[2]


def key(im):
    a = np.array(im.convert('RGBA'))
    r, g, b = [a[..., i].astype(float) for i in range(3)]
    chroma = np.minimum(r, b) - g
    magenta = (r > 100) & (b > 100) & (chroma > 55)
    coverage = np.clip((160 - chroma) / 105, 0, 1)
    a[..., 3] = np.where(magenta, np.minimum(a[..., 3], coverage * 255), a[..., 3]).astype('uint8')
    alpha = Image.fromarray(a[..., 3])
    interior = np.array(alpha.filter(ImageFilter.MinFilter(3))) >= 245
    a[interior, 3] = 255
    a[a[..., 3] == 0, :3] = 0
    return Image.fromarray(a)


def main():
    p = argparse.ArgumentParser()
    p.add_argument('id')
    p.add_argument('source')
    p.add_argument('--face', help='semicolon-separated x,y polygon vertices')
    args = p.parse_args()
    manifest = ROOT / 'art/manifest.csv'
    text = manifest.read_text(encoding='utf-8-sig')
    rows = list(csv.DictReader(io.StringIO(text)))
    row = next(r for r in rows if r['id'] == args.id)
    if row['status'] != 'todo' or row['subject'] != 'C02':
        raise RuntimeError('Only the authorized todo C02 row may be replaced')
    refsfile = ROOT / 'art/raw/S10R_cecile_session' / (args.id + '.refs.txt')
    refs = refsfile.read_text(encoding='utf-8').splitlines()
    for ref in refs:
        if not (ROOT / ref).is_file():
            raise FileNotFoundError(ref)
    versions = [int(m.group(1)) for f in (ROOT / 'art/raw').glob(args.id + '_v*.png') if (m := re.search(r'_v(\d+)\.png$', f.name))]
    raw = ROOT / 'art/raw' / f'{args.id}_v{max(versions, default=0) + 1}.png'
    shutil.copy2(args.source, raw)
    output = ROOT / row['output']
    im = Image.open(raw).convert('RGBA')
    kind = row['format']
    if kind == 'portrait':
        im = key(im.resize((1024, 1536), Image.Resampling.LANCZOS))
    elif kind == 'sd':
        im = key(im)
        im = im.crop(im.getbbox())
        im.thumbnail((464, 464), Image.Resampling.LANCZOS)
        canvas = Image.new('RGBA', (512, 512))
        canvas.paste(im, ((512 - im.width) // 2, 488 - im.height))
        im = canvas
    elif kind == 'cutin':
        im = ImageOps.fit(im.convert('RGB'), (1920, 640), Image.Resampling.LANCZOS)
    elif kind == 'cg':
        im = ImageOps.fit(im.convert('RGB'), (1920, 1080), Image.Resampling.LANCZOS)
    output.parent.mkdir(parents=True, exist_ok=True)
    im.save(output)
    if kind in ('portrait', 'sd'):
        despill(str(output))
    processing = 'Technical canvas sizing; '
    if args.face:
        basepath = ROOT / row['output'].replace('_' + args.id.rsplit('_', 1)[1] + '.png', '_neutral.png')
        base = Image.open(basepath).convert('RGBA')
        edited = Image.open(output).convert('RGBA')
        mask = Image.new('L', base.size)
        points = [tuple(map(int, pair.split(','))) for pair in args.face.split(';')]
        ImageDraw.Draw(mask).polygon(points, fill=255)
        # Feather inward only, preserving every pixel outside the chosen face area.
        mask = Image.fromarray(np.minimum(np.array(mask), np.array(mask.filter(ImageFilter.GaussianBlur(2)))))
        edited.putalpha(base.getchannel('A'))
        Image.composite(edited, base, mask).save(output)
        processing += 'face interior mask composited over neutral, original pixels retained outside face; edited source magenta removal and despill.py before compositing. '
    elif kind in ('portrait', 'sd'):
        processing += 'magenta removal, opaque interior/antialiased alpha, tools/art/despill.py. '
    if kind == 'sd':
        processing += '512x512, visible lower baseline y=487, centered without mirroring. '
    prompt = (refsfile.parent / (args.id + '.txt')).read_text(encoding='utf-8')
    record = ('Tool/model: built-in image_gen (underlying model ID not exposed)\n'
              'Generation date: 2026-10-16 Asia/Seoul\n'
              'Step: S10R, Cecile only; one generation, no retries or art-content self-review\n'
              'References in attachment order:\n' + '\n'.join(f'{i+1}. {v}' for i, v in enumerate(refs)) +
              f'\nRaw source: {raw.relative_to(ROOT).as_posix()}\nFinal: {row["output"]}\n'
              f'Postprocessing: {processing}\nFace mask polygon: {args.face or "none"}\n\nFULL PROMPT\n{prompt}\n')
    output.with_suffix('.prompt.txt').write_text(record, encoding='utf-8')
    oldline = next(line for line in text.splitlines() if line.startswith(args.id + ',') or line.startswith('"' + args.id + '",'))
    row['status'] = 'generated'
    row['refs'] = ';'.join(refs)
    row['notes'] += f'; 2026-10-16 S10R 세실 전용: 내장 image_gen 1회·재생성0; raw={raw.relative_to(ROOT).as_posix()}; 전체 prompt·참조 기록; 기술 후처리 완료; 그림 자체 검수·비교 시트·QA 스크립트 없음; 사용자·Claude 검토 대기'
    buf = io.StringIO(newline='')
    csv.DictWriter(buf, fieldnames=list(row), lineterminator='').writerow(row)
    # Preserve all unrelated rows byte-for-byte at the text level.
    manifest.write_text(text.replace(oldline, buf.getvalue(), 1), encoding='utf-8', newline='')
    print(f'{args.id}: generated; {im.size[0]}x{im.size[1]}; {raw.relative_to(ROOT).as_posix()} -> {row["output"]}')


if __name__ == '__main__':
    main()
