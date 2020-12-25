## proxy_lua
利用 `openresty` lua ，在业务负载均衡方面根据 body 中的数据做负载均衡，在动态域名映射方面根据对应的请求 host 找到绑定好的后端服务 ip:port

### 需求
1. 客户端请求中含有 json 格式数据，利用 **cjson** 模块进行 json 解析，根据 `method` 字段的值，负载均衡到对应的后端服务
     - `--data:` `[{"jsonrpc":"2.0","id":"rfBd67ti","method":"one","params":{"data":"xxxxxx","path":"custom/xxx/account"}}]`

     - 为了限制对应 `method` 和 `ngx.var.binary_remote_addr` 的访问量，使用了 **resty.limit.req** 模块进行限流
     
2. 根据数据库表关系，做到动态域名映射的功能
     - 数据库目前使用的是 **mysql** 进行存储动态域名转发的映射关系，所以使用了 **resty.mysql** 模块
     - 利用请求的 `ngx.var.http_host` 值进行数据库查询，找到对应的后端服务 **ip**


### 优化 & 问题
1. 为了更好的排查问题，在 nginx.conf 的 `access_log` 配置自定义 **set** 的字段值
2. 需要做日志分析，所以日志输出为 json 格式
3. 由于部署在外网出现了跨域之类的问题，所以在 location 中加了 **header_filter_by_lua_file lua/handle_core.lua** ，也需要根据需求，添加请求过来的部分头部，如 `nodehost`
4. 部署在线上环境中使用到了 **aws-elb**，所以在 nginx.conf 中配置了获取真实 ip 配置
   ```
   real_ip_header X-Forwarded-For;
   set_real_ip_from 172.31.0.0/16;
   ```
5. 由于请求体 json 数据有的是数组对象，所以在 **access.lua** 中使用了判断，判断是否数组对象


### roadmap
1. 后续需要支持 `websocket` 方式
2. 目前开放所有跨域请求 `*`，需要优化该问题
3. 限流方面的代码需要改善，需要将 `ip` 和 `method` 请求量区别开