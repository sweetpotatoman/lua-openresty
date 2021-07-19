local utils = require('/usr/local/openresty/nginx/lua/utils')

local json_content = utils.read_file_str('/usr/local/openresty/nginx/lua/chainnode/jsonrpc_mapping_old.json')

local config = utils.json_decode(json_content)

return config
