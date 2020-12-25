local mysql = require 'resty.mysql'
local db, err = mysql:new()
if not db then
    ngx.log(ngx.ERR, 'failed to instantiate mysql: ', err)
    return
end

db:set_timeout(3000) -- 3 sec

local ok, err, errcode, sqlstate =
    db:connect {
    host = '127.0.0.1',
    port = 3306,
    database = 'dnsrecord',
    user = 'root',
    password = '12345678',
    charset = 'utf8',
    max_packet_size = 1024 * 1024
}

if not ok then
    ngx.log(ngx.ERR, 'failed to connect: ', err, ': ', errcode, ' ', sqlstate)
    return
end

-- 将请求 host 赋值给 req_host 变量
local req_host = ngx.var.http_host

local select_sql = "select private_ip from dns_record where domain = '" .. req_host .. "'"
-- ngx.log(ngx.ERR, 'result_value: ', select_sql)
local res, err, errcode, sqlstate = db:query(select_sql)
if not res then
    ngx.log(ngx.ERR, 'bad result: ', err, ': ', errcode, ': ', sqlstate, '.')
    return
end

-- ngx.log(ngx.ERR, 'result_value: ', res[1].private_ip)

-- local dynamic_dns_servername = res[1].servername
local dynamic_dns_ip = res[1].private_ip

-- 赋值给设置好的 ngx 变量
-- ngx.var.dynamic_dns_servername = dynamic_dns_servername
ngx.var.dynamic_dns_ip = dynamic_dns_ip

-- 日志打印三级域名和对应 ip 值
-- ngx.log(ngx.ERR, 'result_value: ', dynamic_dns_servername)
ngx.log(ngx.ERR, 'result_value: ', dynamic_dns_ip)

-- put it into the connection pool of size 100,
-- with 10 seconds max idle timeout
local ok, err = db:set_keepalive(10000, 100)
if not ok then
    ngx.log('failed to set keepalive: ', err)
    return
end

-- or just close the connection right away:
-- local ok, err = db:close()
-- if not ok then
--     ngx.say("failed to close: ", err)
--     return
-- end

