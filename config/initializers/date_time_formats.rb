# Show times as am/pm instead of 24 hour
Time::DATE_FORMATS[:time] = '%l:%M%P'
Time::DATE_FORMATS[:time_utc] = '%H:%M:%S'

# TODO we may need this is the APIs are outputting millisecond precision and it causes an issue:
#ActiveSupport::JSON::Encoding.time_precision = 0
