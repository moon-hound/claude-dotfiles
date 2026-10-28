FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY scripts/ scripts/
COPY prompts/ prompts/
COPY templates/ templates/

# Health check (checks /tmp/personal-assistant.health updated within 30s)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD test -f /tmp/personal-assistant.health && \
      test $(($(date +%s) - $(cat /tmp/personal-assistant.health))) -lt 30

CMD ["python3", "scripts/slack-listener.py"]
