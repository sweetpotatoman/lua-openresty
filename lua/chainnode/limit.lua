local limit_req = require "resty.limit.req"

local _M = {}

local limit_params = {
    {200, 10},
    {100, 5},
}

local defaultLimit = limit_req.new("default_limit", 300, 10)

local limit_table = {}
for index, value in ipairs(limit_params) do
    -- ngx.log(ngx.ERR, "index: ", index, "; value[1]: ", value[1], "; value[2]: ", value[2])
    limit_table[index] = limit_req.new("limit"..index, value[1], value[2])
end

_M.limit = function(index)
    index = tonumber(index)
    ngx.var.speedLimitClass = index

    -- if not index or index < 1 or index > #limit_table then
    --     if index == 0 then
    --         return defaultLimit
    --     end
    --     ngx.log(ngx.ERR, "speedLimitClass is not a prescribed value, speedLimitClass:" , index, ", Access Denied")
    --     return ngx.exit(430)
    -- end
    -- return limit_table[index]

    if  index == 1 or index ==2 then
        return limit_table[index]
    else
        return defaultLimit
    end
end

return _M
