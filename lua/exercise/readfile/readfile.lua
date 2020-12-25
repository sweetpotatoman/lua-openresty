function FileRead()
	local file = io.open("/usr/local/openresty/nginx/lua/gui-config.json", "r");
	local json = file:read("*a");
	file:close();
	return json;
end

function FileWrite()
	local file = io.open("/usr/local/openresty/nginx/lua/gui-config.json", "w");
	file:close();
end

local cjson = require("cjson");
local file = FileRead();
local json = cjson.decode(file);
for i, w in ipairs(json.configs) do
	ngx.say("server: " .. w.password)
	ngx.say("server_port: " .. w.server_port)
	ngx.say("password: " .. w.password)
	ngx.say("method: " .. w.method .. '\n')
end
