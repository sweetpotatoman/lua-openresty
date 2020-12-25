local utils = require('/usr/local/openresty/nginx/lua/utils')
local json_decode = utils.json_decode

local limit_req = require "resty.limit.req"
local lim, err = limit_req.new("mylimit", 2000, 1000)
if err ~= nil then
    ngx.log(ngx.ERR, err)
end

local balance_table = require("/usr/local/openresty/nginx/lua/config_rules");

local data = ngx.req.get_body_data()
local t = json_decode(data)

if t[1] == nil then
    if t ~= nil then
        local method = t.method
        local delay, err = lim:incoming(method, true)
        if not delay then
            if err == "rejected" then
                return ngx.exit(429)
            end
            return ngx.exit(500)
        end
        local host = balance_table[method]
        if not host then
            return ngx.exit(500)
        end
        ngx.var.balance_host = host
        ngx.var.json_method = method
    else
        local delay, err = lim:incoming(ngx.var.binary_remote_addr, true)
        if not delay then
            if err == "rejected" then
                return ngx.exit(430)
            end
            return ngx.exit(500)
        end
    end
    --ngx.log(ngx.ERR, "failed onemore", type(t))
else
    local methodx = nil
    local hostx = nil
    for k, v in pairs(t) do
        if v == nil then
            local delay, err = lim:incoming(ngx.var.binary_remote_addr, true)
            if not delay then
                if err == "rejected" then
                    return ngx.exit(430)
                end
                return ngx.exit(500)
            end
        end
        if k == 1 then
            methodx = v.method
        end
        local method = v.method
        hostx = balance_table[method]
        if not hostx then
            return ngx.exit(500)
        end
        if methodx ~= method then
            return ngx.exit(500)
        end
    end
    local delay, err = lim:incoming(methodx, true)
    if not delay then
        if err == "rejected" then
            return ngx.exit(429)
        end
        return ngx.exit(500)
    end
    ngx.var.balance_host = hostx
    ngx.var.json_method = methodx
end