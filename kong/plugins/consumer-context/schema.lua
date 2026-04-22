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