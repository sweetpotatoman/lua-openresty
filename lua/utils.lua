local json = require("cjson")
-- local http = require "resty.http"

local _M = {}
-- 将字符串转换为table,如果转换失败,则返回nil
_M.json_decode = function(str) 
    local ok, t = pcall(json.decode, str)
    if not ok then
        return nil
    end
    return t
end

-- 将字符串转换为json,如果转换失败,则返回nil
_M.json_encode = function(str) 
    local ok, t = pcall(json.encode, str)
    if not ok then
        return nil
    end
    return t
end

-- 将文件读入到字符串内,不要读取大文件
_M.read_file_str = function(filename)
    local f = io.input(filename)
    local data = {}
    repeat
        line = io.read()
        if nil == line then
            break
        end
        table.insert(data, line)
    until(false)
    return table.concat(data, '\n')
end


-- _M.new_limit_req = function(sharedict, rate, brust)
--     return limit_req.new(sharedict, rate, brust)
-- end
-- local httpc = http.new();
-- _M.request_uri = function(host, params)
--     return httpc:request_uri(host, params)
-- end

_M.get_file_body = function(filename)
    local f = assert(io.open(filename, 'r'))
    local string = f:read("*all")
    f:close()
    return string
end


return _M