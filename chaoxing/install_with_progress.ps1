# Enhanced Python Dependency Installation with Progress Display
# 增强版Python依赖安装脚本，带进度条和下载速率显示

param(
    [string]$PythonExe = "",
    [string]$RequirementsFile = "chaoxing\requirements.txt",
    [switch]$Verbose
)

# Set console encoding
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'Continue'

function Write-Progress-Header {
    param($Title)
    Write-Host ""
    Write-Host "===============================================================" -ForegroundColor Cyan
    Write-Host ("  {0}" -f $Title) -ForegroundColor White
    Write-Host "===============================================================" -ForegroundColor Cyan
}

function Install-Package-With-Progress {
    param(
        [string]$PackageName,
        [string]$PipCommand,
        [int]$Current = 1,
        [int]$Total = 1
    )
    
    Write-Host ""
    Write-Host "[$Current/$Total] Installing $PackageName..." -ForegroundColor Yellow
    
    # Create a progress bar
    $percentComplete = [math]::Round(($Current / $Total) * 100, 1)
    Write-Progress -Activity "Installing Python Packages" -Status "$PackageName ($percentComplete%)" -PercentComplete $percentComplete
    
    # Start timer for speed calculation
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    # Execute pip command with progress bar
    $process = Start-Process -FilePath $PythonExe -ArgumentList $PipCommand -NoNewWindow -PassThru -RedirectStandardOutput "pip_output.tmp" -RedirectStandardError "pip_error.tmp"
    
    # Monitor progress
    $lastSize = 0
    while (-not $process.HasExited) {
        Start-Sleep -Milliseconds 500
        
        # Try to get file size changes as a rough progress indicator
        if (Test-Path "pip_output.tmp") {
            $currentSize = (Get-Item "pip_output.tmp").Length
            if ($currentSize -gt $lastSize) {
                $speed = [math]::Round(($currentSize - $lastSize) / 1024, 2)  # KB/s
                Write-Host "  📦 Downloading... ${speed} KB/s" -ForegroundColor Green -NoNewline
                Write-Host "`r" -NoNewline
                $lastSize = $currentSize
            }
        }
    }
    
    $stopwatch.Stop()
    $process.WaitForExit()
    
    # Read output
    $output = ""
    $error = ""
    if (Test-Path "pip_output.tmp") {
        $output = Get-Content "pip_output.tmp" -Raw
        Remove-Item "pip_output.tmp" -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path "pip_error.tmp") {
        $error = Get-Content "pip_error.tmp" -Raw
        Remove-Item "pip_error.tmp" -Force -ErrorAction SilentlyContinue
    }
    
    $duration = $stopwatch.Elapsed.TotalSeconds
    
    if ($process.ExitCode -eq 0) {
        Write-Host "  ✓ $PackageName installed successfully (${duration}s)" -ForegroundColor Green
        if ($Verbose -and $output) {
            Write-Host "    Output: $($output.Trim())" -ForegroundColor Gray
        }
        return $true
    } else {
        Write-Host "  ✗ Failed to install $PackageName (${duration}s)" -ForegroundColor Red
        if ($error) {
            Write-Host "    Error: $($error.Trim())" -ForegroundColor Red
        }
        return $false
    }
}

function Install-Requirements-With-Progress {
    param(
        [string]$PythonExe,
        [string]$RequirementsFile
    )
    
    Write-Progress-Header "Installing Dependencies from Requirements"
    
    # Parse requirements file to count packages
    $packages = @()
    if (Test-Path $RequirementsFile) {
        $content = Get-Content $RequirementsFile
        foreach ($line in $content) {
            $line = $line.Trim()
            if ($line -and -not $line.StartsWith("#")) {
                $packages += $line.Split(">=")[0].Split("==")[0].Split(";")[0].Trim()
            }
        }
    }
    
    Write-Host "Found $($packages.Count) packages to install" -ForegroundColor Cyan
    
    # Install all at once first (faster)
    $pipArgs = @("-m", "pip", "install", "-r", $RequirementsFile, "--disable-pip-version-check", "--no-cache-dir", "--progress-bar", "on", "--verbose")
    $success = Install-Package-With-Progress -PackageName "All Requirements" -PipCommand $pipArgs -Current 1 -Total 1
    
    if (-not $success) {
        Write-Host ""
        Write-Host "Batch installation failed, trying individual packages..." -ForegroundColor Yellow
        Write-Progress-Header "Installing Core Dependencies Individually"
        
        # Core packages in order of importance
        $corePackages = @(
            "requests",
            "httpx", 
            "PySide6>=6.7.0",
            "pyaes",
            "beautifulsoup4",
            "lxml",
            "loguru",
            "pycryptodome",
            "openai",
            "urllib3"
        )
        
        $successCount = 0
        for ($i = 0; $i -lt $corePackages.Count; $i++) {
            $pkg = $corePackages[$i]
            $pipArgs = @("-m", "pip", "install", $pkg, "--disable-pip-version-check", "--no-cache-dir", "--progress-bar", "on", "--upgrade")
            
            if (Install-Package-With-Progress -PackageName $pkg -PipCommand $pipArgs -Current ($i + 1) -Total $corePackages.Count) {
                $successCount++
            }
        }
        
        Write-Host ""
        Write-Host "Individual installation completed: $successCount/$($corePackages.Count) packages installed" -ForegroundColor $(if ($successCount -eq $corePackages.Count) { "Green" } else { "Yellow" })
        return $successCount -eq $corePackages.Count
    }
    
    return $true
}

function Test-Critical-Modules {
    param([string]$PythonExe)
    
    Write-Progress-Header "Verifying Critical Modules"
    
    $criticalModules = @(
        @{Name="PySide6"; ImportName="PySide6"},
        @{Name="httpx"; ImportName="httpx"},
        @{Name="requests"; ImportName="requests"},
        @{Name="openai"; ImportName="openai"},
        @{Name="Crypto"; ImportName="Crypto"; Package="pycryptodome"}
    )
    
    $failedModules = @()
    
    for ($i = 0; $i -lt $criticalModules.Count; $i++) {
        $module = $criticalModules[$i]
        $percentComplete = [math]::Round((($i + 1) / $criticalModules.Count) * 100, 1)
        Write-Progress -Activity "Verifying Modules" -Status "Checking $($module.Name) ($percentComplete%)" -PercentComplete $percentComplete
        
        $testScript = "import $($module.ImportName); print('$($module.Name) OK')"
        $result = & $PythonExe -c $testScript 2>$null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✓ $($module.Name) is available" -ForegroundColor Green
        } else {
            Write-Host "  ✗ $($module.Name) is missing" -ForegroundColor Red
            $failedModules += $module
        }
    }
    
    # Reinstall failed modules
    if ($failedModules.Count -gt 0) {
        Write-Host ""
        Write-Host "Reinstalling $($failedModules.Count) missing modules..." -ForegroundColor Yellow
        
        for ($i = 0; $i -lt $failedModules.Count; $i++) {
            $module = $failedModules[$i]
            $packageName = if ($module.Package) { $module.Package } else { $module.Name }
            $pipArgs = @("-m", "pip", "install", $packageName, "--disable-pip-version-check", "--no-cache-dir", "--force-reinstall", "--progress-bar", "on")
            
            Install-Package-With-Progress -PackageName $module.Name -PipCommand $pipArgs -Current ($i + 1) -Total $failedModules.Count
        }
    }
    
    Write-Progress -Activity "Verifying Modules" -Completed
    return $failedModules.Count -eq 0
}

# Main execution
try {
    if (-not $PythonExe) {
        Write-Host "Error: Python executable path not provided" -ForegroundColor Red
        exit 1
    }
    
    if (-not (Test-Path $PythonExe)) {
        Write-Host "Error: Python executable not found: $PythonExe" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Enhanced Python Dependency Installation" -ForegroundColor Magenta
    Write-Host "Python: $PythonExe" -ForegroundColor Gray
    Write-Host "Requirements: $RequirementsFile" -ForegroundColor Gray
    Write-Host ""
    
    # Upgrade pip first
    Write-Progress-Header "Upgrading pip"
    $pipArgs = @("-m", "pip", "install", "--upgrade", "pip", "--disable-pip-version-check", "--no-cache-dir", "--progress-bar", "on")
    Install-Package-With-Progress -PackageName "pip" -PipCommand $pipArgs -Current 1 -Total 1
    
    # Install requirements
    $installSuccess = Install-Requirements-With-Progress -PythonExe $PythonExe -RequirementsFile $RequirementsFile
    
    # Verify critical modules
    $verifySuccess = Test-Critical-Modules -PythonExe $PythonExe
    
    # Summary
    Write-Host ""
    Write-Host "===============================================================" -ForegroundColor $(if ($installSuccess -and $verifySuccess) { "Green" } else { "Yellow" })
    $status = if ($installSuccess -and $verifySuccess) { "Installation Completed Successfully" } else { "Installation Completed with Issues" }
    Write-Host ("  {0}" -f $status) -ForegroundColor White
    Write-Host "===============================================================" -ForegroundColor $(if ($installSuccess -and $verifySuccess) { "Green" } else { "Yellow" })
    
    if ($installSuccess -and $verifySuccess) {
        Write-Host "All dependencies are ready!" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "Some issues occurred during installation. Check the log above." -ForegroundColor Yellow
        exit 1
    }
}
catch {
    Write-Host "Fatal error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
