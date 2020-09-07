-- https://jasonstitt.com/ip-reporting-script-lua-lighttpd
lighty.content = { lighty.env["request.remote-ip"] }
return 200

