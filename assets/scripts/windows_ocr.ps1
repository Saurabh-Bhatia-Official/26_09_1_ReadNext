param(
    [string]$ManifestPath,
    [string]$LanguageTag = "",
    [string]$OutputPath = ""
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

Add-Type -AssemblyName System.Runtime.WindowsRuntime

$asTaskGeneric = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
    $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1'
}

function Await-AsyncOp($asyncOp, $resultType) {
    $asTaskMethod = $asTaskGeneric.MakeGenericMethod($resultType)
    $task = $asTaskMethod.Invoke($null, @($asyncOp))
    $task.Wait()
    return $task.Result
}

[Windows.Media.Ocr.OcrEngine, Windows.Foundation, ContentType = WindowsRuntime] | Out-Null
[Windows.Graphics.Imaging.BitmapDecoder, Windows.Foundation, ContentType = WindowsRuntime] | Out-Null
[Windows.Storage.StorageFile, Windows.Foundation, ContentType = WindowsRuntime] | Out-Null
[Windows.Media.Ocr.OcrResult, Windows.Foundation, ContentType = WindowsRuntime] | Out-Null
[Windows.Graphics.Imaging.SoftwareBitmap, Windows.Foundation, ContentType = WindowsRuntime] | Out-Null
[Windows.Storage.Streams.IRandomAccessStream, Windows.Foundation, ContentType = WindowsRuntime] | Out-Null
[Windows.Globalization.Language, Windows.Globalization, ContentType = WindowsRuntime] | Out-Null

$engine = $null
if ($LanguageTag -ne "") {
    try {
        $lang = [Windows.Globalization.Language]::new($LanguageTag)
        if ([Windows.Media.Ocr.OcrEngine]::IsLanguageSupported($lang)) {
            $engine = [Windows.Media.Ocr.OcrEngine]::TryCreateFromLanguage($lang)
        }
    } catch {}
}
if ($engine -eq $null) {
    $engine = [Windows.Media.Ocr.OcrEngine]::TryCreateFromUserProfileLanguages()
}

$imagePaths = @()
if (Test-Path $ManifestPath) {
    $imagePaths = Get-Content -Encoding UTF8 $ManifestPath | Where-Object { $_.Trim().Length -gt 0 } | ForEach-Object { $_.Trim() }
}

$results = @{}
foreach ($img in $imagePaths) {
    if (Test-Path $img) {
        try {
            $fullPath = [System.IO.Path]::GetFullPath($img)
            $file = Await-AsyncOp ([Windows.Storage.StorageFile]::GetFileFromPathAsync($fullPath)) ([Windows.Storage.StorageFile])
            $stream = Await-AsyncOp ($file.OpenAsync([Windows.Storage.FileAccessMode]::Read)) ([Windows.Storage.Streams.IRandomAccessStream])
            $decoder = Await-AsyncOp ([Windows.Graphics.Imaging.BitmapDecoder]::CreateAsync($stream)) ([Windows.Graphics.Imaging.BitmapDecoder])
            $softwareBitmap = Await-AsyncOp ($decoder.GetSoftwareBitmapAsync()) ([Windows.Graphics.Imaging.SoftwareBitmap])
            $ocrResult = Await-AsyncOp ($engine.RecognizeAsync($softwareBitmap)) ([Windows.Media.Ocr.OcrResult])
            
            $lines = @()
            foreach ($l in $ocrResult.Lines) {
                if ($l.Text -ne $null -and $l.Text.Trim().Length -gt 0) {
                    $lines += $l.Text.Trim()
                }
            }
            $results[$img] = @{
                "text" = ($lines -join "`n")
                "lines" = $lines
                "success" = $true
            }
        } catch {
            $errMsg = $_.Exception.Message
            if ($_.Exception.InnerException -ne $null) {
                $errMsg += " -> " + $_.Exception.InnerException.Message
            }
            $results[$img] = @{
                "text" = ""
                "lines" = @()
                "success" = $false
                "error" = $errMsg
            }
        }
    }
}

$jsonOut = $results | ConvertTo-Json -Depth 4
if ($OutputPath -ne "") {
    [System.IO.File]::WriteAllText($OutputPath, $jsonOut, [System.Text.Encoding]::UTF8)
} else {
    Write-Output $jsonOut
}
