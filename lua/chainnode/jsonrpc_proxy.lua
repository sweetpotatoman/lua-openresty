local proxy = require('/usr/local/openresty/nginx/lua/proxy')

proxy.rep_header()

ngx.req.read_body();

local jsonrpc_data = ngx.req.get_body_data()
local jsonrpc_method = ngx.var.request_method
local jsonrpc_path = ngx.var.request_uri

proxy.rep_handler("http://xxx-filter.com", "jsonrpc", {
    method = jsonrpc_method,
    path = jsonrpc_path,
    body = jsonrpc_data,
    headers = {
        ["port"] = "26657"
    },
    keepalive_timeout = 60000,
    keepalive_pool = 30,
    ssl_verify = false
})
