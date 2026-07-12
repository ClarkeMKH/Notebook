function Panel {
    param(
        [string]$Text,
        [object]$Options = @{}
    )
    $entries = @($Options.GetEnumerator())
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
        $userInput = Read-Host
        try {
            $number = [int]$userInput
            if ($number -ge 1 -and $number -le $Options.Count) {
                if ($entries[$number-1].Value -is [hashtable]) {
                    Panel -Text $Text -Options $entries[$number-1].Value
                }
                else {
                    & $entries[$number-1].Value
                }
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
 
Panel -Text "Hi, Welcome to the Terminal Companion created by Clarke Harrison`n`nPlease select from one of the options below." -Options [ordered]@{
    "Microsoft 365" = [ordered]@{
        "Sign In" = {}
    }
    "This System" = { Write-Host "Test" }
}




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
