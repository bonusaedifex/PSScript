$pingCount = 4

$cpuUsage = (Get-Counter -Counter "\Processor(_Total)\% Processor Time").CounterSamples.CookedValue
$memoryUsage = (Get-Counter -Counter "\Memory\% Committed Bytes In Use").CounterSamples.CookedValue
$networkUsage = (Get-Counter -Counter "\Network Interface(*)\Bytes Total/sec").CounterSamples.CookedValue | Measure-Object -Sum | Select-Object -ExpandProperty Sum

$cpuPercent = [math]::Round($cpuUsage, 2)
$memoryPercent = [math]::Round($memoryUsage, 2)

$downloadUrl = "http://speedtest.tele2.net/100MB.zip"
$tempFilePath = "$env:TEMP\speedtest.bin"

# Start the stopwatch to measure the download time
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# Download the file
Invoke-WebRequest -Uri $downloadUrl -OutFile $tempFilePath

# Stop the stopwatch and calculate the download time in seconds
$downloadTime = $stopwatch.Elapsed.TotalSeconds

# Calculate the download speed in Megabits per second (Mbps)
$fileSize = (Get-Item $tempFilePath).Length
$downloadSpeed = ($fileSize / $downloadTime) * 8 / 1MB

$googlePingResults = 1..$pingCount | ForEach-Object {
    $googlePing = Test-Connection -ComputerName "google.com" -Count 1
    $googlePingResult = [PSCustomObject]@{
        Source = $googlePing.Source
        Destination = $googlePing.Destination
        Address = $googlePing.Address
        Latency = $googlePing.Latency
        Status = $googlePing.Status
    }
    $googlePingResult
}

$cayentaPingResults = 1..$pingCount | ForEach-Object {
    $cayentaPing = Test-Connection -ComputerName "CAYPD-DB1" -Count 1
    $cayentaPingResult = [PSCustomObject]@{
        Source = $cayentaPing.Source
        Destination = $cayentaPing.Destination
        Address = $cayentaPing.Address
        Latency = $cayentaPing.Latency
        Status = $cayentaPing.Status
    }
    $cayentaPingResult
}

$topMemoryProcesses = Get-Process | Sort-Object -Property WorkingSet -Descending | Select-Object -First 5
$topCpuProcesses = Get-Process | Sort-Object -Property CPU -Descending | Select-Object -First 5

$output = @"
TimeStamp: $(Get-Date)
CPU Usage: $cpuPercent%
Memory Usage: $memoryPercent%

Download Speed: $([Math]::Round($downloadSpeed, 2)) Mbps

Google Ping Results:

$('{0,-15} {1,-20} {2,-15} {3,-10} {4,-10}' -f "Source", "Destination", "Address", "Latency", "Status")
$('-' * 80)`n
"@

foreach ($pingResult in $googlePingResults) {
    $source = $pingResult.Source
    $destination = $pingResult.Destination
    $address = $pingResult.Address
    $latency = $pingResult.Latency
    $status = $pingResult.Status

    $output += "$('{0,-15} {1,-20} {2,-15} {3,-10} {4,-10}' -f $source, $destination, $address, $latency, $status)`n"
}

$output += @"
`nCAYENTA Ping Results:
$('{0,-15} {1,-20} {2,-15} {3,-10} {4,-10}' -f "Source", "Destination", "Address", "Latency", "Status")
$('-' * 80)`n
"@

foreach ($pingResult in $cayentaPingResults) {
    $source = $pingResult.Source
    $destination = $pingResult.Destination
    $address = $pingResult.Address
    $latency = $pingResult.Latency
    $status = $pingResult.Status

    $output += "$('{0,-15} {1,-20} {2,-15} {3,-10} {4,-10}' -f $source, $destination, $address, $latency, $status)`n"
}

$output += "`nTop 5 Processes by Memory Usage:`n$('{0,-25} {1,-15}' -f "Process Name", "Memory Usage")`n$('-' * 40)`n"

foreach ($process in $topMemoryProcesses) {
    $processName = $process.ProcessName
    $processMemory = [math]::Round($process.WorkingSet / 1MB, 2)
    $output += "$('{0,-25} {1,-15} MB' -f $processName, $processMemory)`n"
}

$output += "`nTop 5 Processes by CPU Usage:`n$('{0,-25} {1,-15}' -f 'Process Name', 'CPU Usage')`n$('-' * 40)`n"

foreach ($process in $topCpuProcesses) {
    $processName = $process.ProcessName
    $processCpu = [math]::Round($process.CPU, 2)
    $output += "$('{0,-25} {1,-15}' -f $processName, $processCpu)`n"
}

$outputPath = "C:\Users\tjudson\OneDrive - Clayton County Water Authority\Desktop\TextLogs\SystemStats.txt"
$output | Out-File -FilePath $outputPath

Write-Host "Output written to $outputPath"

# Remove the downloaded file
Remove-Item $tempFilePath
