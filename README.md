## Lua-openresty
我使用 `openresty` 和 `lua` 在公司的业务做一些逻辑处理
- 对链节点的请求进行预处理  
  - 处理 `grpc、jsonrpc、restapi` 请求，通过请求的数据进行分级限流或拒绝访问
- 动态域名映射  
  - 在动态域名映射方面根据对应的请求 **host** 找到绑定好的后端服务 `ip:port`
  - 限流策略


### 需求
1. ~~客户端 `post` 请求中含有 json 格式数据，利用 **cjson** 模块进行 json 解析，根据数据中 `method` 字段的值，负载均衡到对应的后端服务 `(old)`~~
     - `--data:` `[{"jsonrpc":"2.0","id":"rfBd67ti","method":"one","params":{"data":"xxxxxx","path":"custom/xxx/account"}}]`

     - 为了限制对应 `method` 和 `ngx.var.binary_remote_addr` 的访问量，使用了 **resty.limit.req** 模块进行限流
     
2. ~~根据数据库表关系，做到动态域名映射的功能 `(old)`~~
     - 数据库目前使用的是 **mysql** 进行存储动态域名转发的映射关系，所以使用了 **resty.mysql** 模块
     - 利用请求的 `ngx.var.http_host` 值进行数据库查询，找到对应的后端服务 **ip**

3. 通过调用后端服务查询区块浏览器信息，做到动态映射的功能 (替换之前直接使用查询本地数据库的方法)
    - 约定环境的域名标示，通过标示识别去对应的环境后端服务进行请求
    - 向后端服务申请 **client** 认证信息，通过 **client secret** 和数据 `(ngx.var.http_host)` 进行签名加密查询关键数据 **ip**

4. 该网关支持 `grpc/jsonrpc/restapi` 的方式请求链节点，在反向代理到节点时需要先对请求的路径和请求信息进行一个预处理
    - 不同请求协议都通过一个过滤器服务进行处理，该服务由业务人员进行控制
    - 通过请求过滤器服务得到响应，通过响应数据中的限速等级做对应的限速或拒绝处理

### 优化 & 问题
1. ~~由于部署在外网出现了跨域之类的问题，所以在 location 中加了 **header_filter_by_lua_file lua/handle_core.lua** ，也需要根据需求，添加请求过来的部分头部，如 `nodehost`. `(old)`~~
2. ~~由于请求体 json 数据有的是数组对象，所以在 **access.lua** 中使用了判断，判断是否数组对象. `(old)`~~

### 依赖相关库
- https://github.com/ledgetech/lua-resty-http
- https://github.com/openresty/lua-resty-limit-traffic
- https://github.com/openresty/lua-resty-redis
- https://github.com/openresty/lua-resty-shell
- https://github.com/ledgetech/lua-resty-mysql

### roadmap
- [x] openresty 日志输出为 json 格式方便日志收集，增加部分字段值进行数据分析
- [x] 部署在线上环境中使用到了 **aws-elb**，所以在 nginx.conf 中配置了获取真实 ip 配置
- [x] 获取动态域名映射功能需要优化，使用直接调用后端服务方式进行查询映射关系 **(后端数据库提供映射表关系)**
- [x] 后续需要支持 `websocket` 方式，如果 ws 请求也需要进行对应的负载均衡方式，则需要在头部进行判断
- [x] 提供 `get` 请求方式访问
- [ ] 将 openresty rpc 部署在 k8s 集群中 **(当 chain-node 服务迁移至 eks 集群时)**