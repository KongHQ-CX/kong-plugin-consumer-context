# Consumer Context Plugin

This plugin enables the use of consumer level plugins when using Konnect App Auth to authenticate API requests using self service APIKeys. Consumers are hidden when using Konnect App Auth, therefore to allow plugins to be scoped to consumer a new consumer must be created and the context switched to this new consumer based on Application Id.

---

## **Key Features**
- **Dynamic Consumer Context Switching:**  
  Validates the initial consumer using Key Authentication and then changes the request context to a different consumer.

- **Enhanced Authentication Flow:**  
  Utilizes Kong’s built-in mechanisms (`kong.client.load_consumer`) to fetch and validate consumer entities and their associated credentials.

- **Integration with Rate Limiting:**  
  By changing the consumer context, the plugin enables the application of rate limiting policies to the new consumer.

---

## **Execution Flow**

1. The request arrives with a headers containing the API key.
2. The plugin retrieves the applicationid using the x-application-id header and loads a consumer with the same username.
3. The plugin updates Kong’s context by calling `kong.client.authenticate()` to authenticate with the located consumer and the existing credential.
5. The new consumer context is now active, allowing subsequent plugins (like rate limiting) to apply policies based on the updated consumer.

---

## **Configuration**

| Field Name                         | Type   | Description                                  | Default     |
|------------------------------------|--------|----------------------------------------------|-------------|
| `konnect_applicationId_header_name`             | string | Header containing the initial consumer name. | `"x-application-id"`   |
| `konnect_consumer_username_header_name`         | string | Header containing the applicationId + consumer customId. | `"x-consumer-username"`   |
| `add_consumer_username_header`                  | boolean | If selected will add request header for x-consumer-username. | `"false"`   |
| `reject_request_no_matching_consumer`           | boolean | If selected will reject a request where no consumer exists for the applicationId. | `"false"`   |

In order to use the plugin a consumer entity must be manually created with the username set to the value of the Konnect Dev Portal Application's ApplicationId. This can be retrieved in the dev portal when viewing the application by looking at the URI. Example: https://devportal.eu.portal.konghq.com/application/57610687-192c-4c37-a8e8-a357ac114af4 - In this case '57610687-192c-4c37-a8e8-a357ac114af4' is the application Id.

---

## **Execution Flow Diagram**

Below is a simple Markdown representation of the execution flow:
# Execution Flow Diagram

```plaintext
    Request
      │
      ▼
+-----------+
| Konnect Auth |   --> (Valid API Key)
| Plugin    |       --> (Invalid API Key: 401 Unauthorized)
+-----------+
      │
      ▼
+-----------------+
| Your-Consumer-  |       --> (Consumer Not Found: Allow call but don't map to a consumer)
| Context Plugin  |       --> (Valid Consumer)
+-----------------+
      │
      ▼
  Updated Context
      │
      ▼
+--------------------+
| Rate Limiting     |  
| (Consumer-Specific)|
+--------------------+
      │
      ▼
  Forward Request
