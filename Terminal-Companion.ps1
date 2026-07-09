function Panel {
    param(
        [string]$Text,
        [object]$Options = @{}
    )
    Clear-Host
    Write-Host "================================================================`n                      TERMINAL COMPANION                      `n================================================================`n`n"
    Write-Host "$Text`n"
    $i = 1
    foreach ($key in $Options.Keys) {
        Write-Host "$i : $key"
        $i ++
    }
    while ($Options) {
        Write-Host "`n> " -NoNewline -ForegroundColor Yellow
        $input = Read-Host

        try {
            $number = [int]$userInput
            if ($number -ge 1 -and $number -le 10) {
                Write-Host "Valid! You entered $number"
            } else {
                Write-Host "Out of range"
            }
        }
        catch {
            Write-Host "Not a valid number"
        }

    }
}
 
Panel -Text "Hi, Welcome to the Terminal Companion created by Clarke Harrison`n`nPlease select from one of the options below." -Options @{"Option1"=1; "Option2"=2}




while ($true) {
    Write-Host "`n> " -NoNewline -ForegroundColor Yellow
    $input = Read-Host

    if ($input -eq "exit") {
        break
    }




    try {
        Invoke-Expression $input
    }
    catch {
        Write-Host "Error: $_" -ForegroundColor Red
    }
}
