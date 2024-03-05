defmodule RateLimit.Worker do
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

  def handle_call({:count_hit}, _from, state) do
    updated_state = Map.update!(state, "count_hit", fn count -> count + 1 end)
    {:reply, updated_state, updated_state}
  end

  def handle_info({:interval, time_ms}, state) do
    updated_state = %{state | "count_hit" => 0}
    schedule_call(time_ms)
    {:noreply, updated_state}
  end

  defp schedule_call(time_ms) do
    Process.send_after(self(), {:interval, time_ms}, time_ms)
  end
end
