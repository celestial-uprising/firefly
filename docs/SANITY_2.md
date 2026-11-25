podman run --rm localhost/bella:latest \
  find /usr/bin /usr/lib /usr/lib64 /usr/share /etc -xtype l 2>/dev/null
