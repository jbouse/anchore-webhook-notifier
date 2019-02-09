JSON = require "rapidjson"

local outputSnsPublish = os.tmpname()
local status = os.execute('aws sns list-topics --region ' .. ngx.var.aws_region .. ' >' .. outputSnsPublish .. ' 2>&1')
local retOutput = io.open(outputSnsPublish, "r"):read("*a")
os.remove(outputSnsPublish)

local retCode = status / 256
if (retCode > 0) then
  ngx.log(ngx.ERR, 'Error: ' .. retOutput)
  ngx.status = ngx.HTTP_SERVICE_UNAVAILABLE
  ngx.header['Content-Type'] = 'text/plain'
else
  ngx.log(ngx.INFO, 'SNS Response: ' .. JSON.encode(JSON.decode(retOutput)))
  ngx.status = ngx.HTTP_OK
  ngx.header['Content-Type'] = 'application/json'
end
ngx.header["Content-Length"] = #retOutput
ngx.print(retOutput)
