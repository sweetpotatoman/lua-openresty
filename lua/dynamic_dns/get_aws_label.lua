local shell = require "resty.shell"
local redis = require "resty.redis"

local red = redis:new()

-- 设置redis连接超时时间
red:set_timeouts(10000, 10000, 10000) -- 10 sec

local req_host = ngx.var.http_host
local execommand = "aws ec2 describe-instances --filters Name=tag-key,Values=test-domain Name=tag-value,Values=" .. req_host .. " --query 'Reservations[*].Instances[*].[PublicIpAddress]' --output text"
local timeout = 20000  -- ms
local max_size = 4096  -- byte
local public_ip = nil  -- awscli search public ip


local ok, err = red:connect("192.168.20.94", 6379)
if not ok then
    ngx.log(ngx.ERR, "failed to connect: ", err)
    return
end

local res, err = red:get(req_host)
if not res then
    ngx.log(ngx.ERR, "failed to get req_host: ", err)
    return
end

if res == ngx.null or res == "" then
    ngx.log(ngx.ERR, "req_host value is nil or null", res)
    -- 这里需要写个循环，如果失败则继续
    for i=0,1,1 do
        local shell_ok, stdout, stderr, reason, status = 
            shell.run(execommand, nil, timeout, max_size)
        if not shell_ok then
            ngx.log(ngx.ERR, 'shell is wrong: ', reason, ' count is: ', i+1)
        else
            public_ip = stdout
            break
        end
    end

    if public_ip == nil then
        ngx.log(ngx.ERR, "no get public_ip value")
        return
    else
        local dynamic_dns_ip = public_ip:gsub("%s+", "")

        local ok, err = red:set(req_host, dynamic_dns_ip)
        if not ok then
            ngx.log(ngx.ERR, "failed to set domain: ", err)
            return
        end
        ngx.log(ngx.ERR, "set result: ", ok)

        ngx.var.dynamic_dns_ip = dynamic_dns_ip
        ngx.log(ngx.ERR, "get values: ", ngx.var.dynamic_dns_ip)
    end 

    -- local res, err = red:get(req_host)
    -- if not res then
    --     ngx.log(ngx.ERR, "failed to get domain: ", err)
    --     return
    -- end

    -- 取值一般不会为空
    -- if res == ngx.null then
    -- if res == "" then
    --     ngx.log(ngx.ERR, "domain not found.")
    --     return
    -- end

    -- ngx.var.dynamic_dns_ip = res
    -- ngx.log(ngx.ERR, "get values: ", ngx.var.dynamic_dns_ip)
else
    local res, err = red:get(req_host)
    if not res then
        ngx.log(ngx.ERR, "failed to get domain: ", err)
        return
    end

    -- 取值一般不会为空
    -- if res == ngx.null then
    -- if res == "" then
    --     ngx.log(ngx.ERR, "domain not found.")
    --     return
    -- end

    ngx.var.dynamic_dns_ip = res
    ngx.log(ngx.ERR, "get values: ", ngx.var.dynamic_dns_ip)
end

-- put it into the connection pool of size 100,
-- with 10 seconds max idle time
local ok, err = red:set_keepalive(60000, 100)
if not ok then
    ngx.log(ngx.ERR, "failed to set keepalive: ", err)
    return
end
