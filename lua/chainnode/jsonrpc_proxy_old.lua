local utils = require('/usr/local/openresty/nginx/lua/utils')
local limit_req = require "resty.limit.req"
local json_decode = utils.json_decode
local json_content = utils.read_file_str('/usr/local/openresty/nginx/lua/chainnode/jsonrpc_mapping_old.json')

local methods = json_decode(json_content)

local function get_paths(method)
    return methods[method]
end

local function contains_tal(type, key, table)
    for k,v in pairs(table) do
        if type == 'key' then
            if k == key then
                return true;
            end
        else
            if v == key then
                return true;
            end
        end
    end
    return false
end

local function contains_method(method)
    return contains_tal('key', method, methods)
end

local function contains_path(path, table)
    return contains_tal('value', path, table)
end

local function white_list(method, path)
    if not contains_method(method) then
        ngx.log(ngx.ERR, "Cannot match a specific method, method: ", method)
        return ngx.exit(431)
    end

    if method ~= 'genesis' and not contains_path(path, get_paths(method)) then
        ngx.log(ngx.ERR, "Cannot match the specific path, path: ", path)
        return ngx.exit(432)
    end
end

local defaultLimit = limit_req.new("jsonrpc_default_limit", 5, 5)
local delay, err = defaultLimit:incoming(ngx.var.binary_remote_addr, true)
if not delay then
    if err == 'rejected' then
        ngx.log(ngx.ERR, "Rate rejected")
        return ngx.exit(429)
    end
    return ngx.exit(500)
end

-- ngx.log(ngx.ERR, "delay: ", delay)
if delay >= 0.001 then
    ngx.sleep(delay)
end

ngx.req.read_body();

local jsonrpc_data = ngx.req.get_body_data()
if jsonrpc_data ~= nil then
    local jsonrpc_t = json_decode(jsonrpc_data)
    local method = jsonrpc_t.method
    if jsonrpc_t.params ~= nil then
        local path = jsonrpc_t.params.path
        white_list(method, path)
    else
        -- ngx.log(ngx.ERR, "Request body no containers params")
        return ngx.exit(443)
    end
    -- ngx.log(ngx.ERR, "body_method: " .. method)
    -- ngx.log(ngx.ERR, "body_params_path: " .. path)
else
    -- ngx.log(ngx.ERR, "No request body")
    return ngx.exit(443)
end