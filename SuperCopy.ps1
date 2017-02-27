# CreatedBy : Fadhly Permata
# CreatedOn : 2017.01.31

# EXEC SAMPLE:
# PS D:\- JOBS\PowerShell> .\SuperCopy.ps1 
#                          -Server "10.53.30.154" 
#                          -ServerUID "dtmp0dg" 
#                          -ServerPID "********" 
#                          -Src "D:\- SHARE\tfsRelease\WS_DPLK" 
#                          -Dst "D:\- SHARE\tfsRelease\Copyan" 
#                          -ActionType "copy-except" 
#                          -Files @('*.config')
param
    (
        [Parameter()] [string]$Server      = $(throw "PS-Script SettingsCopy error: ""Server"" parameter is mandatory, please define the value."),
        [Parameter()] [string]$ServerUID   = $(throw "PS-Script SettingsCopy error: ""ServerUID"" parameter is mandatory, please define the value."),
        [Parameter()] [string]$ServerPID   = $(throw "PS-Script SettingsCopy error: ""ServerPID"" parameter is mandatory, please define the value."),
        [Parameter()] [string]$Src         = $(throw "PS-Script SettingsCopy error: ""Src"" parameter is mandatory, please define the value."),
        [Parameter()] [string]$Dst         = $(throw "PS-Script SettingsCopy error: ""Dst"" parameter is mandatory, please define the value."),
        [Parameter()] [string]$ActionType  = $(throw "PS-Script SettingsCopy error: ""ActionType"" parameter is mandatory, please define the value."),
        [Parameter()] [string[]]$Files
    )


    ### HELPER METHODS ###
    function console-log {
        param (
            [Parameter()] [string]$logText = $(throw "PS-Script log error: ""LogText"" parameter is mandatory, please define the value.")
        )
        Write-Host "==> $logText" -ForegroundColor Yellow -BackgroundColor Black;
    }


    ### FILE or FOLDER COPIER METHODS ###
    function create-path-and-copy {
        param (
            [Parameter()] [string]$fileSource,
            [Parameter()] [string]$fileDest
        )

        console-log -logText $fileSource;
        console-log -logText $fileDest;

        $sPath = [System.IO.Path]::GetDirectoryName($fileDest);
        if (!(Test-Path $sPath)) { [System.IO.Directory]::CreateDirectory($sPath); }
        
        Copy-Item -Path $fileSource -Destination $fileDest -Verbose -Force;
    }

    function copy-all {
        console-log "Copy files (recursively) from [$Src] into [$Dst]";

        ## check source and destination folder
        if (!(Test-Path $Src)) { throw "PS-Script copy-all error: Source directory is not found."; }
        if ($Src.Substring($Src.Length - 1) -ne "*") { $Src = [System.IO.Path]::Combine($Src, "*"); }
        if (!(Test-Path $Dst)) { [System.IO.Directory]::CreateDirectory($Dst); }

        Copy-Item -Path $Src -Destination $Dst -Recurse -Force -Verbose;
    }

    function copy-only {
        if ($Files.Length -eq 0) {
            throw "PS-Script copy-only error: ""Files"" parameter is mandatory, please define the files that will be processed.";

        } else {
            console-log "Copy files (recursively) from [$Src] into [$Dst]";

            ## check source and destination folder
            if (!(Test-Path $Src)) { throw "PS-Script copy-only error: Source directory is not found."; }
            if (!(Test-Path $Dst)) { [System.IO.Directory]::CreateDirectory($Dst); }
            $include = $Files;

            $listFiles = Get-ChildItem $Src -Include $include -Recurse | Where-Object { $_.PSIsContainer -eq $False };
            foreach ($file in $listFiles) {
                $sDest = Join-Path $Dst $file.FullName.Substring(([System.String]$Src).Length);
                create-path-and-copy -fileSource $file.FullName -fileDest $sDest;
            }
        }
    }

    function copy-except {
        If ($Files.Length -eq 0) {
            throw "PS-Script copy-except error: ""Files"" parameter is mandatory, please define the files that will not be processed.";

        } else {
            console-log "Copy files (recursively) from [$Src] into [$Dst]";

            ## check source and destination folder
            if (!(Test-Path $Src)) { throw "PS-Script copy-except error: Source directory is not found."; }
            if (!(Test-Path $Dst)) { [System.IO.Directory]::CreateDirectory($Dst); }
            $exclude = $Files;

            $listFiles = Get-ChildItem $Src -Exclude $exclude -Recurse |  Where-Object { $_.PSIsContainer -eq $False };
            foreach ($file in $listFiles) {
                $sDest = Join-Path $Dst $file.FullName.Substring(([System.String]$Src).Length);
                create-path-and-copy -fileSource $file.FullName -fileDest $sDest;
            }
        }
    }
    
    
    #### MAIN PROC'S ####
    Clear-Host;
    try {
        console-log -logText "Try to Log-in into $Server";
        net use "\\$Server" "$ServerPID" /USER:"$ServerUID";

        If ($ActionType -eq 'copy-except') { copy-except; } 
        ElseIf ($ActionType -eq 'copy-only') {  copy-only; } 
        ElseIf ($ActionType -eq 'copy-all') { copy-all; }
        Else { 
            $(throw "PS-Script SettingsCopy error: Unknown value for ""ActionType"" parameter.");
        }
    }

    catch [System.Exception] {
        console-log -logText "Could not copy files to remote server $Server... $_";
    }

    finally {
        console-log -logText "Log-out from $Server machine.";
        net use "\\$Server" /delete;
    }