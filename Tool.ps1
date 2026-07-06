param(
    [int]$Port = 8080,
    [String]$UrlToken = [System.Guid]::NewGuid().ToString("N"),
    [String]$PostToken = [System.Guid]::NewGuid().ToString("N")
)

$html = @"
<html>
    <body style="margin:0px; padding:0px; height:100dvh; background-color:#505050">

        <div id="panel" style="width:100%; height:100%; overflow:auto; scrollbar-width:none; z-index:10"></div>

        <script>
            async function message(txt="") {
                const req = await fetch("http://localhost:8080/$UrlToken/", {
                    method: "POST",
                    headers: {"Content-Type": "application/json"},
                    body: JSON.stringify({token: "$PostToken", code: txt})
                })
                const res = await req.json();
                if (res.html && res.target) document.getElementById(res.target).innerHTML = res.html;
                if (res.js) new Function(res.js)();
            }

            message("Home-Panel");

        </script>
    </body>
</html>
"@





$functionalities = @(
    "Home-Panel"
    "System-Panel"
)






function Home-Panel {
    function Return-Btn {
        param(
            [String]$Click,
            [String]$Title,
            [String]$Pic
        )
        return @"
<div onclick="$Click" style="position:relative; border-radius:4px; display:flex; justify-content:center; align-items:center; flex-direction:column; gap:20px; padding:20px; cursor:pointer;">
    <div onmouseenter="this.style.opacity=1" onmouseleave="this.style.opacity=0.6" style="width:100%; height:100%; background-color:#04084a; opacity:0.6; transition:all 0.2s ease-in-out; position:absolute; top:0px; left:0px;"></div>
    <img src="$Pic" style="width:100px; height:100px; border-radius:8px; outline:none; border:0px; z-index:10; pointer-events:none;"></img>
    <div style="font-size:24px; color:#eeeeee; text-align:center; z-index:10; pointer-events:none;">$Title</div>
</div>
"@
    }

    return @{
        "target" = "panel"
        "html" = @"

<div style="margin:40px; font-size:42px;">IT Toolkit</div>

<div style="width:80%; min-height:120px; margin:0px 10%; display:grid; gap:10px; grid-template-columns:repeat(auto-fit, minmax(300px, 1fr)); grid-auto-rows:1fr;">
    $(Return-Btn -Click "message('System-Panel')" -Title "System" -Pic "")
    $(Return-Btn -Click "alert('test')" -Title "Microsoft" -Pic "")
</div>
"@
        "js" = ""
    }
}





function System-Panel {
    return @{
        "target" = "panel"
        "html" = "System"
        "js" = "alert('System')"
    }
}





$listener = New-Object System.Net.HttpListener
$url = "http://localhost:$Port/$UrlToken/"
$listener.Prefixes.Add($url)
$listener.Start()
Write-Host "Serving at $url (Ctrl+C to stop)"
Start-Process $url




while ($listener.IsListening) {
    $context = $listener.GetContext()
    $request = $context.Request
    $response = $context.Response
    $path = $request.Url.AbsolutePath
    $method = $request.HttpMethod
    if ($path -eq "/$UrlToken/" -and $method -eq "POST") {
        $reader = New-Object System.IO.StreamReader($request.InputStream, $request.ContentEncoding)
        $body = $reader.ReadToEnd()
        $reader.Close()
        try {
            $jsonData = $body | ConvertFrom-Json
            $receivedToken = $jsonData.token
            $receivedCode = $jsonData.code
            if (($receivedToken -eq $PostToken) -and ($functionalities -contains $receivedCode)) {
                $responseText = Invoke-Expression $receivedCode | ConvertTo-Json
                $response.StatusCode = 200
            }
            else {
                $responseText = "Invalid Token"
                $response.StatusCode = 400
            }
        }
        catch {
            $responseText = "Invalid JSON: $($_.Exception.Message)"
            $response.StatusCode = 400
        }
    }
    elseif ($path -eq "/$UrlToken/" -and $method -eq "GET") {
        $responseText = $html
    }
    else {
        $responseText = "Not found: $path"
        $response.StatusCode = 404
    }
    $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseText)
    $context.Response.ContentLength64 = $buffer.Length
    $context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
    $context.Response.OutputStream.Close()
}








