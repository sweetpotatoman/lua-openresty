local utils = require('/usr/local/openresty/nginx/lua/utils')
local limit_req = require('resty.limit.req')
local json_decode = utils.json_decode
local restapi_content = utils.read_file_str('/usr/local/openresty/nginx/lua/chainnode/restapi_mapping.json')
local restapi_uri = json_decode(restapi_content)

local function uri_re_match(restapi_request_uri)
    for i,regex in pairs(restapi_uri.uri) do
        local m = ngx.re.match(restapi_request_uri, regex, "jo")
        if m then
            ngx.log(ngx.ERR, "match success, request_uri: ", restapi_request_uri)
            return true
        end
    end
    ngx.log(ngx.ERR, "match failed, request_uri: ", restapi_request_uri)
    return ngx.exit(441)
end

local defaultLimit = limit_req.new("restapi_default_limit", 5, 5)
local delay, err = defaultLimit:incoming(ngx.var.binary_remote_addr, true)
if not delay then
    if err == 'rejected' then
        ngx.log(ngx.ERR, "Rate rejected")
        return ngx.exit(429)
    end
    return ngx.exit(500)
end

ngx.log(ngx.ERR, "delay: ", delay)
if delay >= 0.001 then
    ngx.sleep(delay)
end

if ngx.var.request_uri ~= nil then
    local restapi_request_uri = ngx.var.request_uri
    ngx.log(ngx.ERR, "restapi_request_uri: ", restapi_request_uri)
    ngx.log(ngx.ERR, "type: ", type(restapi_uri))
    uri_re_match(restapi_request_uri)
else
    ngx.log(ngx.ERR, "No request uri")
    return ngx.exit(443)
end