#Requires -RunAsAdministrator

function Check-Administrator
{
    $user = [Security.Principal.WindowsIdentity]::GetCurrent();
    (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

function Get-ScriptName {
  $fp = $myInvocation.ScriptName
  return [System.IO.Path]::GetFileNameWithoutExtension($fp)
}

function Write-Usage {
  $Program = Get-ScriptName
  Write-Output "$($Program) -Status <arg>"
  Write-Output "   -Status [enabled|disabled]    Enable or Disable the touchscreen"
  Write-Host -NoNewLine 'Press any key to continue...';
  $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
  exit(1)
}

function Write-AdminRequired {
  $Program = Get-ScriptName
  Write-Output "$($Program) must be run as Administrator in order to enable/disable devices"
  Write-Host -NoNewLine 'Press any key to continue...';
  $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
  exit(2)
}

function Disable-Touchscreen {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [string]$InstanceId
    )
    Disable-PnpDevice -InstanceId $InstanceId
}

function Enable-Touchscreen {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [string]$InstanceId
    )
    Enable-PnpDevice -InstanceId $InstanceId
}

function Toggle-Touchscreen {

       [CmdletBinding()]
        param
        (
            [Parameter(Mandatory=$true)]
            [string]$Status
        )
        if($Status.Length -lt 2){
            Write-Usage
        }

        $b = Check-Administrator
        if( -not $b) {
            Write-AdminRequired
        }

        # Get Action, HID devices, and Touch Screen ID's
        $stub = $Status.substring(0, 2).ToLower()
        $HIDs = Get-PnpDevice -Class HIDClass
        $TS = $HIDS | Where-Object -FilterScript {$_.FriendlyName -EQ 'HID-compliant touch screen'}

        # If more than one touchscreen
        if($TS -is [array]) {
            # enable each one
            if($stub -eq 'en') {
                Foreach ($id in $TS) {
                    Enable-Touchscreen -InstanceId $id.InstanceId
                }
            }
            # disable each one
            elseif($stub -eq 'di') {
                Foreach ($id in $TS) {
                    Disable-Touchscreen -InstanceId $id.InstanceId
                }
            }
            else { throw }
        }
        # Otherwise
        else {
            # enable it
            if($stub -eq 'en') {
                Enable-Touchscreen -InstanceId $TS.InstanceId
            }
            # disable it
            elseif($stub -eq 'di') {
                Disable-Touchscreen -InstanceId $TS.InstanceId
            }
            else { throw }
        }
}

Toggle-Touchscreen
