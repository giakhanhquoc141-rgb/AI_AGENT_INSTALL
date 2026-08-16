# Unit tests for the shared version-check helper logic (copied verbatim from scan.ps1)
$ErrorActionPreference='Stop'
function S3($v){$m=[regex]::Match([string]$v,'\d+\.\d+\.\d+');if($m.Success){return $m.Value};return ''}
function Cmp3($a,$b){$A=($a -split '\.');$B=($b -split '\.');for($i=0;$i -lt 3;$i++){$x=[int]$A[$i];$y=[int]$B[$i];if($x -gt $y){return 1};if($x -lt $y){return -1}};return 0}
function Decide($it,$cur,$lat){
  if($it -eq 'VSCodeExt'){if($cur -ne ''){return 'SKIP'};return 'INSTALL'}
  if($cur -eq ''){return 'INSTALL'}
  if($lat -eq ''){return 'SKIP'}
  if($it -eq 'OpenClaw'){if($cur.CompareTo($lat) -ge 0){return 'SKIP'};return 'UPDATE'}
  $c=S3 $cur;$l=S3 $lat
  if($c -eq '' -or $l -eq ''){return 'SKIP'}
  if((Cmp3 $c $l) -ge 0){return 'SKIP'};return 'UPDATE'
}
function PickNodeLatest($arr){
  $best=''
  foreach($e in @($arr)){
    if($e.lts -eq $false){continue}
    $v=S3 $e.version
    if($v -eq ''){continue}
    if((Cmp3 $v '22.22.3') -ge 0 -and (Cmp3 $v '23.0.0') -lt 0){}elseif((Cmp3 $v '24.15.0') -ge 0 -and (Cmp3 $v '25.0.0') -lt 0){}else{continue}
    if($best -eq '' -or (Cmp3 $v $best) -gt 0){$best=$v}
  }
  return $best
}
$f=0;$p=0
function Chk($name,$got,$exp){if($got -eq $exp){Write-Output "PASS $name = [$got]"}else{$script:f++;Write-Output "FAIL $name got=[$got] exp=[$exp]"}}

# --- Cmp3 numeric comparisons ---
Chk 'Cmp3 24.15.0 vs 24.19.0' (Cmp3 '24.15.0' '24.19.0') -1
Chk 'Cmp3 1.2.3 vs 1.2.3' (Cmp3 '1.2.3' '1.2.3') 0
Chk 'Cmp3 2.0.0 vs 1.99.99' (Cmp3 '2.0.0' '1.99.99') 1
Chk 'Cmp3 3.13.10 vs 3.13.9' (Cmp3 '3.13.10' '3.13.9') 1
Chk 'Cmp3 22.22.3 vs 23.0.0' (Cmp3 '22.22.3' '23.0.0') -1
Chk 'Cmp3 24.15.0 vs 25.0.0' (Cmp3 '24.15.0' '25.0.0') -1

# --- S3 normalization ---
Chk 'S3 strips v' (S3 'v20.11.0') '20.11.0'
Chk 'S3 clean' (S3 '3.13.5') '3.13.5'
Chk 'S3 from python line' (S3 'Python 3.13.5') '3.13.5'
Chk 'S3 2-part -> empty' (S3 '1.2') ''

# --- Decide: no downgrade (current >= latest -> SKIP) ---
Chk 'Decide eq -> SKIP' (Decide '9Router' '0.5.50' '0.5.50') 'SKIP'
Chk 'Decide newer cur -> SKIP' (Decide '9Router' '1.0.0' '0.5.55') 'SKIP'
Chk 'Decide older -> UPDATE' (Decide '9Router' '0.5.50' '0.5.55') 'UPDATE'
Chk 'Decide not installed -> INSTALL' (Decide '9Router' '' '0.5.55') 'INSTALL'
Chk 'Decide offline+installed -> SKIP' (Decide '9Router' '0.5.50' '') 'SKIP'
Chk 'Decide offline+not-installed -> INSTALL' (Decide '9Router' '' '') 'INSTALL'

# --- Decide: OpenClaw calendar (string compare) ---
Chk 'OpenClaw cur older -> UPDATE' (Decide 'OpenClaw' '2026.7.1-2' '2026.7.1-3') 'UPDATE'
Chk 'OpenClaw cur eq -> SKIP' (Decide 'OpenClaw' '2026.7.1-2' '2026.7.1-2') 'SKIP'
Chk 'OpenClaw cur newer -> SKIP' (Decide 'OpenClaw' '2026.8.1-1' '2026.7.1-2') 'SKIP'

# --- Decide: VSCodeExt presence-only ---
Chk 'Ext installed -> SKIP' (Decide 'VSCodeExt' '2.1.233' '') 'SKIP'
Chk 'Ext missing -> INSTALL' (Decide 'VSCodeExt' '' '') 'INSTALL'

# --- Node LTS selection ---
$mock=@(
  @{version='v26.7.0';lts=$false},
  @{version='v25.9.0';lts=$false},
  @{version='v24.19.0';lts='Krypton'},
  @{version='v24.15.0';lts='Krypton'},
  @{version='v23.0.0';lts=$false},
  @{version='v22.22.3';lts='Jod'},
  @{version='v22.0.0';lts='Jod'}
)
Chk 'Node latest = newest LTS 24.x' (PickNodeLatest $mock) '24.19.0'

# Node range: no 24.x in range, only 22.x -> newest 22.x
$mock2=@(
  @{version='v24.10.0';lts='Krypton'},  # below 24.15 -> excluded
  @{version='v26.0.0';lts=$false},
  @{version='v22.30.0';lts='Jod'},
  @{version='v22.22.3';lts='Jod'},
  @{version='v22.0.0';lts='Jod'}
)
Chk 'Node latest falls back to newest LTS 22.x' (PickNodeLatest $mock2) '22.30.0'

# Node: never picks Current (26.x) even if newest
$mock3=@(
  @{version='v26.5.0';lts=$false},
  @{version='v24.16.0';lts='Krypton'},
  @{version='v24.15.0';lts='Krypton'}
)
Chk 'Node never picks Current 26' (PickNodeLatest $mock3) '24.16.0'

# Node: 24.19.0 vs 26.x in real world
$mock4=@(
  @{version='v26.7.0';lts=$false},
  @{version='v24.19.0';lts='Krypton'}
)
Chk 'Node real: picks 24.19.0 over 26.7.0' (PickNodeLatest $mock4) '24.19.0'

Write-Output "TOTAL_FAIL=$f"
