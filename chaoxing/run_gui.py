import sys
from pathlib import Path

# Ensure 'chaoxing' directory is on sys.path so 'api' and 'gui' imports work
_HERE = Path(__file__).resolve().parent
if str(_HERE) not in sys.path:
    sys.path.insert(0, str(_HERE))

from gui.main_gui import run_gui


if __name__ == "__main__":
    run_gui()


