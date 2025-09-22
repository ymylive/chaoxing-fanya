[Setup]
AppName=Chaoxing 学习助手
AppVersion=3.1.3
AppPublisher=Chaoxing Open Source
AppPublisherURL=https://github.com/Samueli924/chaoxing
AppId={{A1E3C88C-2B9F-4B3F-9E4E-9BB8C7D2C8B7}}
DefaultDirName=D:\Chaoxing
DefaultGroupName=Chaoxing
DisableDirPage=no
DisableProgramGroupPage=no
OutputDir=.
OutputBaseFilename=Chaoxing-Setup
Compression=lzma2
SolidCompression=yes
PrivilegesRequired=lowest
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "创建桌面快捷方式"; GroupDescription: "附加任务:"

[Files]
; 项目源码
Source: "..\chaoxing\*"; DestDir: "{app}\chaoxing"; Flags: recursesubdirs ignoreversion
; 启动脚本
Source: "..\run_gui.bat"; DestDir: "{app}"; Flags: ignoreversion
; 安装后自动创建虚拟环境并安装依赖
Source: "post_install.bat"; DestDir: "{app}"; Flags: ignoreversion
; Python 自动安装器
Source: "auto_install_python.bat"; DestDir: "{app}\installer"; Flags: ignoreversion
; 增强版进度显示安装脚本
Source: "..\install_with_progress.ps1"; DestDir: "{app}"; Flags: ignoreversion
; 安装后专用进度脚本
Source: "..\post_install_progress.ps1"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\Chaoxing 学习助手"; Filename: "{app}\run_gui.bat"; WorkingDir: "{app}"
Name: "{userdesktop}\Chaoxing 学习助手"; Filename: "{app}\run_gui.bat"; Tasks: desktopicon; WorkingDir: "{app}"

[Run]
; 安装后执行依赖安装（创建 .venv 并 pip 安装）
Filename: "{app}\\post_install.bat"; WorkingDir: "{app}"; Flags: shellexec waituntilterminated
; 可选：安装完成后立即运行
Filename: "{app}\run_gui.bat"; Description: "安装完成后运行 Chaoxing 学习助手"; Flags: nowait postinstall skipifsilent


