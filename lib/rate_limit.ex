defmodule RateLimit do
  alias RateLimit.Worker
  alias RateLimit.Utils
  alias RateLimit.DynamicSupervisor

  @spec check_rate(id :: String.t(), scale_ms :: integer, limit :: integer) ::
  {:allow, count :: integer}
  | {:deny, limit :: integer}
  | {:error, reason :: any}

  def check_rate(id, scale_ms, limit) do
    case call_worker(id, scale_ms) do
      {:ok, count} ->
        if count > limit do
          {:deny, limit}
        else
          {:allow, count}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp call_worker(id, scale_ms) do
    args = %{"count_hit" => 1,"created_at" => Utils.timestamp,"updated_at" => Utils.timestamp,"last_15_seconds_hit" => 0,"id" => String.to_atom(id), "scale_ms" => scale_ms}
    DynamicSupervisor.start_child(args)
    |> case do
      {:ok, _pid} ->
        {:ok, 1}
      {:error, {:already_started, pid}} ->
        %{"count_hit" => count_hit} = Worker.count_hit(pid)
        {:ok, count_hit}
    end
  end
end
