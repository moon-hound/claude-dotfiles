# Sentry Alert Configuration

Configure Sentry alert rules at https://sentry.io/settings/

## Recommended Alerts

### High Error Rate Alert
- **Condition:** Error rate > 5% over 5 minutes
- **Threshold:** 10 errors/minute
- **Action:** Email + Slack notification
- **Environment:** production

### Critical Error Alert
- **Condition:** Any error tagged `severity:critical`
- **Action:** Immediate email + Slack notification  
- **Environment:** production

### Service Degradation Alert
- **Condition:** > 3 ExternalServiceError in 1 minute (circuit breaker opening)
- **Action:** Email notification
- **Environment:** production

## Setup Steps

1. Log in to Sentry dashboard
2. Navigate to Settings → Alerts
3. Click "Create Alert Rule"
4. Configure conditions above
5. Set notification channels (email, Slack webhook)
6. Test alert triggering

## Notes

- Sentry DSN already configured in sentry_config.py
- Alerts require Sentry account with alert permissions
- Production environment must be set via ENVIRONMENT=production env var
