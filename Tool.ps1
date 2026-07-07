param(
    [int]$Port = 8080,
    [String]$UrlToken = [System.Guid]::NewGuid().ToString("N"),
    [String]$PostToken = [System.Guid]::NewGuid().ToString("N"),
    [String]$BackgroundColour = "#eeeeee",
    [String]$CardColour = "#cccccc",
    [String]$TextColour = "#111111"
)

$html = @"
<html>
    <body style="margin:0px; padding:0px; height:100dvh; background-color:$BackgroundColour; display:flex; flex-direction:column;">

        <div id="identityCarosel" style="width:100%; height:340px; min-height:340px; max-height:340px; position:relative;">
            <img id="prevIdentityImage" src="" style="position:absolute; top:110px; left:calc(50% - 282px); width:80px; height:80px; border:solid $CardColour 2px; border-radius:400px; outline:none; cursor:pointer;"></img>
            <img id="identityImage" src="" style="position:absolute; top:20px; left:calc(50% - 132px); width:260px; height:260px; border:solid $CardColour 2px; border-radius:400px; outline:none; cursor:pointer;"></img>
            <img id="nextIdentityImage" src="" style="position:absolute; top:110px; right:calc(50% - 282px); width:80px; height:80px; border:solid $CardColour 2px; border-radius:400px; outline:none; cursor:pointer;"></img>
            <div id="identityText" style="position:absolute; bottom:10px; left:0px; width:100%; height:40px; text-align:center; font-size:32px;">LT-010203</div>
        </div>

        <div id="dashboard" style="width:100%; height:100%; overflow:auto; scrollbar-width:none;"></div>

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

            message("Local-Identity");

        </script>
    </body>
</html>
"@





$functionalities = @(
    "Local-Identity"
    "Microsoft-Identity"
)







function Local-Identity {
    $Hardware = $PSVersionTable.OS

    return @{
        "target" = "dashboard"
        "html" = @"
<div style="width:calc(100% - 20px); margin:10px; gap:10px; display:grid; grid-template-columns:repeat(auto-fit, minmax(500px, 1fr)); grid-auto-rows:1fr;">
    <div id="hardware" style="height:300px; background-color:#888888; border-radius:8px;">
        <h2>Hardware</h2>
        $Hardware
    </div>

    <div id="network" style="height:300px; background-color:#888888; border-radius:8px;">
        <h2>Network</h2>
    </div>


</div>
"@
        "js" = ""
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








