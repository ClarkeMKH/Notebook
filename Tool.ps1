param(
    [int]$Port = 8080,
    [String]$UrlToken = [System.Guid]::NewGuid().ToString("N"),
    [String]$PostToken = [System.Guid]::NewGuid().ToString("N")
)

$html = @"
<html>
    <body style="margin:0px; padding:0px; height:100dvh;">
        <div id="menuButton" onclick="expandManu();" style="width:30px; height:30px; position:fixed; top:5px; left:5px; display:flex; flex-direction:column; padding:5px; border:solid #000000 2px; border-radius:8px; background-color:#ffffff; color:#000000; box-shadow:1px 1px 2px #000000; cursor:pointer; z-index:20; transition: all 0.3s ease-in-out;"></div>

        <div id="panel" style="width:100%; height:100%; overflow:auto; scrollbar-width:none; z-index:10"></div>

        <script>
            async function message(txt="") {
                const req = await fetch("http://localhost:8080/$UrlToken/", {
                    method: "POST",
                    headers: {"Content-Type": "application/json"},
                    body: JSON.stringify({token: "$PostToken", code: txt})
                })
                const res = await req.json();
                if (res.html) document.getElementById('panel').innerHTML = res.html;
                if (res.js) new Function(res.js)();
            }

            message("My-Computer");


            const menuOptions = {
                "Crosstek": "",
                "Microsoft": "",
                "My Computer": "My-Computer-Panel"
            };


            function expandMenu() {

            }


            function collapseMenu() {

            }

        </script>
    </body>
</html>
"@



$functionalities = @(
    "Crosstek-Panel"
    "Microsoft-Panel"
    "My-Computer-Panel"
)




function Crosstek-Panel {
    return @{
        "html" = "<div></div>"
        "js" = ""
    }
}




function Microsoft-Panel {
    return @{
        "html" = "<div></div>"
        "js" = ""
    }
}





function My-Computer-Panel {
    return @{
        "html" = "<div style='font-size:32px;'>$($PSVersionTable.OS)</div>"
        "js" = "console.log('from powershell')"
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








