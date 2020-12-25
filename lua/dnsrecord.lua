local http = require "resty.http"
local cjson = require "cjson"

local _M = {}

function _M:new(o)
    -- 初始化，防止o（table）为空
    o = o or {}
    -- sefl为o的原型
    setmetatable(o, self)
    self.__index = self
    -- 返回创建的实例，此时o将具备 _M 的所有对象
    return o
end

local function http_conn_post(self, request_uri, params)
    local body_str = cjson.encode(params)
    local httpc = http.new();
    local res, err = httpc:request_uri(self.host..self.root..request_uri, {
        method = "POST",
        body = body_str,
        headers = {
            ["Content-Type"] = "application/json",
        },
        keepalive_timeout = 60000,
        keepalive_pool = 10,
        ssl_verify = false,
    })
    -- ngx.log(ngx.ERR, res.body)
    local resp = cjson.decode(res.body)
    return resp;
end

local function http_conn_get(self, request_uri)
    ngx.log(ngx.ERR, "log:", self.host..self.root..request_uri)
    local httpc = http.new();
    local res, err = httpc:request_uri(self.host..self.root..request_uri, {
        method = "GET",
        keepalive_timeout = 60000,
        keepalive_pool = 10,
        ssl_verify = false,
    })
    -- ngx.log(ngx.ERR, res.body)
    local resp = cjson.decode(res.body)
    return resp;
end

-- sha256加密
function _M:sign(data)
    local resty_sha256 = require "resty.sha256"
    local str = require "resty.string"
    local sha256 = resty_sha256:new()
    if sha256:update(""..data..self.client_secret.."") then
        local digest = sha256:final()
        local signature = str.to_hex(digest)
        return signature
    end
end

function _M:pre(domain)
    local params = {clientId=self.client_id, domain=domain}
    return http_conn_post(self, "/pre", params);
end

function _M:query(domain, nonce, timestamp, signature)
    local params = {clientId=self.client_id, domain=domain, nonce=nonce, timestamp=timestamp, signature=signature}
    return http_conn_post(self, "/", params);
end

function _M:chaindnsrecord(request_uri)
    request_uri = "/"..request_uri
    return http_conn_get(self, request_uri);
end

return _M