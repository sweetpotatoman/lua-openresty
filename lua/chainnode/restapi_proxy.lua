local proxy = require('/usr/local/openresty/nginx/lua/proxy')

proxy.rep_header()

if ngx.var.request_uri ~= nil then
    proxy.rep_handler("http://xxx-filter.com", "restapi", {
        method = "POST",
        path = ngx.var.request_uri,
        headers = {
            ["port"] = "1317"
        },
        keepalive_timeout = 60000,
        keepalive_pool = 30,
        ssl_verify = false
    })
else
    return ngx.exit(443)
end