local utils = require('/usr/local/openresty/nginx/lua/utils')
local limit = require('/usr/local/openresty/nginx/lua/limit');
local http = require "resty.http"

local json_decode = utils.json_decode
local json_encode = utils.json_encode

local _P = {}

_P.rep_header = function()
    ngx.header["content-type"] = "application/json"
end

_P.rep_handler = function(host, req_protocol, req_para)
    -- api filter host
    -- request params
    local httpc = http.new();
    local res, err = httpc:request_uri(host, req_para)

    if not res then
        ngx.log(ngx.ERR, "Request failed: May be need u look api server", "err: ", err)
        return ngx.exit(499)
    end

    -- ngx.header["content-type"] = res.headers["Content-Type"]

    ngx.log(ngx.ERR, "res-body:", res.body)
    local speedLimitClass = tonumber(res.headers["speedLimitClass"])
    ngx.log(ngx.ERR, "speedLimitClass: ", speedLimitClass)
    if speedLimitClass == 9  or speedLimitClass == -1 then
        if req_protocol == 'grpc' then
            ngx.header["content-type"] = "application/grpc"
            ngx.header["grpc-message"] = res.headers["grpc-message"]
            ngx.header["grpc-status"] = res.headers["grpc-status"]
            return ngx.exit(tonumber(res.headers["grpc-status"]))
	end
	ngx.say(res.body)
	return ngx.exit(200)
    end

    -- ngx.log(ngx.ERR, speedLimitClass)
    if speedLimitClass ~= nil then

        local rateLimit = limit.limit(speedLimitClass)
        local delay, err = rateLimit:incoming(ngx.var.binary_remote_addr, true)

        if not delay then
            if err == 'rejected' then
                ngx.log(ngx.ERR, "Rate rejected")
                ngx.say(json_encode({
                    code = 20003,
                    msg = "You're doing it too frequently",
                    data = {}
                }))
                return ngx.exit(200)
            end
            return ngx.exit(500)
        end

        if delay >= 0.001 then
            ngx.sleep(delay)
        end
    end

    -- if req_protocol == 'grpc' then
    --    ngx.header["grpc-message"] = res.headers["grpc-message"]
    --	ngx.exit(res.headers["grpc-status"])
    end
    -- ngx.say(res.body)
-- end

return _P