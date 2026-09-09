#!/usr/bin/env python3
"""Run the real modules outside Studio, adapting only static Instance require paths."""
import argparse
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser()
p.add_argument('--luau',required=True)
p.add_argument('--analyzer')
a=p.parse_args()
with tempfile.TemporaryDirectory(prefix='hoops-data-check-') as directory:
    temp=Path(directory)
    # The Roblox-dependent shop presentation catalog has its own check_shop.py.
    paths=[p for p in (ROOT/'src/shared').rglob('*.luau') if p.name != 'ShopCatalog.luau']+list((ROOT/'src/ServerScriptService/Config').glob('*.luau'))
    translated=[]
    for source in paths:
        relative=source.relative_to(ROOT)
        target=temp/relative;target.parent.mkdir(parents=True,exist_ok=True)
        def rewrite(match):
            resolved=source
            for token in match[1].split('.')[1:]:
                resolved=resolved.parent if token=='Parent' else resolved/token
            import os
            require_path=os.path.relpath(resolved,source.parent)
            if not require_path.startswith('.'):require_path='./'+require_path
            return f'require("{require_path}")'
        content=re.sub(r'require\((script(?:\.[A-Za-z0-9_]+)+)\)',rewrite,source.read_text())
        assert 'require(script.' not in content
        target.write_text(content);translated.append(str(target))
    test=temp/'tests/player_database.spec.luau';test.parent.mkdir()
    shutil.copyfile(ROOT/'tests/player_database.spec.luau',test)
    if a.analyzer:
        result=subprocess.run([a.analyzer,'--mode=strict',*translated,str(test)])
        if result.returncode: raise SystemExit(result.returncode)
    subprocess.run([a.luau,str(test)],check=True)
