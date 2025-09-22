# Python Environment Cleanup Tool (PowerShell Version)
# 清理Python环境和相关缓存文件

param(
    [switch]$Force,  # 强制删除，不询问确认
    [switch]$Verbose # 详细输出
)

# Set console encoding
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Write-Status {
    param($Message, $Type = "Info")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    switch ($Type) {
        "Success" { Write-Host "[$timestamp] ✓ $Message" -ForegroundColor Green }
        "Warning" { Write-Host "[$timestamp] ⚠ $Message" -ForegroundColor Yellow }
        "Error"   { Write-Host "[$timestamp] ✗ $Message" -ForegroundColor Red }
        "Info"    { Write-Host "[$timestamp] $Message" -ForegroundColor Cyan }
    }
}

function Remove-DirectoryIfExists {
    param($Path, $Description)
    if (Test-Path $Path) {
        try {
            Remove-Item -Path $Path -Recurse -Force -ErrorAction Stop
            Write-Status "Removed $Description" "Success"
            return $true
        }
        catch {
            Write-Status "Failed to remove $Description`: $($_.Exception.Message)" "Error"
            return $false
        }
    }
    else {
        Write-Status "No $Description found" "Success"
        return $true
    }
}

function Remove-FileIfExists {
    param($Path, $Description)
    if (Test-Path $Path) {
        try {
            Remove-Item -Path $Path -Force -ErrorAction Stop
            Write-Status "Removed $Description" "Success"
            return $true
        }
        catch {
            Write-Status "Failed to remove $Description`: $($_.Exception.Message)" "Error"
            return $false
        }
    }
    else {
        Write-Status "No $Description found" "Success"
        return $true
    }
}

# Header
Write-Host "================================================" -ForegroundColor Magenta
Write-Host "      Python Environment Cleanup Tool" -ForegroundColor Magenta
Write-Host "================================================" -ForegroundColor Magenta
Write-Host ""

if (-not $Force) {
    $confirmation = Read-Host "This will clean all Python environments and caches. Continue? (y/N)"
    if ($confirmation -notmatch '^[Yy]') {
        Write-Host "Cleanup cancelled." -ForegroundColor Yellow
        exit 0
    }
}

Write-Status "Starting Python environment cleanup..."
Write-Host ""

# 1. Clean project virtual environment
Write-Host "[1/6] Cleaning project virtual environment..." -ForegroundColor Yellow
$venvPath = Join-Path $env:USERPROFILE "chaoxing_venv"
Remove-DirectoryIfExists $venvPath "virtual environment ($venvPath)"

# 2. Clean installation logs
Write-Host ""
Write-Host "[2/6] Cleaning installation logs..." -ForegroundColor Yellow
$logFiles = @(
    @{Path = Join-Path $env:USERPROFILE "chaoxing_install.log"; Name = "chaoxing_install.log"},
    @{Path = Join-Path $env:USERPROFILE "chaoxing_post_install.log"; Name = "chaoxing_post_install.log"},
    @{Path = Join-Path $env:USERPROFILE "python_auto_install.log"; Name = "python_auto_install.log"},
    @{Path = Join-Path $env:USERPROFILE "python_debug.log"; Name = "python_debug.log"}
)

$logsCleaned = 0
foreach ($log in $logFiles) {
    if (Remove-FileIfExists $log.Path $log.Name) {
        if (Test-Path $log.Path -ErrorAction SilentlyContinue) {
            # File existed and was processed
        } else {
            $logsCleaned++
        }
    }
}

if ($logsCleaned -eq 0) {
    Write-Status "No log files were found to clean" "Success"
} else {
    Write-Status "Cleaned $logsCleaned log files" "Success"
}

# 3. Clean saved credentials
Write-Host ""
Write-Host "[3/6] Cleaning saved credentials..." -ForegroundColor Yellow
$credentialsPath = Join-Path $env:USERPROFILE ".chaoxing_gui"
Remove-DirectoryIfExists $credentialsPath "saved login credentials"

# 4. Clean pip cache
Write-Host ""
Write-Host "[4/6] Cleaning pip cache..." -ForegroundColor Yellow
try {
    $pipResult = & pip cache purge 2>$null
    Write-Status "pip cache purged successfully" "Success"
}
catch {
    Write-Status "pip cache purge failed (pip may not be available)" "Warning"
}

# Manual pip cache cleanup
$pipCachePath = Join-Path $env:LOCALAPPDATA "pip\cache"
Remove-DirectoryIfExists $pipCachePath "manual pip cache"

# 5. Clean Python compiled cache
Write-Host ""
Write-Host "[5/6] Cleaning Python compiled cache..." -ForegroundColor Yellow

# Remove __pycache__ directories
try {
    $pycacheDirs = Get-ChildItem -Path . -Recurse -Directory -Name "__pycache__" -ErrorAction SilentlyContinue
    if ($pycacheDirs.Count -gt 0) {
        Write-Status "Found $($pycacheDirs.Count) __pycache__ directories, removing..." "Info"
        Get-ChildItem -Path . -Recurse -Directory -Name "__pycache__" | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        Write-Status "__pycache__ directories removed" "Success"
    } else {
        Write-Status "No __pycache__ directories found" "Success"
    }
}
catch {
    Write-Status "Error cleaning __pycache__ directories: $($_.Exception.Message)" "Error"
}

# Remove .pyc files
try {
    $pycFiles = Get-ChildItem -Path . -Recurse -Filter "*.pyc" -ErrorAction SilentlyContinue
    if ($pycFiles.Count -gt 0) {
        Write-Status "Found $($pycFiles.Count) .pyc files, removing..." "Info"
        $pycFiles | Remove-Item -Force -ErrorAction SilentlyContinue
        Write-Status ".pyc files removed" "Success"
    } else {
        Write-Status "No .pyc files found" "Success"
    }
}
catch {
    Write-Status "Error cleaning .pyc files: $($_.Exception.Message)" "Error"
}

# 6. Clean temporary files
Write-Host ""
Write-Host "[6/6] Cleaning temporary files..." -ForegroundColor Yellow
try {
    $pipTempDirs = Get-ChildItem -Path $env:TEMP -Directory -Filter "pip-*" -ErrorAction SilentlyContinue
    if ($pipTempDirs.Count -gt 0) {
        Write-Status "Removing $($pipTempDirs.Count) pip temporary directories..." "Info"
        $pipTempDirs | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        Write-Status "pip temporary files cleaned" "Success"
    } else {
        Write-Status "No pip temporary files found" "Success"
    }
}
catch {
    Write-Status "Error cleaning temporary files: $($_.Exception.Message)" "Error"
}

# Summary
Write-Host ""
Write-Host "================================================" -ForegroundColor Green
Write-Host "              Cleanup Summary" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Status "Virtual environment cleaned" "Success"
Write-Status "Installation logs cleaned" "Success"
Write-Status "Saved credentials cleaned" "Success"
Write-Status "pip cache cleaned" "Success"
Write-Status "Python compiled cache cleaned" "Success"
Write-Status "Temporary files cleaned" "Success"
Write-Host ""
Write-Status "Python environment cleanup completed!" "Success"
Write-Host ""
Write-Host "Note: You may need to reinstall dependencies next time you run the application." -ForegroundColor Yellow
Write-Host ""

if (-not $Force) {
    Read-Host "Press Enter to continue..."
}



