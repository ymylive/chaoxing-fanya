import sys
from pathlib import Path

from PySide6.QtCore import Qt, QSize, QThread, Signal, QObject, QEasingCurve, QPropertyAnimation, QTimer, QParallelAnimationGroup, QSequentialAnimationGroup, QRect
from PySide6.QtGui import QAction, QIcon, QMovie, QColor, QPixmap, QPainter, QBrush, QLinearGradient
from PySide6.QtWidgets import (
    QApplication,
    QMainWindow,
    QWidget,
    QVBoxLayout,
    QHBoxLayout,
    QLabel,
    QLineEdit,
    QPushButton,
    QSpinBox,
    QDoubleSpinBox,
    QComboBox,
    QListWidget,
    QListWidgetItem,
    QTextEdit,
    QFileDialog,
    QSplitter,
    QGroupBox,
    QMessageBox,
    QGraphicsDropShadowEffect,
    QGraphicsOpacityEffect,
    QFrame,
    QCheckBox,
)

try:
    from api.logger import logger as app_file_logger
except Exception:
    app_file_logger = None

class AnimatedButton(QPushButton):
    """按钮点击动画效果"""
    def __init__(self, text: str, parent=None):
        super().__init__(text, parent)
        self._scale_anim = None
        
    def mousePressEvent(self, event):
        self._animate_press()
        super().mousePressEvent(event)
        
    def mouseReleaseEvent(self, event):
        self._animate_release()
        super().mouseReleaseEvent(event)
        
    def _animate_press(self):
        self._scale_anim = QPropertyAnimation(self, b"geometry", self)
        start_rect = self.geometry()
        end_rect = QRect(
            start_rect.x() + 2, start_rect.y() + 2,
            start_rect.width() - 4, start_rect.height() - 4
        )
        self._scale_anim.setDuration(100)
        self._scale_anim.setStartValue(start_rect)
        self._scale_anim.setEndValue(end_rect)
        self._scale_anim.setEasingCurve(QEasingCurve.OutCubic)
        self._scale_anim.start()
        
    def _animate_release(self):
        if self._scale_anim:
            self._scale_anim.stop()
        self._scale_anim = QPropertyAnimation(self, b"geometry", self)
        current_rect = self.geometry()
        end_rect = QRect(
            current_rect.x() - 2, current_rect.y() - 2,
            current_rect.width() + 4, current_rect.height() + 4
        )
        self._scale_anim.setDuration(150)
        self._scale_anim.setStartValue(current_rect)
        self._scale_anim.setEndValue(end_rect)
        self._scale_anim.setEasingCurve(QEasingCurve.OutElastic)
        self._scale_anim.start()


class AnimatedListItem(QListWidgetItem):
    """列表项悬停动画"""
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
        file_menu = menubar.addMenu("文件")
        open_action = QAction("打开配置(config.ini)", self)
        open_action.triggered.connect(self._open_config)
        file_menu.addAction(open_action)

        save_action = QAction("保存配置", self)
        save_action.triggered.connect(self._save_config)
        file_menu.addAction(save_action)

        exit_action = QAction("退出", self)
        exit_action.triggered.connect(self.close)
        file_menu.addAction(exit_action)

        help_menu = menubar.addMenu("帮助")
        about_action = QAction("关于", self)
        about_action.triggered.connect(self._about)
        help_menu.addAction(about_action)

    def _build_ui(self) -> None:
        container = QWidget()
        root_layout = QVBoxLayout(container)

        # Header bar
        header = QWidget()
        header.setObjectName("HeaderBar")
        header_layout = QHBoxLayout(header)
        header_layout.setContentsMargins(12, 8, 12, 8)
        title = QLabel("Chaoxing 学习助手")
        title.setObjectName("HeaderTitle")
        header_layout.addWidget(title)
        header_layout.addStretch(1)
        # Busy indicator (movie)
        self.busy = QLabel()
        self.busy.setVisible(False)
        header_layout.addWidget(self.busy)

        # Drop shadow for header
        shadow = QGraphicsDropShadowEffect(self)
        shadow.setBlurRadius(16)
        shadow.setXOffset(0)
        shadow.setYOffset(2)
        shadow.setColor(Qt.black)
        header.setGraphicsEffect(shadow)

        # Body
        body = QWidget()
        body_layout = QHBoxLayout(body)

        # Left: configuration group
        left_panel = QWidget()
        left_layout = QVBoxLayout(left_panel)
        left_layout.setSpacing(4)  # 进一步减小垂直间距
        left_layout.setContentsMargins(6, 6, 6, 6)  # 进一步减小内边距

        # 账号登录区域
        self.username_edit = QLineEdit()
        self.username_edit.setPlaceholderText("📱 请输入手机号码")
        self.password_edit = QLineEdit()
        self.password_edit.setEchoMode(QLineEdit.Password)
        self.password_edit.setPlaceholderText("🔐 请输入登录密码")
        
        # 记住我选项
        self.remember_checkbox = QCheckBox("记住登录信息")
        self.remember_checkbox.setStyleSheet("margin-top: 2px; margin-bottom: 2px;")
        
        self.login_btn = AnimatedButton("🚀 登录并获取课程")
        self.login_btn.setMinimumHeight(24)  # 进一步减小按钮高度
        self.login_btn.clicked.connect(self._on_login_clicked)
        
        # 添加到主布局
        left_layout.addWidget(self.username_edit)
        left_layout.addWidget(self.password_edit)
        left_layout.addWidget(self.remember_checkbox)
        left_layout.addWidget(self.login_btn)
        left_layout.addSpacing(6)  # 分隔间距

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
        left_layout.addSpacing(6)  # 分隔间距

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
        self.tiku_cover.setSuffix("%")
        
        self.tiku_delay = QDoubleSpinBox()
        self.tiku_delay.setRange(0.0, 10.0)
        self.tiku_delay.setSingleStep(0.5)
        self.tiku_delay.setValue(1.0)
        self.tiku_delay.setPrefix("⏱️ ")
        self.tiku_delay.setSuffix("s")
        
        self.tiku_tokens = QLineEdit()
        self.tiku_tokens.setPlaceholderText("🔑 请输入题库TOKEN，多个请用英文逗号分隔")
        
        # 添加到主布局
        left_layout.addWidget(self.tiku_provider)
        left_layout.addWidget(self.tiku_submit)
        left_layout.addWidget(self.tiku_cover)
        left_layout.addWidget(self.tiku_delay)
        left_layout.addWidget(self.tiku_tokens)
        left_layout.addSpacing(6)  # 分隔间距

        # Advanced settings container with animated expand/collapse
        self.advanced_container = QWidget()
        adv_layout = QVBoxLayout(self.advanced_container)
        adv_layout.setSpacing(4)
        adv_layout.setContentsMargins(0, 0, 0, 0)
        
        self.proxy_edit = QLineEdit()
        self.proxy_edit.setPlaceholderText("🌐 登录网络代理，如：http://127.0.0.1:7890")
        
        proxy_note = QLabel("💡 仅对登录过程生效，留空则直连")
        proxy_note.setStyleSheet("font-size: 11px; color: #6b7280; font-style: italic;")
        
        # 添加组件
        adv_layout.addWidget(self.proxy_edit)
        adv_layout.addWidget(proxy_note)
        self.advanced_container.setVisible(False)
        left_layout.addWidget(self.advanced_container)
        
        # 添加一些间距
        left_layout.addSpacing(2)
        
        self.toggle_adv_btn = AnimatedButton("🔽 显示高级设置")
        self.toggle_adv_btn.setObjectName("Secondary")
        self.toggle_adv_btn.setMinimumHeight(22)  # 进一步减小按钮高度
        self.toggle_adv_btn.clicked.connect(self._toggle_advanced)
        left_layout.addWidget(self.toggle_adv_btn)
        left_layout.addStretch(1)

        # Right: courses + logs
        right_splitter = QSplitter(Qt.Vertical)

        # 课程区域容器
        courses_container = QWidget()
        courses_layout = QVBoxLayout(courses_container)
        courses_layout.setSpacing(4)
        courses_layout.setContentsMargins(4, 4, 4, 4)
        
        # 状态栏
        status_bar = QWidget()
        status_layout = QHBoxLayout(status_bar)
        status_layout.setContentsMargins(0, 0, 0, 0)
        self.course_status = QLabel("📊 请先登录获取课程")
        self.course_status.setStyleSheet("font-weight: 500; color: #6b7280;")
        status_layout.addWidget(self.course_status)
        status_layout.addStretch()
        
        self.refresh_courses_btn = AnimatedButton("🔄 刷新课程")
        self.refresh_courses_btn.setObjectName("Secondary") 
        self.refresh_courses_btn.setMinimumHeight(20)  # 进一步减小按钮高度
        self.refresh_courses_btn.clicked.connect(self._fetch_courses)
        status_layout.addWidget(self.refresh_courses_btn)
        
        courses_layout.addWidget(status_bar)
        
        self.course_list = QListWidget()
        self.course_list.setAlternatingRowColors(True)
        courses_layout.addWidget(self.course_list)

        # 改进的控制按钮
        control_row = QWidget()
        control_layout = QHBoxLayout(control_row)
        control_layout.setSpacing(12)
        control_layout.setContentsMargins(0, 8, 0, 0)  # 顶部增加一些间距
        
        self.start_btn = AnimatedButton("🎯 开始学习")
        self.start_btn.setMinimumHeight(26)  # 进一步减小按钮高度
        self.stop_btn = AnimatedButton("⏹️ 停止")
        self.stop_btn.setMinimumHeight(26)  # 进一步减小按钮高度
        self.stop_btn.setObjectName("Secondary")
        self.stop_btn.setEnabled(False)
        
        self.start_btn.clicked.connect(self._start_run)
        self.stop_btn.clicked.connect(self._stop_run)
        
        control_layout.addWidget(self.start_btn, 2)
        control_layout.addWidget(self.stop_btn, 1)
        courses_layout.addWidget(control_row)

        # 日志区域容器
        log_container = QWidget()
        log_layout = QVBoxLayout(log_container)
        log_layout.setSpacing(4)
        log_layout.setContentsMargins(4, 4, 4, 4)
        
        # 日志工具栏
        log_toolbar = QWidget()
        log_toolbar_layout = QHBoxLayout(log_toolbar)
        log_toolbar_layout.setContentsMargins(0, 0, 0, 0)
        
        log_status = QLabel("📍 实时显示运行状态")
        log_status.setStyleSheet("font-weight: 500; color: #6b7280; font-size: 12px;")
        log_toolbar_layout.addWidget(log_status)
        log_toolbar_layout.addStretch()
        
        clear_log_btn = AnimatedButton("🗑️ 清空")
        clear_log_btn.setObjectName("Secondary")
        clear_log_btn.setMinimumHeight(18)  # 进一步减小按钮高度
        clear_log_btn.clicked.connect(self._clear_logs)
        log_toolbar_layout.addWidget(clear_log_btn)
        
        log_layout.addWidget(log_toolbar)
        
        self.log_view = QTextEdit()
        self.log_view.setReadOnly(True)
        self.log_view.setPlaceholderText("🚀 准备就绪，等待操作...")
        log_layout.addWidget(self.log_view)

        # Toast overlay (hidden by default)
        self.toast = QLabel("")
        self.toast.setObjectName("Toast")
        self.toast.setAlignment(Qt.AlignCenter)
        self.toast.setVisible(False)

        right_splitter.addWidget(courses_container)
        right_splitter.addWidget(log_container)
        right_splitter.setSizes([400, 300])

        body_layout.addWidget(left_panel, 0)
        body_layout.addWidget(right_splitter, 1)

        root_layout.addWidget(header)
        root_layout.addWidget(body, 1)
        root_layout.addWidget(self.toast, 0, Qt.AlignHCenter)
        self.setCentralWidget(container)

        # Load theme
        self._load_theme()
        # Apply card shadows (removed as we no longer have group boxes)

    # ===== Menu Actions =====
    def _open_config(self) -> None:
        path, _ = QFileDialog.getOpenFileName(self, "选择配置文件", str(Path.cwd()), "INI Files (*.ini)")
        if not path:
            return
        self._load_config(Path(path))

    def _save_config(self) -> None:
        try:
            from configparser import ConfigParser
            cfg = ConfigParser()
            cfg["common"] = {
                "username": self.username_edit.text().strip(),
                "password": self.password_edit.text().strip(),
                "course_list": ",".join(self._selected_course_ids()),
                "speed": str(self.speed_spin.value()),
                "notopen_action": self.notopen_combo.currentText(),
            }
            cfg["tiku"] = {
                "provider": self.tiku_provider.currentText(),
                "submit": self.tiku_submit.currentText(),
                "cover_rate": str(self.tiku_cover.value()),
                "delay": str(self.tiku_delay.value()),
                "tokens": self.tiku_tokens.text().strip(),
            }
            # Save to project root config.ini
            target = getattr(self, "_config_path", None)
            if not target:
                target = Path(__file__).resolve().parents[1] / "config.ini"
            else:
                target = Path(target)
            with target.open("w", encoding="utf8") as fp:
                cfg.write(fp)
            QMessageBox.information(self, "保存成功", f"已保存到: {target}")
        except Exception as e:
            QMessageBox.critical(self, "保存失败", str(e))

    def _about(self) -> None:
        QMessageBox.information(self, "关于", "Chaoxing 学习助手 GUI\n基于现有 CLI 工作流封装")

    # ===== Business Logic Placeholders =====
    def _load_config(self, path: Path) -> None:
        try:
            from configparser import ConfigParser
            cfg = ConfigParser()
            cfg.read(path, encoding="utf8")
            self._config_path = str(path)
            if cfg.has_section("common"):
                self.username_edit.setText(cfg.get("common", "username", fallback=""))
                self.password_edit.setText(cfg.get("common", "password", fallback=""))
                speed = cfg.getfloat("common", "speed", fallback=1.0)
                self.speed_spin.setValue(max(1.0, min(2.0, speed)))
                self.notopen_combo.setCurrentText(cfg.get("common", "notopen_action", fallback="retry"))
            if cfg.has_section("tiku"):
                self.tiku_provider.setCurrentText(cfg.get("tiku", "provider", fallback=""))
                self.tiku_submit.setCurrentText(cfg.get("tiku", "submit", fallback="false"))
                self.tiku_cover.setValue(cfg.getfloat("tiku", "cover_rate", fallback=0.9))
                self.tiku_delay.setValue(cfg.getfloat("tiku", "delay", fallback=1.0))
                self.tiku_tokens.setText(cfg.get("tiku", "tokens", fallback=""))
        except Exception as e:
            QMessageBox.critical(self, "读取失败", str(e))

    def _on_login_clicked(self) -> None:
        # Run real login + fetch courses in background
        username = self.username_edit.text().strip()
        password = self.password_edit.text().strip()
        if not username or not password:
            QMessageBox.warning(self, "提示", "请先填写手机号和密码")
            return
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

    def _fetch_courses(self) -> None:
        # Re-run login to refresh courses with current credentials
        self._on_login_clicked()

    def _selected_course_ids(self) -> list[str]:
        ids = []
        for i in range(self.course_list.count()):
            item = self.course_list.item(i)
            if item.checkState() == Qt.Checked:
                data = item.data(Qt.UserRole)
                if isinstance(data, dict) and "courseId" in data:
                    ids.append(data["courseId"])
                else:
                    ids.append(data)
        return ids

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
        if self._run_worker and self._run_worker.isRunning():
            self._run_worker.request_stop()
            self._append_log("已请求停止，将在当前课程结束后停止...")
        else:
            self._append_log("无正在运行的任务")

    def _append_log(self, text: str) -> None:
        self.log_view.append(text)

    # ===== Log Integration =====
    def _install_log_sink(self) -> None:
        try:
            from api.logger import logger as app_logger

            def sink(message):
                try:
                    record = getattr(message, "record", None)
                    text = record.get("message", "") if record else str(message)
                except Exception:
                    text = str(message)
                if text:
                    LogBus.instance().message.emit(text.rstrip())

            self._log_sink_id = app_logger.add(sink, level="INFO")
            LogBus.instance().message.connect(self._append_log)
        except Exception:
            pass

    # ===== Worker Callbacks =====
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
            # 错开添加动画
            QTimer.singleShot(i * 50, lambda item=item: self._animate_item_in(item))
            
        # Fade in courses panel (removed as we no longer have group boxes)
        self._show_toast(f"✨ 已加载 {len(self._all_courses)} 门课程", 1200)

    def _on_login_failed(self, msg: str) -> None:
        QMessageBox.critical(self, "登录失败", msg)
        self._append_log(f"登录失败: {msg}")
        self._show_toast("登录失败")

    def _on_run_finished(self) -> None:
        self.stop_btn.setEnabled(False)
        self.start_btn.setText("🎯 开始学习")
        QMessageBox.information(self, "🎉 任务完成", "所有课程学习任务已完成！")
        self._append_log("🏆 所有课程学习任务已完成")
        self._show_toast("🎉 学习完成", 2000)

    def _on_run_failed(self, msg: str) -> None:
        self.stop_btn.setEnabled(False)
        self.start_btn.setText("🎯 开始学习")
        QMessageBox.critical(self, "⚠️ 运行失败", f"任务执行失败：{msg}")
        self._append_log(f"❌ 运行失败: {msg}")
        self._show_toast("❌ 运行失败", 2000)

    # ===== Theming & Busy =====
    def _load_theme(self) -> None:
        try:
            # 优先加载高级主题
            theme_path = Path(__file__).resolve().parent / "assets" / "theme_advanced.qss"
            if not theme_path.exists():
                theme_path = Path(__file__).resolve().parent / "assets" / "theme.qss"
            
            if theme_path.exists():
                with theme_path.open("r", encoding="utf8") as f:
                    self.setStyleSheet(f.read())
                    
            # busy indicator gif (fallback to animated text)
            spinner_path = Path(__file__).resolve().parent / "assets" / "spinner.gif"
            if spinner_path.exists():
                movie = QMovie(str(spinner_path))
                self.busy.setMovie(movie)
                movie.start()
            else:
                self.busy.setObjectName("BusyIndicator")
                self.busy.setText("⚡")
                # 添加旋转动画
                self._setup_busy_animation()
        except Exception:
            pass
            
    def _setup_busy_animation(self):
        """设置忙碌指示器的旋转动画"""
        self._busy_anim = QPropertyAnimation(self.busy, b"rotation", self)
        self._busy_anim.setDuration(1000)
        self._busy_anim.setStartValue(0)
        self._busy_anim.setEndValue(360)
        self._busy_anim.setLoopCount(-1)  # 无限循环
        
    def _clear_logs(self):
        """清空日志"""
        self.log_view.clear()
        self._append_log("📝 日志已清空")

    def _set_busy(self, busy: bool) -> None:
        self.busy.setVisible(busy)

    def _toggle_advanced(self) -> None:
        show = not self.advanced_container.isVisible()
        self.advanced_container.setVisible(True)  # ensure widget exists to animate
        start_h = self.advanced_container.height() if show else self.advanced_container.sizeHint().height()
        end_h = self.advanced_container.sizeHint().height() if show else 0
        
        # 高度动画
        height_anim = QPropertyAnimation(self.advanced_container, b"maximumHeight", self)
        height_anim.setDuration(280)
        height_anim.setStartValue(start_h)
        height_anim.setEndValue(end_h)
        height_anim.setEasingCurve(QEasingCurve.OutCubic)
        
        # 透明度动画
        opacity_effect = QGraphicsOpacityEffect()
        self.advanced_container.setGraphicsEffect(opacity_effect)
        opacity_anim = QPropertyAnimation(opacity_effect, b"opacity", self)
        opacity_anim.setDuration(280)
        opacity_anim.setStartValue(0.0 if show else 1.0)
        opacity_anim.setEndValue(1.0 if show else 0.0)
        opacity_anim.setEasingCurve(QEasingCurve.OutCubic)
        
        # 组合动画
        self._toggle_anim_group = QParallelAnimationGroup()
        self._toggle_anim_group.addAnimation(height_anim)
        self._toggle_anim_group.addAnimation(opacity_anim)
        
        def on_finished():
            self.advanced_container.setVisible(show)
            self.advanced_container.setMaximumHeight(16777215 if show else 0)
            
        self._toggle_anim_group.finished.connect(on_finished)
        self._toggle_anim_group.start()
        
        # 更新按钮文本和图标
        icon = "🔼" if show else "🔽"
        text = "隐藏高级设置" if show else "显示高级设置"
        self.toggle_adv_btn.setText(f"{icon} {text}")

    def _show_toast(self, text: str, duration_ms: int = 1600) -> None:
        self.toast.setText(text)
        self.toast.setVisible(True)
        self.toast.setWindowOpacity(0.0)
        fade_in = QPropertyAnimation(self.toast, b"windowOpacity", self)
        fade_in.setDuration(180)
        fade_in.setStartValue(0.0)
        fade_in.setEndValue(1.0)
        fade_in.setEasingCurve(QEasingCurve.OutCubic)
        def after_in():
            fade_out = QPropertyAnimation(self.toast, b"windowOpacity", self)
            fade_out.setDuration(260)
            fade_out.setStartValue(1.0)
            fade_out.setEndValue(0.0)
            fade_out.setEasingCurve(QEasingCurve.OutCubic)
            fade_out.finished.connect(lambda: self.toast.setVisible(False))
            fade_out.start()
            self._last_fade = fade_out
        fade_in.finished.connect(lambda: self.startTimer(duration_ms, Qt.VeryCoarseTimer) or after_in())
        fade_in.start()
        self._last_fade = fade_in

    def _apply_card_shadow(self, widget: QWidget) -> None:
        eff = QGraphicsDropShadowEffect(self)
        eff.setBlurRadius(24)
        eff.setXOffset(0)
        eff.setYOffset(8)
        eff.setColor(QColor(0, 0, 0, 28))
        widget.setGraphicsEffect(eff)

    def _fade_in(self, widget: QWidget, duration: int = 200) -> None:
        eff = QGraphicsOpacityEffect(widget)
        widget.setGraphicsEffect(eff)
        eff.setOpacity(0.0)
        anim = QPropertyAnimation(eff, b"opacity", self)
        anim.setDuration(duration)
        anim.setStartValue(0.0)
        anim.setEndValue(1.0)
        anim.setEasingCurve(QEasingCurve.OutCubic)
        anim.start()
        self._last_opacity_anim = anim

    def _pulse_widget(self, widget: QWidget) -> None:
        eff = QGraphicsDropShadowEffect(self)
        eff.setBlurRadius(10)
        eff.setXOffset(0)
        eff.setYOffset(4)
        eff.setColor(QColor(0, 122, 255, 120))
        widget.setGraphicsEffect(eff)
        anim = QPropertyAnimation(eff, b"blurRadius", self)
        anim.setDuration(360)
        anim.setStartValue(6)
        anim.setEndValue(22)
        anim.setEasingCurve(QEasingCurve.OutCubic)
        anim.finished.connect(lambda: eff.setEnabled(False))
        anim.start()
        self._last_pulse = anim
        
    def _animate_item_in(self, item: QListWidgetItem) -> None:
        """列表项淡入动画"""
        if not item or not self.course_list:
            return
        # 简单的透明度动画效果
        widget = self.course_list.itemWidget(item)
        if widget:
            self._fade_in(widget, 180)


class LogBus(QObject):
    message = Signal(str)

    _instance = None

    @classmethod
    def instance(cls):
        if cls._instance is None:
            cls._instance = LogBus()
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


