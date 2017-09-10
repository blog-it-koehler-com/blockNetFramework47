  <# .SYNOPSIS

    script blocks .Net 4.7 Installation on windows server 2012/2012R2/2016 (

    .DESCRIPTION

    this script checks the registry for blocking .Net Framework 4.7 and creates or updates values needed

    .EXAMPLE
    .\blockNetFramework4.7.ps1 
    
    .Notes
    no parameters needed
    see also https://blog.it-koehler.com/en/Archive/1535

  
    ---------------------------------------------------------------------------------
                                                                                 
    Script:       blockNetFramework4.7.ps1                                      
    Author:       A. Koehler; blog.it-koehler.com
    ModifyDate:    28/08/2017                                                        
    Usage:        for use in ise, see also exe available
    Version:       0.1
                                                                                  
    ---------------------------------------------------------------------------------
#>





#### function registry value check by jonathanmedd.net ###
#### http://www.jonathanmedd.net/2014/02/testing-for-the-presence-of-a-registry-key-and-value.html
function Test-RegistryValue {

  param (

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]$Path,

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]$Value
  )

  try {

    Get-ItemProperty -Path $Path -Name $Value -ErrorAction Stop | Out-Null
    return $true
    }

  catch {

    return $false
      }
}


####function opening registry editor by 
####https://powershellone.wordpress.com/2015/09/02/use-powershell-to-open-regedit-at-a-specific-or-regjump-for-powershell/

function Open-Registry{
    [CmdletBinding()]
    [Alias("regJump")]
    param(
        [Parameter(Position=0)]
    	$regKey
    )
    #check for clipbaord only if no argument provided
    if (!$regKey){
        #split the clipboard content by crlf and get of trailing crlf in case clipboard populated via piping it to clip.exe
		$cmd = {
			Add-Type -Assembly PresentationCore
			[Windows.Clipboard]::GetText() -split "`r`n" | where {$_}
		}
        #in case its run from the powershell commandline
	    if([Threading.Thread]::CurrentThread.GetApartmentState() -eq 'MTA') {
		    $regKey = & powershell -STA -Command $cmd
	    } 
        else {
		    $regKey = & $cmd
	    }
    }
    foreach ($key in $regKey){
        $replacers = @{
            'HKCU:?\\'='HKEY_CURRENT_USER\'
            'HKLM:?\\'='HKEY_LOCAL_MACHINE\'
            'HKU:?\\'='HKEY_USERS\'
            'HKCC:?\\'='HKEY_CURRENT_CONFIG\'
            'HKCR:?\\'='HKEY_CLASSES_ROOT\'
        }
        #replace hive shortnames with or without PowerShell Syntax + remove trailing backslash
        $properKey = $key
	    $replacers.GetEnumerator() | foreach {
		    $properKey = $properKey.ToUpper() -replace $_.Key, $_.Value -replace '\\$'
	    }
        #check if the path points to an existing key or its parent is an existing value 
        #add one level since we don't want the first iteration of the loop to remove a level
        $path = "$properKey\dummyFolder"
        #test the registry path and revert to parent path until valid path is found otherwise return $false
        while(Split-Path $path -OutVariable path){
            $providerPath = $providerPath = "Registry::$path"
            if (Test-Path $providerPath){
               break
            }
        }
        if ($path){
	        Set-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Applets\Regedit\ -Name LastKey -Value $path -Force
            #start regedit using m switch to allow for multiple instances
            $regeditInstance = [Diagnostics.Process]::Start("regedit","-m")
            #wait the regedit window to appear
            while ($regeditInstance.MainWindowHandle -eq 0){
                sleep -Milliseconds 100
            }
        }
        else{
            Write-Warning "Neither ""$key"" nor any of its parents does exist"
        }
    }
}


### beginning of the script ###
###defining regkey to .net4.7 blocker ###
$RegKey = "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\WU"
#checking if regkey already exists ###
if (-Not(Test-Path "$RegKey")) {
  
  Write-Host ".Net 4.7 Block Key will be created!" -ForegroundColor Yellow
  New-Item -Path "$($RegKey.TrimEnd($RegKey.Split('\')[-1]))" -Name "$($RegKey.Split('\')[-1])" -Force | Out-Null
  
  if (Test-Path "$RegKey") {
  
    Write-Host ".Net 4.7 Block Key was created successful!" -ForegroundColor Green
    Set-ItemProperty -Path "$RegKey" -Name "BlockNetFramework47" -Type Dword -Value "1"
        
  }
  else{
  
    Write-Host "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\WU can not be created please check permissions!" -ForegroundColor Red
  
  }
    
}
else{
  Write-Host "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\WU already exists!" -ForegroundColor Yellow
  Write-Host "Creating BlockNetFramework47 Dword Value " -ForegroundColor Yellow
  ###check if blocknetFramework47 value exists ###
  $exist = (Test-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\WU" -Value "BlockNetFramework47")
  if ($exist -eq $true){
    
    $value = (Get-ItemProperty -Path "$RegKey" -Name BlockNetFramework47 ).BlockNetFramework47
    Write-Host "BlockNetFramework47 already exists in registry, checking if it is set to 1" -ForegroundColor Yellow
    
    if ($value -eq 1 ){
    
      Write-Host "BlockNetFramework47 exists in registry, and is set to $value everything is fine!" -ForegroundColor Green
    
    }
    else{
      Write-Host "BlockNetFramework47 exists in registry, but is set to $value, correcting to vaule 1" -ForegroundColor Yellow
      Set-ItemProperty -Path "$RegKey" -Name "BlockNetFramework47" -Value "1"
      Write-Host "BlockNetFramework47 corrected to $value everything is fine!" -ForegroundColor Green
    }

    }
   else {
      Set-ItemProperty -Path "$RegKey" -Name "BlockNetFramework47" -Type Dword -Value "1"
      $exist = (Test-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\WU" -Value "BlockNetFramework47")
      
      if ($exist -eq $true){
      
      $value = (Get-ItemProperty -Path "$RegKey" -Name BlockNetFramework47 ).BlockNetFramework47
      Write-Host "BlockNetFramework47 created in registry, checking if it is set to 1" -ForegroundColor Yellow
    
      if ($value -eq 1 ){
    
            Write-Host "BlockNetFramework47 exists and is set to $value everything is fine!" -ForegroundColor Green
    
                        }
      else{
        Write-Host "BlockNetFramework47 exists in registry, but is set to $value, correcting to vaule 1" -ForegroundColor Yellow
        Set-ItemProperty -Path "$RegKey" -Name "BlockNetFramework47" -Value "1"
        Write-Host "BlockNetFramework47 corrected to $value everything is fine!" -ForegroundColor Green
        }
      
       Write-Host ".Net 4.7 Block Key was created successful, check HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\WU !" -ForegroundColor Green
        
      }
    
    }
  }
Write-Host "Opening Registry Editor " -ForegroundColor Yellow
Open-Registry -regKey $RegKey

