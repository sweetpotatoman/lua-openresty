local utils = require('/usr/local/openresty/nginx/lua/utils')
local proxy = require('/usr/local/openresty/nginx/lua/proxy')

proxy.rep_header()

ngx.req.read_body();

local grpc_request_uri = ngx.var.request_uri
local grpc_data = ngx.req.get_body_data()

if grpc_data == nil then
    local filename = ngx.req.get_body_file();
    if filename then
        grpc_data = utils.get_file_body(filename)
    end
end

proxy.rep_handler("http://xxx-filter.com", "grpc", {
    method = "POST",
    path = grpc_request_uri,
    body = grpc_data,
    headers = {
        ["port"] = "9090"
    },
    keepalive_timeout = 60000,
    keepalive_pool = 30,
    ssl_verify = false
})
