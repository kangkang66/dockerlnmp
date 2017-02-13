local start_time = ngx.now();

--加载 json 库
local json = require "cjson.safe";
json.encode_empty_table_as_object(false);

--获取请求方式
local request_method = ngx.var.request_method;
--判断请求方式
if request_method ~= "POST" then
    ngx.say(json.encode({"only post"}));
    return;
end;

--读取 post 参数.表单需要是 x-www-form-urlencoded
ngx.req.read_body();
local api_p = ngx.req.get_post_args();
--拼接子请求
local list = {};
for api,p in pairs(api_p) do
    p = json.decode(p);
    if p ~= nil then
        p = ngx.encode_args(p);
    else
        p = "";
    end;
    local tmp = {api,{args=p,method=ngx.HTTP_GET}};
    table.insert(list, tmp);
end;
--发送子请求
local response = {ngx.location.capture_multi(list)};

--合并响应
local data = {};
local notice = {};
for num,up_resp in pairs(response) do
    resp = json.decode(up_resp["body"]);
    if resp ~= nil then
        data[resp["uri"]] = resp;
    else
        table.insert(notice, up_resp["body"]);
    end;
end;

if #notice > 0 then
    data["notice"] = notice;
end;

--计算耗时
data['duration'] = ngx.now() - start_time;
--响应到客户端
ngx.say(json.encode(data));