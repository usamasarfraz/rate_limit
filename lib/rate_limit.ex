defmodule RateLimit do
  alias RateLimit.Worker
  alias RateLimit.Utils
  alias RateLimit.DynamicSupervisor

  @spec check_rate(id :: String.t()) ::
  {:allow, count :: integer}
  | {:deny, limit :: integer}
  | {:error, reason :: any}

  def check_rate(id) do
    new_id = String.to_atom(id)
    case call_worker(new_id, 60000) do
      {:ok, count, limit} ->
        if count > limit do
          {:deny, limit, "limit exceed."}
        else
          {:allow, count, "user allowed."}
        end
      {:warning, limit} ->
        {:deny, limit, "hit too many requests."}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec update_rate(id :: String.t(), scale_ms :: integer, limit :: integer) ::
  {:ok, limit :: integer, scale_ms :: integer}

  def update_rate(id, scale_ms, limit) do
    %{"limit" => limit, "scale_ms" => scale_ms} =
    String.to_atom(id)
    |> Worker.update_limit_and_scale(scale_ms, limit)
    {:ok, limit, scale_ms}
  end

  @spec update_scale(id :: String.t(), scale_ms :: integer) ::
  {:ok, scale_ms :: integer}

  def update_scale(id, scale_ms) do
    %{"scale_ms" => scale_ms} =
    String.to_atom(id)
    |> Worker.update_scale(scale_ms)
    {:ok, scale_ms}
  end

  @spec update_limit(id :: String.t(), limit :: integer) ::
  {:ok, limit :: integer}

  def update_limit(id, limit) do
    %{"limit" => limit} =
    String.to_atom(id)
    |> Worker.update_limit(limit)
    {:ok, limit}
  end

  defp call_worker(id, scale_ms) do
    %{"count_hit" => 1,"limit" => 10,"created_at" => Utils.timestamp,"updated_at" => Utils.timestamp,"last_seconds_hit" => 0,"id" => id,"scale_ms" => scale_ms,"expire" => Utils.timestamp + scale_ms}
    |> DynamicSupervisor.start_child()
    |> case do
      {:ok, _pid} ->
        {:ok, 1, 10}
      {:error, {:already_started, pid}} ->
        Worker.count_hit(pid)
        |> check_last_second_hits()
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp check_last_second_hits(%{"count_hit" => count_hit, "limit" => limit, "last_seconds_hit" => last_seconds_hit}) do
    if last_seconds_hit >= limit do
      {:warning, limit}
    else
      {:ok, count_hit, limit}
    end
  end
end
