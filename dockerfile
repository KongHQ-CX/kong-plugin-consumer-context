FROM kong/kong-gateway:latest

# Ensure any patching steps are executed as root user
USER root

# Add custom plugin to the image
COPY kong/plugins/consumer-context /usr/local/share/lua/5.1/kong/plugins/consumer-context
ENV KONG_PLUGINS=bundled,consumer-context

# Ensure kong user is selected for image execution
USER kong

# Run kong
ENTRYPOINT ["/entrypoint.sh"]
EXPOSE 8000 8443 8001 8444
STOPSIGNAL SIGQUIT
HEALTHCHECK --interval=10s --timeout=10s --retries=10 CMD kong health
CMD ["kong", "docker-start"]
