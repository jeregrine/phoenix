defmodule Phoenix.Endpoint.Metrics do
  @moduledoc """
  A plug for tracking basic request metrics

  To use it, just plug it into the desired module.

  plug Phoenix.Endpoint.Metrics
  """

  @behaviour Plug

  def init(_opts) do
    get_metrics_module()
  end

  def call(conn, mod) do
    mod.increment_counter([:phoenix, :total_requests]) 
    mod.increment_counter([:phoenix, :running_requests]) 
    mod.increment_counter([:phoenix, :request, conn.method, conn.request_path]) 

    before_time = :os.timestamp()

    Plug.Conn.register_before_send(conn, fn conn ->
      after_time = :os.timestamp()
      diff = div(:timer.now_diff(after_time, before_time), 1000)

      mod.update_histogram([:phoenix, :request_time, conn.method, conn.request_path], diff)
      mod.decrement_counter([:phoenix, :running_requests]) 
      mod.increment_counter([:phoenix, :finished_requests]) 
      conn
    end)
  end

  defp get_metrics_module() do
    Application.get_env(:phoenix, :mod_metrics, Phoenix.Metrics.Dummy)
  end
end
