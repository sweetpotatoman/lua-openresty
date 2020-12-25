local json = require("cjson")
-- local limit_req = require('resty.limit.req')

local _M = {}
-- 将字符串转换为table,如果转换失败,则返回nil
_M.json_decode = function(str) 
    local ok, t = pcall(json.decode, str)
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

return _M