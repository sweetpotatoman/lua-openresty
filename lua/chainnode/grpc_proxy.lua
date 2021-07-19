local utils = require('/usr/local/openresty/nginx/lua/utils')
local limit = require('/usr/local/openresty/nginx/lua/limit');
local http = require "resty.http"

local json_decode = utils.json_decode

-- grpc 拦截器服务
local host = "http://127.0.0.1:9096"

-- 读取请求 body 内容
ngx.req.read_body();

local grpc_request_uri = ngx.var.request_uri
local grpc_data = ngx.req.get_body_data()

if grpc_data == nil then
    local filename = ngx.req.get_body_file();
    if filename then
        grpc_data = utils.get_file_body(filename)
    end
end

-- ngx.log(ngx.ERR, "body: ", grpc_data)

local httpc = http.new();
local res, err = httpc:request_uri(host, {
    method = "POST",
    path= grpc_request_uri,
    body = grpc_data,
    -- headers = {
    --     ["Content-Type"] = "application/json",
    -- },
    keepalive_timeout = 60000,
    keepalive_pool = 30,
    ssl_verify = false,
})

if not res then
    ngx.log(ngx.ERR, "Request failed: May be need u look grpc-interceptor server", "err: ", err)
    return ngx.exit(499)
end

-- ngx.log(ngx.ERR, "res body: ", res.body)

local resp = json_decode(res.body)

-- 使用 nginx 子查询进行请求中间件服务 (不支持 http2)
-- local res = ngx.location.capture('/proxy/', {method = ngx.HTTP_POST, body = grpc_data})
-- ngx.log(ngx.ERR, "body: ", res.body)


local speedLimitClass
if resp then
    speedLimitClass = resp.speedLimitClass
end

-- if speedLimitClass == 9 then
-- -- if speedLimitClass ~= 0 or speedLimitClass ~= 1 or speedLimitClass ~= 2 then
--     ngx.log(ngx.ERR, "speedLimitClass is 9, Access Denied")
--     return ngx.exit(430)
-- end

-- ngx.log(ngx.ERR, "resp speedLimitClass: ", speedLimitClass)

local rateLimit = limit.limit(speedLimitClass)
local delay, err = rateLimit:incoming(ngx.var.binary_remote_addr, true)



if not delay then
    if err == 'rejected' then
        ngx.log(ngx.ERR, "Rate rejected: grpc")
        return ngx.exit(429)
    end
    return ngx.exit(500)
end


-- ngx.log(ngx.ERR, "delay: ", delay)
if delay >= 0.001 then
    ngx.sleep(delay)
end
