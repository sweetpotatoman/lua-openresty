--ngx.req.read_body()
--local data = ngx.req.get_body_data()
--ngx.say("hello ", data)

local json = require("cjson")
function json_decode(str)
    local ok, t = pcall(json.decode, str)
    if not ok then
        return nil
    end
    return t
end

local data = ngx.req.get_body_data()
local t = json_decode(data)

if t ~= nil then
    ngx.say("method:", t.method)
end
ngx.say("--->", type(t))
ngx.say("Hello ", data)
