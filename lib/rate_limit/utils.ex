defmodule RateLimit.Utils do
  # Returns Erlang Time as milliseconds since 00:00 GMT, January 1, 1970
  def timestamp do
    DateTime.to_unix(DateTime.utc_now(), :millisecond)
  end
end
