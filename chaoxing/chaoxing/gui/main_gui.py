#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Chaoxing GUI Main Window - 修复版本

这是修复了记住登录功能的完整GUI文件
"""

import sys
import os
from pathlib import Path
from typing import Dict, List, Optional, Union
from PySide6.QtWidgets import (
    QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout, 
    QLineEdit, QPushButton, QListWidget, QListWidgetItem, QLabel,
    QComboBox, QDoubleSpinBox, QSpinBox, QCheckBox, QTextEdit,
    QMessageBox, QMenuBar, QFileDialog, QSplitter,
    QGraphicsOpacityEffect, QProgressBar
)
from PySide6.QtCore import (
    Qt, QThread, Signal, QPropertyAnimation, QEasingCurve, 
    QRect, QTimer, QObject, QSize
)
from PySide6.QtGui import QFont, QPalette, QColor, QIcon

# 全局日志
app_file_logger = None
try:
    from api.logger import logger as app_file_logger
except Exception:
    pass

class AnimatedButton(QPushButton):
    def __init__(self, text: str, parent=None):
        super().__init__(text, parent)
        self._animation = None

class AnimatedListItem(QListWidgetItem):
    def __init__(self, text: str, parent=None):
        super().__init__(text, parent)
        self._opacity_effect = None

class MainWindow(QMainWindow):
    def __init__(self) -> None:
        super().__init__()
        self.setWindowTitle("Chaoxing 学习助手 (GUI)")
        self.setMinimumSize(QSize(1100, 700))

        self._build_menu()
        self._build_ui()
        self._install_log_sink()

        # runtime state
        self._all_courses = []
        self._login_worker = None
        self._run_worker = None
        
        # 加载保存的登录信息
        self._load_saved_credentials()

    def _build_tiku_conf(self) -> dict:
        # 规范化来自UI的题库配置，映射为后端所需格式
        provider_label = self.tiku_provider.currentText().strip()
        provider_mapping = {
            "🏪 无": "",
            "🏪 TikuYanxi": "TikuYanxi",
            "🏪 TikuLike": "TikuLike",
            "🏪 TikuAdapter": "TikuAdapter",
            "🏪 AI": "AI",
            "🏪 SiliconFlow": "SiliconFlow",
        }
        provider = provider_mapping.get(provider_label, "")

        submit_label = self.tiku_submit.currentText().strip()
        submit_mapping = {
            "📤 只保存": "false",
            "📤 提交": "true",
        }
        submit_value = submit_mapping.get(submit_label, "false")

        # Ensure required keys for Tiku.init_tiku
        tiku_conf = {
            "provider": provider,
            "submit": submit_value,
            "cover_rate": str(self.tiku_cover.value()),
            "delay": str(self.tiku_delay.value()),
            "tokens": self.tiku_tokens.text().strip(),
            # defaults aligned with config_template.ini
            "true_list": "正确,对,√,是",
            "false_list": "错误,错,×,否,不对,不正确",
            # 传递代理给可能用到的题库（如AI）
            "http_proxy": self.proxy_edit.text().strip() or "",
        }
        return tiku_conf

    def _build_menu(self) -> None:
        menubar = self.menuBar()
        
        # File menu
        file_menu = menubar.addMenu("文件(&F)")
        
        load_config_action = file_menu.addAction("📂 加载配置文件...")
        load_config_action.triggered.connect(self._load_config_dialog)
        
        file_menu.addSeparator()
        
        exit_action = file_menu.addAction("❌ 退出")
        exit_action.triggered.connect(self.close)

    def _build_ui(self) -> None:
        container = QWidget()
        self.setCentralWidget(container)
        
        # 主布局 - 水平分割
        main_layout = QHBoxLayout(container)
        splitter = QSplitter(Qt.Horizontal)
        main_layout.addWidget(splitter)

        # 左侧控制面板
        left_panel = QWidget()
        left_layout = QVBoxLayout(left_panel)
        left_layout.setContentsMargins(8, 8, 8, 8)
        left_layout.setSpacing(4)

        # 账号登录区域
        self.username_edit = QLineEdit()
        self.username_edit.setPlaceholderText("📱 请输入手机号码")
        self.password_edit = QLineEdit()
        self.password_edit.setEchoMode(QLineEdit.Password)
        self.password_edit.setPlaceholderText("🔐 请输入登录密码")
        
        # 记住我选项
        self.remember_checkbox = QCheckBox("记住登录信息")
        self.remember_checkbox.setStyleSheet("margin-top: 2px; margin-bottom: 2px;")
        self.remember_checkbox.stateChanged.connect(self._on_remember_changed)
        
        self.login_btn = AnimatedButton("🚀 登录并获取课程")
        self.login_btn.setMinimumHeight(24)
        self.login_btn.clicked.connect(self._on_login_clicked)
        
        # 添加到主布局
        left_layout.addWidget(self.username_edit)
        left_layout.addWidget(self.password_edit)
        left_layout.addWidget(self.remember_checkbox)
        left_layout.addWidget(self.login_btn)
        left_layout.addSpacing(6)

        # 运行设置区域
        self.speed_spin = QDoubleSpinBox()
        self.speed_spin.setRange(1.0, 2.0)
        self.speed_spin.setSingleStep(0.1)
        self.speed_spin.setValue(1.0)
        self.speed_spin.setPrefix("⚡ ")
        self.speed_spin.setSuffix("x")
        
        self.notopen_combo = QComboBox()
        self.notopen_combo.addItems(["🔁 重试", "❓ 询问", "➡️ 继续"])
        
        # 添加到主布局
        left_layout.addWidget(self.speed_spin)
        left_layout.addWidget(self.notopen_combo)
        left_layout.addSpacing(6)

        # 题库设置区域
        self.tiku_provider = QComboBox()
        self.tiku_provider.addItems(["🏪 无", "🏪 TikuYanxi", "🏪 TikuLike", "🏪 TikuAdapter", "🏪 AI", "🏪 SiliconFlow"])
        
        self.tiku_submit = QComboBox()
        self.tiku_submit.addItems(["📤 只保存", "📤 提交"])
        
        self.tiku_cover = QDoubleSpinBox()
        self.tiku_cover.setRange(0.0, 1.0)
        self.tiku_cover.setSingleStep(0.05)
        self.tiku_cover.setValue(0.9)
        self.tiku_cover.setPrefix("📊 ")
        
        self.tiku_delay = QDoubleSpinBox()
        self.tiku_delay.setRange(0.5, 10.0)
        self.tiku_delay.setSingleStep(0.5)
        self.tiku_delay.setValue(1.0)
        self.tiku_delay.setPrefix("⏱️ ")
        self.tiku_delay.setSuffix("s")
        
        self.tiku_tokens = QLineEdit()
        self.tiku_tokens.setPlaceholderText("🔑 API密钥 (可选)")
        
        # 添加到主布局
        left_layout.addWidget(self.tiku_provider)
        left_layout.addWidget(self.tiku_submit)
        left_layout.addWidget(self.tiku_cover)
        left_layout.addWidget(self.tiku_delay)
        left_layout.addWidget(self.tiku_tokens)
        left_layout.addSpacing(6)

        # 代理设置
        self.proxy_edit = QLineEdit()
        self.proxy_edit.setPlaceholderText("🌐 HTTP代理 (可选)")
        left_layout.addWidget(self.proxy_edit)
        left_layout.addSpacing(6)

        # 控制按钮
        self.start_btn = AnimatedButton("🎯 开始学习")
        self.start_btn.clicked.connect(self._start_run)
        self.start_btn.setEnabled(False)
        
        self.stop_btn = QPushButton("⏹️ 停止")
        self.stop_btn.clicked.connect(self._stop_run)
        self.stop_btn.setEnabled(False)
        
        left_layout.addWidget(self.start_btn)
        left_layout.addWidget(self.stop_btn)
        left_layout.addStretch()

        # 右侧面板
        right_panel = QWidget()
        right_layout = QVBoxLayout(right_panel)
        
        # 课程列表
        self.course_status = QLabel("🔍 请先登录获取课程列表")
        self.course_status.setStyleSheet("font-weight: 500; color: #6b7280;")
        right_layout.addWidget(self.course_status)
        
        self.course_list = QListWidget()
        self.course_list.setMinimumHeight(200)
        right_layout.addWidget(self.course_list)
        
        # 日志输出
        log_label = QLabel("📋 运行日志")
        log_label.setStyleSheet("font-weight: 500; margin-top: 8px;")
        right_layout.addWidget(log_label)
        
        self.log_output = QTextEdit()
        self.log_output.setMaximumHeight(200)
        self.log_output.setReadOnly(True)
        right_layout.addWidget(self.log_output)

        # 添加面板到分割器
        splitter.addWidget(left_panel)
        splitter.addWidget(right_panel)
        splitter.setSizes([300, 800])

    def _install_log_sink(self) -> None:
        """安装日志接收器"""
        try:
            log_bus = LogBus.instance()
            log_bus.message_received.connect(self._append_log)
        except Exception:
            pass

    def _append_log(self, message: str) -> None:
        """添加日志消息"""
        try:
            self.log_output.append(message)
            # 自动滚动到底部
            scrollbar = self.log_output.verticalScrollBar()
            scrollbar.setValue(scrollbar.maximum())
        except Exception:
            pass

    # ===== 配置相关 =====
    
    def _load_config_dialog(self) -> None:
        file_path, _ = QFileDialog.getOpenFileName(
            self, "选择配置文件", "", "INI files (*.ini);;All files (*)"
        )
        if file_path:
            self._load_config(Path(file_path))

    def _load_config(self, path: Path) -> None:
        try:
            import configparser
            cfg = configparser.ConfigParser()
            cfg.read(path, encoding='utf-8')
            
            # 加载配置到UI
            if cfg.has_section("common"):
                self.speed_spin.setValue(cfg.getfloat("common", "speed", fallback=1.0))
                self.proxy_edit.setText(cfg.get("common", "http_proxy", fallback=""))
                
            if cfg.has_section("tiku"):
                provider = cfg.get("tiku", "provider", fallback="")
                for i in range(self.tiku_provider.count()):
                    if provider in self.tiku_provider.itemText(i):
                        self.tiku_provider.setCurrentIndex(i)
                        break
                        
                submit = cfg.get("tiku", "submit", fallback="false")
                if submit.lower() == "true":
                    self.tiku_submit.setCurrentIndex(1)
                else:
                    self.tiku_submit.setCurrentIndex(0)
                    
                self.tiku_cover.setValue(cfg.getfloat("tiku", "cover_rate", fallback=0.9))
                self.tiku_delay.setValue(cfg.getfloat("tiku", "delay", fallback=1.0))
                self.tiku_tokens.setText(cfg.get("tiku", "tokens", fallback=""))
        except Exception as e:
            QMessageBox.critical(self, "读取失败", str(e))

    # ===== 登录相关 =====
    
    def _on_login_clicked(self) -> None:
        # Run real login + fetch courses in background
        username = self.username_edit.text().strip()
        password = self.password_edit.text().strip()
        if not username or not password:
            QMessageBox.warning(self, "提示", "请先填写手机号和密码")
            return
            
        # 如果勾选了记住登录信息，保存凭据
        if self.remember_checkbox.isChecked():
            self._save_credentials(username, password)
            
        if app_file_logger:
            try:
                masked = f"{username[:3]}****{username[-2:]}" if len(username) >= 5 else "***"
                app_file_logger.info(f"GUI: 登录按钮点击, user={masked}, proxy={(self.proxy_edit.text().strip() or 'none')}")
            except Exception:
                pass
        self.login_btn.setEnabled(False)
        self._append_log("准备登录...")
        self._set_busy(True)
        # Build minimal tiku config from UI (optional)
        tiku_conf = self._build_tiku_conf()
        self._login_worker = LoginWorker(username, password, tiku_conf)
        # propagate optional proxy string
        self._login_worker.http_proxy = self.proxy_edit.text().strip() or None
        self._login_worker.success.connect(self._on_login_success)
        self._login_worker.error.connect(self._on_login_failed)
        self._login_worker.finished.connect(lambda: (self.login_btn.setEnabled(True), self._set_busy(False)))
        self._login_worker.start()

    def _set_busy(self, busy: bool) -> None:
        """设置忙碌状态"""
        # 这里可以添加忙碌指示器
        pass

    # ===== 运行相关 =====
    
    def _start_run(self) -> None:
        # Start main workflow in background using existing logic
        username = self.username_edit.text().strip()
        password = self.password_edit.text().strip()
        if not username or not password:
            QMessageBox.warning(self, "提示", "请先登录或填写账号密码")
            return
        if not self._all_courses:
            QMessageBox.warning(self, "提示", "请先获取课程列表")
            return
        # Build selected courses payload (full dicts)
        selected = []
        for i in range(self.course_list.count()):
            item = self.course_list.item(i)
            if item.checkState() == Qt.Checked:
                data = item.data(Qt.UserRole)
                if isinstance(data, dict):
                    selected.append(data)
        if not selected:
            QMessageBox.information(self, "提示", "请至少选择一个课程")
            return
        self.start_btn.setEnabled(False)
        self.start_btn.setText("🔄 学习中...")
        self.stop_btn.setEnabled(True)
        self._append_log("🚀 开始执行学习流程...")
        self._set_busy(True)
        tiku_conf = self._build_tiku_conf()
        self._run_worker = RunWorker(
            username=username,
            password=password,
            courses=selected,
            speed=float(self.speed_spin.value()),
            notopen_action=self.notopen_combo.currentText().strip(),
            tiku_conf=tiku_conf,
        )
        # propagate optional proxy to background worker as well（备用；RunWorker 内部未使用则忽略）
        self._run_worker.http_proxy = self.proxy_edit.text().strip() or None
        self._run_worker.finished_ok.connect(self._on_run_finished)
        self._run_worker.error.connect(self._on_run_failed)
        self._run_worker.finished.connect(lambda: (self.start_btn.setEnabled(True), self._set_busy(False)))
        self._run_worker.start()

    def _stop_run(self) -> None:
        # Best-effort stop between courses
        if self._run_worker:
            self._run_worker.request_stop()
            self._append_log("🛑 正在停止学习流程...")

    # ===== 回调函数 =====
    
    def _on_login_success(self, courses: list) -> None:
        self._append_log("🎉 登录成功，已获取课程列表")
        self._all_courses = courses or []
        self.course_list.clear()
        
        if not self._all_courses:
            self.course_status.setText("⚠️ 未找到可用课程")
            self.course_status.setStyleSheet("font-weight: 500; color: #f59e0b;")
            return
            
        # 更新状态
        self.course_status.setText(f"✅ 已加载 {len(self._all_courses)} 门课程")
        self.course_status.setStyleSheet("font-weight: 500; color: #10b981;")
        
        # 添加课程项目
        for i, course in enumerate(self._all_courses):
            title = course.get("title", "未命名课程")
            cid = course.get("courseId", "-")
            item = AnimatedListItem(f"📖 {title} (ID: {cid})")
            item.setData(Qt.UserRole, course)
            item.setCheckState(Qt.Checked)
            self.course_list.addItem(item)
            
        self.start_btn.setEnabled(True)

    def _on_login_failed(self, msg: str) -> None:
        QMessageBox.critical(self, "登录失败", msg)
        self._append_log(f"登录失败: {msg}")

    def _on_run_finished(self) -> None:
        self.stop_btn.setEnabled(False)
        self.start_btn.setText("🎯 开始学习")
        QMessageBox.information(self, "🎉 任务完成", "所有课程学习任务已完成！")
        self._append_log("🏆 所有课程学习任务已完成")

    def _on_run_failed(self, msg: str) -> None:
        self.stop_btn.setEnabled(False)
        self.start_btn.setText("🎯 开始学习")
        QMessageBox.critical(self, "执行失败", msg)
        self._append_log(f"执行失败: {msg}")

    # ===== 登录记住功能 =====
    
    def _get_config_dir(self) -> Path:
        """获取配置目录"""
        import os
        config_dir = Path(os.path.expanduser("~")) / ".chaoxing_gui"
        config_dir.mkdir(exist_ok=True)
        return config_dir
    
    def _get_credentials_file(self) -> Path:
        """获取凭据文件路径"""
        return self._get_config_dir() / "credentials.json"
    
    def _save_credentials(self, username: str, password: str) -> None:
        """保存登录凭据"""
        try:
            import json
            import base64
            
            # 简单加密（base64编码）
            encoded_password = base64.b64encode(password.encode()).decode()
            
            credentials = {
                "username": username,
                "password": encoded_password,
                "remember": True
            }
            
            with open(self._get_credentials_file(), 'w', encoding='utf-8') as f:
                json.dump(credentials, f, indent=2)
                
            if app_file_logger:
                try:
                    masked = f"{username[:3]}****{username[-2:]}" if len(username) >= 5 else "***"
                    app_file_logger.info(f"GUI: 已保存登录凭据 user={masked}")
                except Exception:
                    pass
                    
        except Exception as e:
            if app_file_logger:
                try:
                    app_file_logger.warning(f"GUI: 保存凭据失败: {e}")
                except Exception:
                    pass
    
    def _load_saved_credentials(self) -> None:
        """加载保存的登录凭据"""
        try:
            import json
            import base64
            
            credentials_file = self._get_credentials_file()
            if not credentials_file.exists():
                return
                
            with open(credentials_file, 'r', encoding='utf-8') as f:
                credentials = json.load(f)
                
            if not credentials.get('remember', False):
                return
                
            username = credentials.get('username', '')
            encoded_password = credentials.get('password', '')
            
            if username and encoded_password:
                # 解码密码
                try:
                    password = base64.b64decode(encoded_password).decode()
                    
                    # 填充到UI
                    self.username_edit.setText(username)
                    self.password_edit.setText(password)
                    self.remember_checkbox.setChecked(True)
                    
                    if app_file_logger:
                        try:
                            masked = f"{username[:3]}****{username[-2:]}" if len(username) >= 5 else "***"
                            app_file_logger.info(f"GUI: 已加载保存的登录凭据 user={masked}")
                        except Exception:
                            pass
                            
                except Exception as e:
                    if app_file_logger:
                        try:
                            app_file_logger.warning(f"GUI: 解码保存的密码失败: {e}")
                        except Exception:
                            pass
                    
        except Exception as e:
            if app_file_logger:
                try:
                    app_file_logger.warning(f"GUI: 加载保存的凭据失败: {e}")
                except Exception:
                    pass
    
    def _on_remember_changed(self, state: int) -> None:
        """记住登录信息状态改变"""
        try:
            if state == 0:  # 取消勾选
                # 删除保存的凭据
                credentials_file = self._get_credentials_file()
                if credentials_file.exists():
                    credentials_file.unlink()
                    
                if app_file_logger:
                    try:
                        app_file_logger.info("GUI: 已删除保存的登录凭据")
                    except Exception:
                        pass
            else:  # 勾选
                # 如果当前有输入内容，立即保存
                username = self.username_edit.text().strip()
                password = self.password_edit.text().strip()
                if username and password:
                    self._save_credentials(username, password)
                    
        except Exception as e:
            if app_file_logger:
                try:
                    app_file_logger.warning(f"GUI: 处理记住状态改变失败: {e}")
                except Exception:
                    pass


# ===== 辅助类 =====

class LogBus(QObject):
    message_received = Signal(str)
    
    _instance = None
    
    @classmethod
    def instance(cls):
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance


class LoginWorker(QThread):
    success = Signal(list)
    error = Signal(str)

    def __init__(self, username: str, password: str, tiku_conf: dict | None = None) -> None:
        super().__init__()
        self.username = username
        self.password = password
        self.tiku_conf = tiku_conf or {}

    def run(self) -> None:
        try:
            if app_file_logger:
                try:
                    app_file_logger.trace("LoginWorker: start")
                except Exception:
                    pass
            from api.base import Chaoxing, Account
            from api.answer import Tiku
            # init tiku
            tiku = Tiku()
            try:
                if self.tiku_conf:
                    tiku.config_set(self.tiku_conf)
                tiku = tiku.get_tiku_from_config()
                tiku.init_tiku()
            except Exception as te:
                # 容错：题库配置异常则禁用题库，继续登录
                if app_file_logger:
                    try:
                        app_file_logger.warning(f"LoginWorker: tiku_init_failed -> {te}, disable tiku and continue")
                    except Exception:
                        pass
                try:
                    tiku.DISABLE = True
                except Exception:
                    pass

            chaoxing = Chaoxing(
                account=Account(self.username, self.password),
                tiku=tiku,
                http_proxy=getattr(self, "http_proxy", None),
            )
            state = chaoxing.login()
            if not state.get("status"):
                if app_file_logger:
                    try:
                        app_file_logger.warning(f"LoginWorker: login_failed -> {state}")
                    except Exception:
                        pass
                self.error.emit(state.get("msg", "登录失败"))
                return
            courses = chaoxing.get_course_list()
            
            # 验证课程数据质量
            if courses:
                invalid_courses = []
                for course in courses:
                    if not (course.get('courseId') and course.get('clazzId') and course.get('cpi')):
                        invalid_courses.append(course.get('title', 'Unknown'))
                
                if invalid_courses:
                    if app_file_logger:
                        try:
                            app_file_logger.warning(f"LoginWorker: 发现 {len(invalid_courses)} 个课程数据不完整: {invalid_courses}")
                        except Exception:
                            pass
                    
                    # 如果数据质量太差，尝试强制使用旧版API
                    if len(invalid_courses) > len(courses) * 0.5:  # 超过50%课程数据不完整
                        if app_file_logger:
                            try:
                                app_file_logger.info("LoginWorker: 课程数据质量差，尝试强制使用旧版API")
                            except Exception:
                                pass
                        courses = chaoxing.get_course_list(force_old_api=True)
            
            if app_file_logger:
                try:
                    app_file_logger.info(f"LoginWorker: courses_count={len(courses) if courses else 0}")
                except Exception:
                    pass
            self.success.emit(courses)
        except Exception as e:
            if app_file_logger:
                try:
                    app_file_logger.error(f"LoginWorker: exception -> {e}")
                except Exception:
                    pass
            self.error.emit(str(e))


class RunWorker(QThread):
    finished_ok = Signal()
    error = Signal(str)

    def __init__(
        self,
        username: str,
        password: str,
        courses: list,
        speed: float,
        notopen_action: str,
        tiku_conf: dict | None = None,
    ) -> None:
        super().__init__()
        self.username = username
        self.password = password
        self.courses = courses
        self.speed = max(1.0, min(2.0, float(speed)))
        self.notopen_action = notopen_action
        self.tiku_conf = tiku_conf or {}
        self._stop_requested = False

    def request_stop(self) -> None:
        self._stop_requested = True

    def run(self) -> None:
        try:
            from api.base import Chaoxing, Account
            from api.answer import Tiku
            from chaoxing.main import process_course

            # init tiku
            tiku = Tiku()
            try:
                if self.tiku_conf:
                    tiku.config_set(self.tiku_conf)
                tiku = tiku.get_tiku_from_config()
                tiku.init_tiku()
            except Exception as te:
                if app_file_logger:
                    try:
                        app_file_logger.warning(f"RunWorker: tiku_init_failed -> {te}, disable tiku and continue")
                    except Exception:
                        pass
                try:
                    tiku.DISABLE = True
                except Exception:
                    pass

            chaoxing = Chaoxing(
                account=Account(self.username, self.password),
                tiku=tiku,
                http_proxy=getattr(self, "http_proxy", None),
            )
            state = chaoxing.login()
            if not state.get("status"):
                self.error.emit(state.get("msg", "登录失败"))
                return

            # Iterate selected courses
            for course in self.courses:
                if self._stop_requested:
                    break
                process_course(chaoxing, course, self.notopen_action, self.speed)

            if self._stop_requested:
                self.error.emit("用户已停止")
            else:
                self.finished_ok.emit()

        except Exception as e:
            self.error.emit(str(e))


def run_gui() -> None:
    app = QApplication(sys.argv)
    win = MainWindow()
    win.show()
    sys.exit(app.exec())


if __name__ == "__main__":
    run_gui()
