$ErrorActionPreference='SilentlyContinue'
function P($s){[Console]::WriteLine($s)}
function S3($v){$m=[regex]::Match([string]$v,'\d+\.\d+\.\d+');if($m.Success){return $m.Value};return ''}
function Cmp3($a,$b){$A=($a -split '\.');$B=($b -split '\.');for($i=0;$i -lt 3;$i++){$x=[int]$A[$i];$y=[int]$B[$i];if($x -gt $y){return 1};if($x -lt $y){return -1}};return 0}
function RetryC($cb){for($i=0;$i -lt 3;$i++){try{return (& $cb)}catch{if($i -ge 2){throw};Start-Sleep -Milliseconds 300}};throw 'retry-failed'}
function Cur($it){
  switch($it){
    'Git'{$c=Get-Command git -ErrorAction SilentlyContinue;if($null -eq $c){return ''};$o=(& git --version 2>$null)|Out-String;$m=[regex]::Match($o,'\d+\.\d+\.\d+(\.windows\.[0-9]+)?');if($m.Success){return $m.Value};return ''}
    'Node'{$c=Get-Command node -ErrorAction SilentlyContinue;if($null -eq $c){return ''};if($c.Source -match '(?i)openclaw'){return ''};$o=(& node --version 2>$null)|Out-String;return (S3 $o)}
    'Python'{$c=Get-Command python -ErrorAction SilentlyContinue;if($null -eq $c){return ''};$o=(& python --version 2>&1)|Out-String;$m=[regex]::Match($o,'Python\s+(\d+\.\d+(\.\d+)?)');if(-not $m.Success){return ''};return $m.Groups[1].Value}
    'VSCode'{$c=Get-Command code -ErrorAction SilentlyContinue;if($null -eq $c){return ''};$o=@(& code --version 2>$null);if($o.Count -ge 1){return ($o[0].Trim())};return ''}
    'VSCodeExt'{$c=Get-Command code -ErrorAction SilentlyContinue;if($null -eq $c){return ''};$o=@(& code --list-extensions --show-versions 2>$null);foreach($l in $o){if($l -match '(?i)anthropic\.claude-code'){$m=[regex]::Match($l,'@([0-9][^@ ]*)');if($m.Success){return $m.Groups[1].Value};return 'installed'}};return ''}
    'OpenClaw'{$c=Get-Command openclaw -ErrorAction SilentlyContinue;if($null -eq $c){return ''};$o=((& openclaw --version 2>$null)|Out-String).Trim();$t=@($o -split '\s+');if($t.Count -ge 2){return $t[1]};return $o}
    '9Router'{$c=Get-Command 9router -ErrorAction SilentlyContinue;if($null -eq $c){return ''};$o=(& 9router --version 2>$null)|Out-String;return (S3 $o)}
  }
  return ''
}
function Latest($it){
  switch($it){
    'Git'{$d=RetryC {(Invoke-RestMethod -Uri 'http://127.0.0.1:1/x' -UseBasicParsing -ErrorAction Stop -Headers @{'User-Agent'='AI-Tools-Installer'})};return ([string]$d.tag_name).TrimStart('v')}
    'Node'{$d=RetryC {(Invoke-RestMethod -Uri 'http://127.0.0.1:1/x' -UseBasicParsing -ErrorAction Stop)};$best='';foreach($e in @($d)){if($e.lts -eq $false){continue};$v=S3 $e.version;if($v -eq ''){continue};if((Cmp3 $v '22.22.3') -ge 0 -and (Cmp3 $v '23.0.0') -lt 0){}elseif((Cmp3 $v '24.15.0') -ge 0 -and (Cmp3 $v '25.0.0') -lt 0){}else{continue};if($best -eq '' -or (Cmp3 $v $best) -gt 0){$best=$v}};return $best}
    'Python'{$d=RetryC {(Invoke-RestMethod -Uri 'http://127.0.0.1:1/x' -UseBasicParsing -ErrorAction Stop)};$best='';foreach($e in @($d)){if($e.is_prerelease){continue};$v=S3 $e.name;if($v -notmatch '^3\.13\.'){continue};if($best -eq '' -or (Cmp3 $v $best) -gt 0){$best=$v}};return $best}
    'VSCode'{$d=RetryC {(Invoke-RestMethod -Uri 'http://127.0.0.1:1/x' -UseBasicParsing -ErrorAction Stop -Headers @{'User-Agent'='AI-Tools-Installer'})};return ([string]$d.tag_name).TrimStart('v')}
    'OpenClaw'{$d=RetryC {(Invoke-RestMethod -Uri 'http://127.0.0.1:1/x' -UseBasicParsing -ErrorAction Stop)};return ([string]$d.latest)}
    '9Router'{$d=RetryC {(Invoke-RestMethod -Uri 'http://127.0.0.1:1/x' -UseBasicParsing -ErrorAction Stop)};return (S3 $d.latest)}
  }
  return ''
}
function Decide($it,$cur,$lat){
  if($it -eq 'VSCodeExt'){if($cur -ne ''){return 'SKIP'};return 'INSTALL'}
  if($cur -eq ''){return 'INSTALL'}
  if($lat -eq ''){return 'SKIP'}
  if($it -eq 'OpenClaw'){if($cur.CompareTo($lat) -ge 0){return 'SKIP'};return 'UPDATE'}
  $c=S3 $cur;$l=S3 $lat
  if($c -eq '' -or $l -eq ''){return 'SKIP'}
  if((Cmp3 $c $l) -ge 0){return 'SKIP'};return 'UPDATE'
}
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$neterr=0
foreach($it in @('Git','Node','Python','VSCode','VSCodeExt','OpenClaw','9Router')){
  $cur='';try{$cur=Cur $it}catch{$cur=''}
  $lat=''
  if($it -ne 'VSCodeExt'){try{$lat=Latest $it}catch{$lat='';$neterr++}}
  $dec=Decide $it $cur $lat
  P ('{0}|{1}|{2}|{3}' -f $it,$cur,$lat,$dec)
}
P ('NETERR|{0}' -f $neterr)


