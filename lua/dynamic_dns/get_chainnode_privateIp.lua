local dnsrecord = require('/usr/local/openresty/nginx/lua/dynamic_dns/dnsrecord')

local req_host = ngx.var.http_host

if string.match(req_host, "^dev") == "dev" then
    env_host = "https://ooo-dev.xxx.io"
    env_root = "/testnet/cloud/server/api/v1/node/record"

elseif string.match(req_host, "^test") == "test" then
    env_host = "https://ooo-test.xxx.io"
    env_root = "/testnet/cloud/server/api/v1/node/record"
else 
    return ngx.exit(500)
end

local chainnode = dnsrecord:new({
    host = env_host, 
    root = env_root
})

local resp = chainnode:chaindnsrecord(req_host)
local result = resp

if result.code ~= 200 then
    ngx.log(ngx.ERR, "code: ", result.code, ", ", "backend_msg: ", result.msg)
    return ngx.exit(500)
else
    ngx.var.dynamic_dns_ip = result.data
    ngx.log(ngx.ERR, result.data)
end

