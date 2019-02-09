JSON = require "rapidjson"

if ngx.req.get_method() == "POST" then
  ngx.req.read_body() -- explicitly read the req body
  local body = ngx.req.get_body_data()
  if body then
    -- parse JSON data sent via POST
    local decoded = JSON.decode(body)
    ngx.log(ngx.WARN, 'Received: ' .. JSON.encode(decoded))

    if (not(ngx.var.queue_id == decoded.queueId and ngx.var.user_id == decoded.userId)) then
      ngx.status = ngx.HTTP_NOT_ACCEPTABLE
      ngx.say("Invalid request")
      ngx.exit(ngx.HTTP_NOT_ACCEPTABLE)
    end

    -- extract only the data section of the notification
    local data = decoded.data

    -- build message JSON
    local message = {}
    message.default = JSON.encode(data.notification_payload, {pretty=true})
    ngx.log(ngx.WARN, 'Message: ' .. JSON.encode(message))

    -- build CLI input JSON
    local input = {}
    input.MessageStructure = 'json'
    input.TopicArn = ngx.var.sns_topic_arn
    ngx.log(ngx.WARN, 'Topic ARN: ' .. ngx.var.sns_topic_arn)
    -- input.Subject = 'Anchore Engine: ' .. data.notification_payload.subscription_key .. ' ' .. data.notification_type .. ' notification'
    input.Message = JSON.encode(message)
    input.MessageAttributes = {}
    input.MessageAttributes.notification_type = {}
    input.MessageAttributes.notification_type.DataType = 'String'
    input.MessageAttributes.notification_type.StringValue = data.notification_type
    input.MessageAttributes.subscription_key = {}
    input.MessageAttributes.subscription_key.DataType = 'String'
    input.MessageAttributes.subscription_key.StringValue = data.notification_payload.subscription_key
    ngx.log(ngx.WARN, 'CLI Input: ' .. JSON.encode(input))

    -- save CLI input JSON to file
    local inputSnsPublish = os.tmpname()
    JSON.dump(input, inputSnsPublish)

    -- execute aws sns publish command return exit code and output
    local outputSnsPublish = os.tmpname()
    local status = os.execute('aws sns publish --region ' .. ngx.var.aws_region .. ' --cli-input-json file://' .. inputSnsPublish .. ' >' .. outputSnsPublish .. ' 2>&1')
    local retOutput = io.open(outputSnsPublish, "r"):read("*a")
    os.remove(outputSnsPublish)
    os.remove(inputSnsPublish)

    local retCode = status / 256
    if (retCode > 0) then
      ngx.log(ngx.ERR, 'Error: ' .. retOutput)
      ngx.status = ngx.HTTP_BAD_GATEWAY
      ngx.header['Content-Type'] = 'text/plain'
    else
      ngx.log(ngx.WARN, 'SNS Response: ' .. JSON.encode(JSON.decode(retOutput)))
      ngx.status = ngx.HTTP_OK
      ngx.header['Content-Type'] = 'application/json'
    end
    ngx.header["Content-Length"] = #retOutput
    ngx.print(retOutput)
  end
end
