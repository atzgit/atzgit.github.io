# =============================================
# ELECTRONIC DOCUMENT TO PAPER CONVERSION TOOL
# Code này dùng để tự động chèn thông tin chuyển đổi văn bản ký số vào trang cuối cùng, khi in bản giấy để đáp ứng yêu cầu pháp luật việt nam, Luật Giao dịch điện tử ngày 22 tháng 6 năm 2023, 23/2025/NĐ-CP, 137/2024/NĐ-CP.
# Test pdfcpu 0.13.0, Windows 10 x64
#
# You have fixed the following bugs:
# 1. Force run in STA mode so OpenFileDialog does not crash (PowerShell 7 defaults to MTA)
# 2. Allow specifying a Unicode font that supports Vietnamese diacritics for the watermark
# 3. Use splat (@arguments) when calling pdfcpu.exe
# 4. Warn if the output file already exists, do not overwrite silently
# 5. Enable UTF8 for the console to correctly display/input Vietnamese
# pdfcpu 0.13.0 switched to the cobra/pflag library, the current rule is: long flag names must use double dashes (--mode), single dash (-) is reserved only for single-character abbreviations (-m)
# =============================================

# --- FIX 1: force run STA for Windows Forms ---
if ([Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA') {
    $hostExe = (Get-Process -Id $PID).Path
    Write-Host "Restarting in STA mode to open the file selection dialog..." -ForegroundColor Yellow
    Start-Process -FilePath $hostExe -ArgumentList @(
        "-NoProfile", "-ExecutionPolicy", "Bypass", "-STA",
        "-File", "`"$PSCommandPath`""
    ) -Wait
    exit
}

# --- FIX 5: UTF8 cho console (hien thi/nhap tieng Viet co dau) ---
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

try {
    Clear-Host
    Write-Host "=== ELECTRONIC DOCUMENT TO PAPER CONVERSION TOOL ===" -ForegroundColor Cyan
    Write-Host ""

    # Get script dir
    if ($PSScriptRoot) {
        $scriptDir = $PSScriptRoot
    } else {
        $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
    }

    $pdfcpuPath = Join-Path $scriptDir "pdfcpu.exe"

    Write-Host "Folder script: $scriptDir" -ForegroundColor Gray

    if (-not (Test-Path $pdfcpuPath)) {
        Write-Host "`nLoi: pdfcpu.exe not found in this folder!" -ForegroundColor Red
        Write-Host "Copy file pdfcpu.exe with file .ps1" -ForegroundColor Yellow
        Read-Host "`nPress Enter to exit"
        exit
    }

    Write-Host "Found pdfcpu.exe" -ForegroundColor Green

    # --- FIX 2: khai bao font Unicode cho watermark tieng Viet ---
    # Neu de trong (""), pdfcpu dung font mac dinh Helvetica -> KHONG co dau tieng Viet.
    # Cach cai font Unicode (chi can lam 1 lan):
    #   pdfcpu fonts install "C:\Windows\Fonts\arial.ttf"
    # Sau do dien ten font da cai vao day, vi du "Arial":
    ./pdfcpu fonts list
    Start-Sleep -Seconds 1
    $fontName = "Times-Roman"   # <-- dien ten font da cai (vd: "Arial") de watermark hien dung dau tieng Viet

    # 1. Input iframe
    $iframe = Read-Host "`n1. Paste iframe in there"

    if ([string]::IsNullOrWhiteSpace($iframe)) {
        Write-Host "You not input yet!" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit
    }

    # 2. Cut link
    if ($iframe -match 'src="([^"]+)"') {
        $link = $matches[1] -replace '&amp;', '&'
        Write-Host "`n-> Link cutted: $link" -ForegroundColor Green
    } else {
        Write-Host "`nLink not found in iframe!" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit
    }

    # 3. Select file PDF
    Write-Host "`n2. Select file PDF..."
    Add-Type -AssemblyName System.Windows.Forms
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Filter = "PDF files (*.pdf)|*.pdf"
    $dialog.Title = "Select file PDF digital sign"

    if ($dialog.ShowDialog() -ne 'OK') {
        Write-Host "Cancel select file." -ForegroundColor Yellow
        Read-Host "Press Enter to exit"
        exit
    }

    $pdfPath = $dialog.FileName
    $folder = Split-Path $pdfPath
    $fileName = [System.IO.Path]::GetFileNameWithoutExtension($pdfPath)
    $outputPath = Join-Path $folder ($fileName + "_printonly--.pdf")

    Write-Host "-> File input: $pdfPath" -ForegroundColor Green

    # --- FIX 4: Warning if file input exists ---
    if (Test-Path $outputPath) {
        $answer = Read-Host "File '$outputPath' exists. Overwrite? (Y/N)"
        if ($answer -notmatch '^[Yy]') {
            $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $outputPath = Join-Path $folder ($fileName + "_printonly--$stamp.pdf")
            Write-Host "-> New input file: $outputPath" -ForegroundColor Yellow
        }
    }

    # 4. Create content
    # $user = $env:USERNAME
    $user = "user.us@company.us"
    $time = Get-Date -Format "dd/MM/yyyy HH:mm:ss"
    $footerText = "Conversion created by: $user, at $time, `nLink: $link"

    Write-Host "`n-> Content to be inserted:" -ForegroundColor Cyan
    Write-Host $footerText -ForegroundColor White

    # 5. Insert watermark
    Write-Host "`nInserting information into the last page..." -ForegroundColor Yellow

    $desc = "pos:bl, rot:0, scale:1 abs, points:9, font:ArialMT, op:0.9"
    if (-not [string]::IsNullOrWhiteSpace($fontName)) {
        $desc = "$desc, font:$fontName"
    }

    $arguments = @(
        "watermark", "add",
        "--mode", "text",
        "--pages", "l",
        "--",
        $footerText,
        $desc,
        $pdfPath,
        $outputPath
    )

    # --- FIX 3: Use the splat operator instead of passing the array variable directly. ---
    & $pdfcpuPath @arguments

    if ($LASTEXITCODE -eq 0) {
        Write-Host "`nSuccess!" -ForegroundColor Green
        Write-Host "File new: $outputPath" -ForegroundColor Green
        # open explorer if want: explorer.exe /select,"$outputPath"
    } else {
        Write-Host "`nError run pdfcpu (Eror code: $LASTEXITCODE)" -ForegroundColor Red
        if ([string]::IsNullOrWhiteSpace($fontName)) {
            Write-Host "Gợi ý: nếu chữ tiếng Việt có dấu bị lỗi, hãy cài font Unicode bằng:" -ForegroundColor Yellow
            Write-Host '  ./pdfcpu fonts install "C:\Windows\Fonts\arial.ttf"' -ForegroundColor Yellow
            Write-Host "roi dien ten font vao bien `$fontName o dau script." -ForegroundColor Yellow
        }
    }
}
catch {
    Write-Host "`nError:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

# Write-Host ""
# Read-Host "Press Enter to exit"

# Auto exit / exit 0
Start-Sleep -Seconds 2
