defmodule Phoenix.Metrics.Dummy do
  def new(_type, _name) do
    :ok
  end

  def delete(_name) do
    :ok
  end

  def increment_counter(_name, value \\ 1) do
    :ok
  end

  def decrement_counter(_name, value \\ -1) do
    :ok
  end

  def update_histogram(_name, value) when is_number(value) do
    :ok
  end
  def update_histogram(_name, fun) when is_function(fun) do
    :ok
  end
end
