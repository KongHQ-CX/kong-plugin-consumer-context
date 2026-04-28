local typedefs = require "kong.db.schema.typedefs"


local PLUGIN_NAME = "consumer-context"


local schema = {
  name = PLUGIN_NAME,
  fields = {
    { consumer = typedefs.no_consumer },  
    { protocols = typedefs.protocols_http },
    { config = {
        type = "record",
        fields = {
          { konnect_applicationId_header_name = typedefs.header_name {
              required = true,
              default = "x-application-id" } },
          { konnect_api_token = {
              description = "Konnect API token used to resolve application name via the Konnect API",
              type = "string",
              required = false,
              encrypted = true } },
          { application_consumer_mapping = {
              description = "How to map a Konnect application to a Kong consumer: by application_id (default), application_name (resolved via Konnect API), or application_id_or_name (tries name first, falls back to id)",
              type = "string",
              required = false,
              one_of = { "application_id", "application_name", "application_id_or_name" },
              default = "application_id" } },
          { konnect_consumer_username_header_name = {
              type = "string",
              required = true,
              default = "x-consumer-username" } },
          { add_consumer_username_header = {
              description = "Output consumer.username + '_' + consumer.customId as a header",
              type = "boolean",
              required = false,
              default = false } },
          { reject_request_no_matching_consumer = {
              description = "Reject requests when no consumer can be loaded for the applicationId",
              type = "boolean",
              required = false,
              default = false } },
        },
      },
    },
  },
}

return schema