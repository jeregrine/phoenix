defmodule Phoenix.Endpoint.MetricsTest do
  use ExUnit.Case, async: false
  use RouterHelper
  alias Phoenix.Endpoint.Metrics

  defmodule TestMetrics do
    def start_link() do
      Agent.start_link(fn -> %{} end, name: __MODULE__)
    end

    def get_state() do 
      Agent.get(__MODULE__, fn state -> state end)
    end

    def increment_counter(name, value \\ 1) do
      log(name, value)
    end

    def decrement_counter(name, value \\ -1) do
      log(name, value)
    end

    def update_histogram(name, value) do
      log(name, value)
    end

    defp log(name, value) do
      Agent.update(__MODULE__, fn state -> 
        Map.update(state, name, [value], fn(val) -> val ++ [value] end)
      end)
    end
  end

  setup_all do
    Application.put_env(:phoenix, :mod_metrics, Phoenix.Endpoint.MetricsTest.TestMetrics)

    on_exit fn ->
      Application.put_env(:phoenix, :mod_metrics, Phoenix.Metrics.Dummy)
    end
  end

  setup do
    TestMetrics.start_link()
    :ok
  end

  test "that when I call the Endpoint Metrics it logs appropiate metrics" do
    test_conn = conn(:get, "/hello")
    |> action()

    state = TestMetrics.get_state()

    sum_state = fn(state, key) -> 
      items = Map.get(state, key)
      {Enum.reduce(items, &(&1 + &2)), items}
    end

    assert sum_state.(state, [:phoenix, :total_requests]) == {1, [1]}
    assert sum_state.(state, [:phoenix, :running_requests]) == {0, [1, -1]}
    assert sum_state.(state, [:phoenix, :request, test_conn.method, test_conn.request_path]) == {1, [1]}
    assert sum_state.(state, [:phoenix, :finished_requests]) == {1, [1]}

    timing = Map.get(state, [:phoenix, :request_time, test_conn.method, test_conn.request_path])
    assert Enum.count(timing) == 1
    assert timing[0] > 0
  end


  defp action(conn) do
    Metrics.call(conn, Metrics.init(:index))
    |> Plug.Conn.send_resp(200, "Passthrough")
  end
end
