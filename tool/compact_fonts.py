#!/usr/bin/env python3
"""Compact EB Garamond into one variable font, retaining all characters.

Uses the existing fonttools build utility; no application dependency is added.
Usage: python tool/compact_fonts.py EBGaramond-VariableFont_wght.ttf
"""
import argparse
from hashlib import sha256
import json
from pathlib import Path

from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont

ROOT = Path(__file__).resolve().parent.parent
FONTS = ROOT / 'assets/fonts'
SOURCE_SHA256 = '4bd3007d4483df0767a89b209ef2a94eb2a997546b95553a48db4629a286d9b1'


def compact(source):
    if sha256(source.read_bytes()).hexdigest() != SOURCE_SHA256:
        raise ValueError('Unexpected EB Garamond source checksum')
    font = TTFont(source, recalcTimestamp=False)
    characters = set(font.getBestCmap())
    # Preserve the original app's actual weight range. Requests above 700
    # clamp to 700 as they did with the former static font files.
    instantiateVariableFont(font, {'wght': (400, 400, 700)}, inplace=True)
    names = {1: 'Nya EB Garamond', 2: 'Regular', 3: 'NyaEBGaramond-Compact-1',
             4: 'Nya EB Garamond Regular', 6: 'NyaEBGaramond-Regular',
             16: 'Nya EB Garamond', 17: 'Regular'}
    for record in font['name'].names:
        if record.nameID in names:
            record.string = names[record.nameID].encode(record.getEncoding())
    output = FONTS / 'EBGaramond-Variable.ttf'
    font.save(output)
    if set(TTFont(output).getBestCmap()) != characters:
        raise ValueError('Character coverage changed')
    info = {'EBGaramond': {
        'source': 'https://github.com/google/fonts/tree/main/ofl/ebgaramond',
        'source_sha256': SOURCE_SHA256, 'weight_range': [400, 700],
        'characters': len(characters), 'bytes': output.stat().st_size,
        'sha256': sha256(output.read_bytes()).hexdigest(),
    }}
    (FONTS / 'font-sources.json').write_text(json.dumps(info, indent=2) + '\n')
    print(f'{output.name}: {output.stat().st_size:,} bytes, {len(characters)} characters')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path)
    compact(parser.parse_args().source)
