# -*- mode: python ; coding: utf-8 -*-

import glob
from pathlib import Path

block_cipher = None

# Collect data files (QSS, optional GIF, config, resources)
datas = []
for f in glob.glob(str(Path('chaoxing') / 'gui' / 'assets' / '*.*')):
    datas.append((f, str(Path('gui') / 'assets')))
for f in glob.glob(str(Path('chaoxing') / 'resource' / '*.json')):
    datas.append((f, 'resource'))
cfg = Path('chaoxing') / 'config_template.ini'
if cfg.exists():
    datas.append((str(cfg), '.'))

hiddenimports = [
    'api',
    'api.logger',
    'api.base',
    'api.answer',
    'api.config',
    'api.cookies',
    'api.decode',
    'api.exceptions',
    'api.process',
    'api.notification',
    'api.captcha',
    'api.cipher',
    'api.font_decoder',
    'api.cxsecret_font',
]

a = Analysis(
    ['chaoxing\\run_gui.py'],
    pathex=['.', 'chaoxing'],
    binaries=[],
    datas=datas,
    hiddenimports=hiddenimports,
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)
pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name='ChaoxingGUI',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)

coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,
    strip=False,
    upx=True,
    upx_exclude=[],
    name='ChaoxingGUI'
)


