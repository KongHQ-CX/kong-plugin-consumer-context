local kong = kong
local http = require "resty.http"
local cjson = require "cjson.safe"

local plugin = {
    PRIORITY = 949,
    VERSION = "0.1",
}

local function get_application_name(application_id, konnect_api_token)
    local httpc = http.new()
    local res, err = httpc:request_uri(
        "https://eu.api.konghq.com/v3/applications/" .. application_id,
        {
            method = "GET",
            headers = {
                ["Authorization"] = "Bearer " .. konnect_api_token,
            },
        }
    )

    if err then
        kong.log.err("Error when trying to access Konnect API: ", err)
        return nil, err
    end

    local body_table, decode_err = cjson.decode(res.body)
    if decode_err then
        kong.log.err("Error when decoding Konnect API response: ", decode_err)
        return nil, decode_err
    end

    kong.log.notice("All body_table: ", body_table)
    return body_table.name
end

function plugin:access(plugin_conf)
    -- keep the existing credential used to authenticate
    local existing_credential = kong.client.get_credential()
    if not existing_credential then
        return kong.response.exit(401, { message = "Unauthorized: Credential not found" })
    end

    -- read the x-application-id header which contains the Dev Portal ApplicationId
    local application_id = kong.request.get_header(plugin_conf.konnect_applicationId_header_name)
    kong.log.notice("ApplicationId: ", application_id)

    local consumer_name = application_id
    local mapping = plugin_conf.application_consumer_mapping or "application_id"

    -- If mapping requires the application name, resolve it via the Konnect API
    if mapping == "application_name" or mapping == "application_id_or_name" then
        local app_name, err = get_application_name(application_id, plugin_conf.konnect_api_token)
        if err then
            return kong.response.exit(500, { message = "Error retrieving application details from Konnect" })
        end
        if app_name then
            kong.log.notice("Application name resolved: ", app_name)
            consumer_name = app_name
        end
    end

    -- Load the consumer entity
    local consumer_entity = kong.client.load_consumer(consumer_name, true)
    kong.log.inspect(consumer_entity, "Consumer entity loaded: ")

    -- For application_id_or_name: fall back to application_id if name lookup found no consumer
    if not consumer_entity and mapping == "application_id_or_name" and consumer_name ~= application_id then
        kong.log.info("Consumer not found by name, falling back to application_id: ", application_id)
        consumer_entity = kong.client.load_consumer(application_id, true)
        consumer_name = application_id
    end

    if not consumer_entity then
        kong.log.info("No matching consumer for application: ", consumer_name)
        if plugin_conf.reject_request_no_matching_consumer then
            return kong.response.exit(401, { message = "Unauthorized: Consumer not found for application" })
        end
    else
        kong.log.info("Loaded Consumer: ", consumer_name)
        if consumer_entity.custom_id and plugin_conf.add_consumer_username_header then
            -- add header with consumer custom_id
            local consumer_username = (consumer_name .. '_' .. consumer_entity.custom_id)
            kong.service.request.set_header(plugin_conf.konnect_consumer_username_header_name, consumer_username)
            kong.log.info("Loaded Consumer with custom_id: ", consumer_entity.custom_id)
        end
        -- Authenticate the consumer using the located consumer and the existing_credential
        kong.client.authenticate(consumer_entity, existing_credential)
        kong.log.info("Consumer authenticated successfully.")
    end
end

return plugin
