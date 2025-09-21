from loguru import logger
import sys
from pathlib import Path

# 统一格式，输出到文件与控制台（GUI 仍有自己的 sink）
LOG_FORMAT = "{time:YYYY-MM-DD HH:mm:ss.SSS} | {level:<8} | {name}:{function}:{line} - {message}"

logger.remove()

# 写入到当前工作目录（root）
logger.add(
    Path.cwd() / "chaoxing.log",
    rotation="5 MB",
    level="TRACE",
    enqueue=False,  # 关闭异步，确保即时落盘
    backtrace=True,
    diagnose=False,
    format=LOG_FORMAT,
)

# 同时写入到包根目录（chaoxing/chaoxing.log），防止工作目录差异导致空日志
_pkg_root = Path(__file__).resolve().parents[1]
logger.add(
    _pkg_root / "chaoxing.log",
    rotation="5 MB",
    level="TRACE",
    enqueue=False,
    backtrace=True,
    diagnose=False,
    format=LOG_FORMAT,
)

# 控制台输出 INFO+
logger.add(
    sys.stdout,
    level="INFO",
    enqueue=False,
    backtrace=False,
    diagnose=False,
    format=LOG_FORMAT,
)
