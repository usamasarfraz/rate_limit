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
          {:deny, limit}
        else
          {:allow, count}
        end
      {:error, reason} ->
        {:error, reason}
    end
  end

  def update_rate(id, scale_ms, limit) do
    new_id = String.to_atom(id)
    Worker.update_limit_and_scale(new_id, scale_ms, limit)
  end

  def update_scale(id, scale_ms) do
    new_id = String.to_atom(id)
    Worker.update_scale(new_id, scale_ms)
  end

  def update_limit(id, limit) do
    new_id = String.to_atom(id)
    Worker.update_limit(new_id, limit)
  end

  defp call_worker(id, scale_ms) do
    args = %{"count_hit" => 1,"limit" => 10,"created_at" => Utils.timestamp,"updated_at" => Utils.timestamp,"last_seconds_hit" => 0,"id" => id,"scale_ms" => scale_ms,"expire" => Utils.timestamp + scale_ms}
    DynamicSupervisor.start_child(args)
    |> case do
      {:ok, _pid} ->
        {:ok, 1, 10}
      {:error, {:already_started, pid}} ->
        %{"count_hit" => count_hit, "limit" => limit} = Worker.count_hit(pid)
        {:ok, count_hit, limit}
      {:error, reason} ->
        {:error, reason}
    end
  end
end
