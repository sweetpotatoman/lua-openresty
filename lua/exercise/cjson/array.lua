local json = require("cjson")
--function json_decode(str)
--    local ok, t = pcall(json.decode, str)
--    if not ok then
--        return nil
--    end
--    return t
--end


local body_data = ngx.req.get_body_data()
local data = json.decode(body_data)

if data[1] ~= nil then
  for i, w in ipairs(data) do
    ngx.say("array-method: ",  w.method);
    --ngx.say("params.data: ", w.params.data);
  end
else
  local t = data.method
  ngx.say("json-method: ", t)
end
--if t ~= nil then
--    ngx.say("method:", t.method)
--end
--ngx.say("--->", type(t))
--ngx.say("Hello ", data)