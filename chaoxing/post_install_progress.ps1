# Post-Installation Dependency Setup with Progress Display
# 安装后依赖设置脚本，带进度条和下载速率显示

param(
    [string]$PythonExe,
    [string]$RequirementsFile = "chaoxing\requirements.txt",
    [string]$LogFile = ""
)

# Set console encoding
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'Continue'

function Write-Log {
    param($Message, $Type = "Info")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    
    switch ($Type) {
        "Success" { Write-Host $logMessage -ForegroundColor Green }
        "Warning" { Write-Host $logMessage -ForegroundColor Yellow }
        "Error"   { Write-Host $logMessage -ForegroundColor Red }
        "Info"    { Write-Host $logMessage -ForegroundColor Cyan }
    }
    
    if ($LogFile -and (Test-Path (Split-Path $LogFile -Parent))) {
        Add-Content -Path $LogFile -Value $logMessage -ErrorAction SilentlyContinue
    }
}

function Show-ProgressHeader {
    param($Title, $Color = "Cyan")
    Write-Host ""
    Write-Host "===============================================================" -ForegroundColor $Color
    Write-Host ("  {0}" -f $Title) -ForegroundColor White
    Write-Host "===============================================================" -ForegroundColor $Color
}

function Install-WithProgress {
    param(
        [string]$PackageName,
        [string[]]$PipArgs,
        [int]$Step = 1,
        [int]$TotalSteps = 1
    )
    
    $percentComplete = [math]::Round(($Step / $TotalSteps) * 100, 1)
    Write-Progress -Activity "Installing Dependencies" -Status "$PackageName ($percentComplete%)" -PercentComplete $percentComplete
    
    Write-Log "[$Step/$TotalSteps] Installing $PackageName..." "Info"
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    # Execute pip command
    $process = Start-Process -FilePath $PythonExe -ArgumentList $PipArgs -NoNewWindow -PassThru -RedirectStandardOutput "temp_output.log" -RedirectStandardError "temp_error.log"
    
    # Monitor progress with simple animation
    $spinChars = @('|', '/', '-', '\')
    $spinIndex = 0
    
    while (-not $process.HasExited) {
        Start-Sleep -Milliseconds 200
        $spinChar = $spinChars[$spinIndex % 4]
        Write-Host "  $spinChar Installing $PackageName..." -NoNewline -ForegroundColor Yellow
        Write-Host "`r" -NoNewline
        $spinIndex++
    }
    
    $stopwatch.Stop()
    $process.WaitForExit()
    
    # Clean up progress line
    Write-Host ("  " + " " * 50) -NoNewline
    Write-Host "`r" -NoNewline
    
    $duration = [math]::Round($stopwatch.Elapsed.TotalSeconds, 1)
    
    if ($process.ExitCode -eq 0) {
        Write-Log "✓ $PackageName installed successfully (${duration}s)" "Success"
        $success = $true
    } else {
        Write-Log "✗ Failed to install $PackageName (${duration}s)" "Error"
        
        # Show error details
        if (Test-Path "temp_error.log") {
            $errorContent = Get-Content "temp_error.log" -Raw
            if ($errorContent.Trim()) {
                Write-Log "Error details: $($errorContent.Trim())" "Error"
            }
        }
        $success = $false
    }
    
    # Cleanup temp files
    Remove-Item "temp_output.log", "temp_error.log" -Force -ErrorAction SilentlyContinue
    
    return $success
}

# Main execution
try {
    if (-not $PythonExe -or -not (Test-Path $PythonExe)) {
        Write-Log "Error: Invalid Python executable: $PythonExe" "Error"
        exit 1
    }
    
    Show-ProgressHeader "Enhanced Dependency Installation" "Magenta"
    Write-Log "Python: $PythonExe" "Info"
    Write-Log "Requirements: $RequirementsFile" "Info"
    
    # Step 1: Upgrade pip
    Show-ProgressHeader "Upgrading pip"
    $pipUpgradeArgs = @("-m", "pip", "install", "--upgrade", "pip", "--disable-pip-version-check", "--no-cache-dir", "--progress-bar", "on")
    $pipSuccess = Install-WithProgress -PackageName "pip" -PipArgs $pipUpgradeArgs -Step 1 -TotalSteps 3
    
    # Step 2: Install from requirements file
    Show-ProgressHeader "Installing from Requirements File"
    if (Test-Path $RequirementsFile) {
        $reqArgs = @("-m", "pip", "install", "-r", $RequirementsFile, "--disable-pip-version-check", "--no-cache-dir", "--progress-bar", "on", "--verbose")
        $reqSuccess = Install-WithProgress -PackageName "Requirements" -PipArgs $reqArgs -Step 2 -TotalSteps 3
    } else {
        Write-Log "Requirements file not found: $RequirementsFile" "Warning"
        $reqSuccess = $false
    }
    
    # Step 3: Install core packages individually if requirements failed
    if (-not $reqSuccess) {
        Show-ProgressHeader "Installing Core Dependencies Individually"
        
        $corePackages = @(
            "requests", "httpx", "PySide6>=6.7.0", "pyaes", 
            "beautifulsoup4", "lxml", "loguru", "pycryptodome", 
            "openai", "urllib3"
        )
        
        $successCount = 0
        for ($i = 0; $i -lt $corePackages.Count; $i++) {
            $pkg = $corePackages[$i]
            $pkgArgs = @("-m", "pip", "install", $pkg, "--disable-pip-version-check", "--no-cache-dir", "--progress-bar", "on", "--upgrade")
            
            if (Install-WithProgress -PackageName $pkg -PipArgs $pkgArgs -Step ($i + 1) -TotalSteps $corePackages.Count) {
                $successCount++
            }
        }
        
        Write-Log "Core packages installation: $successCount/$($corePackages.Count) successful" $(if ($successCount -eq $corePackages.Count) { "Success" } else { "Warning" })
    }
    
    # Step 4: Verify critical modules
    Show-ProgressHeader "Verifying Critical Modules"
    
    $criticalModules = @(
        @{Name="PySide6"; Import="PySide6"},
        @{Name="httpx"; Import="httpx"},
        @{Name="requests"; Import="requests"},
        @{Name="openai"; Import="openai"},
        @{Name="Crypto"; Import="Crypto"}
    )
    
    $verifySuccess = $true
    for ($i = 0; $i -lt $criticalModules.Count; $i++) {
        $module = $criticalModules[$i]
        $percentComplete = [math]::Round((($i + 1) / $criticalModules.Count) * 100, 1)
        Write-Progress -Activity "Verifying Modules" -Status "$($module.Name) ($percentComplete%)" -PercentComplete $percentComplete
        
        $testResult = & $PythonExe -c "import $($module.Import); print('OK')" 2>$null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "✓ $($module.Name) is available" "Success"
        } else {
            Write-Log "✗ $($module.Name) is missing - attempting reinstall" "Warning"
            $reinstallArgs = @("-m", "pip", "install", $module.Name, "--disable-pip-version-check", "--no-cache-dir", "--force-reinstall", "--progress-bar", "on")
            Install-WithProgress -PackageName $module.Name -PipArgs $reinstallArgs -Step 1 -TotalSteps 1
            $verifySuccess = $false
        }
    }
    
    Write-Progress -Activity "Verifying Modules" -Completed
    
    # Final summary
    Show-ProgressHeader $(if ($verifySuccess) { "Installation Completed Successfully" } else { "Installation Completed with Issues" }) $(if ($verifySuccess) { "Green" } else { "Yellow" })
    
    if ($verifySuccess) {
        Write-Log "All dependencies are ready for use!" "Success"
        exit 0
    } else {
        Write-Log "Some dependencies may need manual attention." "Warning"
        exit 1
    }
}
catch {
    Write-Log "Fatal error: $($_.Exception.Message)" "Error"
    exit 1
}
