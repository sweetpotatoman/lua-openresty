local dnsrecord = require('/usr/local/openresty/nginx/lua/dynamic_dns/dnsrecord')

local req_host = ngx.var.http_host

if string.match(req_host, "^dev") == "dev" then
    env_host = "https://ooo-dev.xxx.io"
    env_root = "/testnet/cloud/server/api/v1/app/record"
    env_client_secret = "xxx"
    env_client_id = "ooo"

elseif string.match(req_host, "^test") == "test" then
    env_host = "https://ooo-test.xxx.io"
    env_root = "/testnet/cloud/server/api/v1/app/record"
    env_client_secret = "xxx"
    env_client_id = "ooo"
else 
    return ngx.exit(500)
end

local explorer_brower = dnsrecord:new({
    host = env_host, 
    root = env_root,
    client_secret = env_client_secret,
    client_id = env_client_id
})

local resp = explorer_brower:pre(req_host)
local result_pre = resp.data

-- local signature = dnsrecord.sign(result_pre.data)
local signature = explorer_brower:sign(result_pre.data)

local result = explorer_brower:query(req_host, result_pre.nonce, result_pre.timestamp, signature)

if result.code ~= 200 then
    ngx.log(ngx.ERR, "code: ", result.code, ", ", "backend_msg: ", result.msg)
    return ngx.exit(500)
else
    ngx.var.dynamic_dns_ip = result.data.ip
    ngx.log(ngx.ERR, result.data.ip)
end

