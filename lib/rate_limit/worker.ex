defmodule RateLimit.Worker do
  alias RateLimit.Utils
  use GenServer

  def start_link(%{"id" => id} = args) do
    GenServer.start_link(__MODULE__, args, name: id)
  end

  def init(%{"scale_ms" => scale_ms} = state) do
    schedule_call(scale_ms)
    {:ok, state}
  end

  def count_hit(pid) do
    GenServer.call(pid, {:count_hit})
  end

  def update_limit_and_scale(id, scale_ms, limit) do
    GenServer.call(id, {:update_limit_and_scale, scale_ms, limit})
  end

  def update_limit(id, limit) do
    GenServer.call(id, {:update_limit, limit})
  end

  def update_scale(id, scale_ms) do
    GenServer.call(id, {:update_scale, scale_ms})
  end

  def handle_call({:count_hit}, _from, %{"expire" => expire_at, "count_hit" => count_hit, "last_seconds_hit" => last_seconds_hit} = state) do
    if expire_at - Utils.timestamp <= 15000 do
      updated_state = %{state | "count_hit" => count_hit + 1, "last_seconds_hit" => last_seconds_hit + 1}
      {:reply, updated_state, updated_state}
    else
      updated_state = %{state | "count_hit" => count_hit + 1}
      {:reply, updated_state, updated_state}
    end
  end

  def handle_call({:update_limit_and_scale, scale_ms, limit}, _from, state) do
    updated_state = %{state | "limit" => limit, "scale_ms" => scale_ms}
    {:reply, updated_state, updated_state}
  end

  def handle_call({:update_limit, limit}, _from, state) do
    updated_state = %{state | "limit" => limit}
    {:reply, updated_state, updated_state}
  end

  def handle_call({:update_scale, scale_ms}, _from, state) do
    updated_state = %{state | "scale_ms" => scale_ms}
    {:reply, updated_state, updated_state}
  end

  def handle_info({:interval, time_ms}, state) do
    updated_state = %{state | "count_hit" => 0, "expire" => Utils.timestamp + time_ms}
    schedule_call(time_ms)
    clear_last_seconds_hit(15000)
    {:noreply, updated_state}
  end

  def handle_info(:clear, state) do
    updated_state = %{state | "last_seconds_hit" => 0}
    {:noreply, updated_state}
  end

  defp schedule_call(time_ms) do
    Process.send_after(self(), {:interval, time_ms}, time_ms)
  end

  defp clear_last_seconds_hit(time_ms) do
    Process.send_after(self(), :clear, time_ms)
  end
end
