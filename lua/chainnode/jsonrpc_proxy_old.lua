local utils = require('/usr/local/openresty/nginx/lua/utils')
local json_decode = utils.json_decode


local limit_req = require "resty.limit.req"
local lim, err = limit_req.new("mylimit", 5000, 2000)
if err ~= nil then
    ngx.log(ngx.ERR,"limit_req.new fail: ", err)
end

local balance_table = require("/usr/local/openresty/nginx/lua/chainnode/config_rules");

local data = ngx.req.get_body_data()
local t = json_decode(data)

-- 如果请求没有传值则报错 416 且打印出 error 日志
if not t then
    ngx.log(ngx.ERR, "request no values")
    return ngx.exit(416)
end

-- 如果解析请求后是数组类型则使用泛型方式进行取值
if t[1] ~= nil then
    for i, w in ipairs(t) do
        local method = w.method
        local host = balance_table[method]
        ngx.var.balance_host = host
        ngx.var.json_method = method
        if not host then
            ngx.log(ngx.ERR, "balance host not found", host )
            return ngx.exit(500)
        end
        local delay, err = lim:incoming(method, true)
        if not delay then
            if err == "rejected" then
                ngx.log(ngx.ERR, "regulation array-method too many requests: ", err)
                return ngx.exit(429)
            end
            ngx.log(ngx.ERR, "regulation array-method not delay but not rejected: ", err)
            return ngx.exit(500)
        end
    end
-- 如果解析请求后是表类型则直接取值
elseif t ~= nil then
    local method = t.method
    local host = balance_table[method]
    ngx.var.balance_host = host
    ngx.var.json_method = method
    if not host then
        ngx.log(ngx.ERR, "balance host not found", host )
        return ngx.exit(500)
    end
    local delay, err = lim:incoming(method, true)
    if not delay then
        if err == "rejected" then
    	    ngx.log(ngx.ERR, "regulation json-method too many requests: ", err)
            return ngx.exit(429)
        end
        ngx.log(ngx.ERR, "regulation json-method not delay but not rejected: ", err)
        return ngx.exit(500)
    end
-- 暂时走不到这一步，需要看明确需求
else
    local delay, err = lim:incoming(ngx.var.binary_remote_addr, true)
    if not delay then
        if err == "rejected" then
            ngx.log(ngx.ERR, "remote-ip too many requests: ", err)
	    return ngx.exit(429)
        end
	ngx.log(ngx.ERR, "remote-ip not delay but not rejected: ", err)
        return ngx.exit(500)
    end
end