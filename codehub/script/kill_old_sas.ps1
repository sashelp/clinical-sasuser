param(
  [int]$HoursThreshold = 168
)

$cutoff = (Get-Date).AddHours(-$HoursThreshold)

$procs = Get-CimInstance Win32_Process -Filter "Name='sas.exe'" -ErrorAction SilentlyContinue
if (-not $procs) {
  Write-Output "No sas.exe processes found."
  exit 0
}

foreach ($p in $procs) {
  $start = $null
  try { $start = (Get-Process -Id $p.ProcessId -ErrorAction Stop).StartTime } catch {}
  if (-not $start) { continue }

  if ($start -le $cutoff) {
    Write-Output "PID $($p.ProcessId) Name:$($p.Name) Start:$start"
    $procId = $p.ProcessId
    $msg = "Killing PID $procId  Name:$($p.Name)  Start:$start"
    try {
      Stop-Process -Id $procId -Force -ErrorAction Stop
      Write-Output "Stopped PID $procId"
    } catch {
      $err = if ($_.Exception) { $_.Exception.Message } else { $_.ToString() }
      Write-Warning ("Failed to stop PID {0}: {1}" -f $procId, $err)
    }
  }
}