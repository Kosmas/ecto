defmodule Ecto.Adapters.Mysql.Worker do
  @moduledoc false

  use GenServer

  @timeout 5000

  alias Ecto.Adapters.Mysql.Result
  alias Ecto.Adapters.Mysql.OkPacket
  alias Ecto.Adapters.Mysql.Error

  def start(args) do
    :gen_server.start(__MODULE__, args, [])
  end

  def start_link(args) do
    :gen_server.start_link(__MODULE__, args, [])
  end

  def query!(worker, sql, params, timeout \\ @timeout) do #compare
    handle_query(:gen_server.call(worker, { :query, sql, params, timeout }, timeout))
  end

  def handle_query({:result_packet, _, _, rows, _ }) do
    %Result{rows: rows, num_rows: Enum.count(rows)}
  end

  def handle_query({:ok_packet, _seq_num, nrows, insert_id, _status, _warning_message, msg }) do
    %OkPacket{num_rows: nrows, insert_id: insert_id, msg: msg}
  end

  def handle_query({:error_packet, _seq_num, _code, _, msg}) do
    %Error{msg: msg}
  end

  def monitor_me(worker) do
    :gen_server.cast(worker, { :monitor, self })
  end

  def demonitor_me(worker) do
    :gen_server.cast(worker, { :demonitor, self })
  end

  def init(opts) do
    Process.flag(:trap_exit, true)

    eager? = Keyword.get(opts, :lazy, true) in [false, "false"]

    if eager? do 
      pool = Keyword.get(opts, :pool_name)
      request = Keyword.get(opts, :request)
      from = Keyword.get(opts, :from)
      case connection(opts, request, from, new_state) do
        :ok ->
          conn = pool
        _ ->
          :ok
      end
    end
    {:ok, Map.merge(new_state, %{conn: conn, params: opts})}
  end

  defp format_params(params) do
    [ size: 1,
      user: String.to_list(params[:username]),
      password: String.to_list(params[:password]),
      host: String.to_list(params[:hostname]),
      port: params[:port],
      database: String.to_list(params[:database]),
      encoding: :utf8 ]
  end

  # Connection is disconnected, reconnect before continuing
  def handle_call(request, from, %{conn: nil, params: params} = s) do
    connection(params, request, from, s)
  end

  def connection(params, request, from, %{params: params} = s) do
    pool = Keyword.get(params, :pool_name)
    :emysql.add_pool(pool, format_params(params)) 
    |> handle_connection(request, from, %{s | conn: pool})
  end

  def handle_connection(:ok, request, from, s) do
    handle_call(request, from, s)
  end
  
  def handle_connection({:error, :pool_already_exists}, request, from, s) do
    handle_call(request, from, s)
  end

  def handle_connection({:error, err}, _request, _from, s) do
    {:reply, {:error, err}, s}
  end

  def handle_call({:query, sql, _params, _timeout}, _from, %{conn: conn} = s) do
    {:reply, :emysql.execute(conn, sql), s}
  end

  def handle_cast({:monitor, pid}, %{monitor: nil} = s) do
    ref = Process.monitor(pid)
    {:noreply, %{s | monitor: {pid, ref}}}
  end

  def handle_cast({:demonitor, pid}, %{monitor: {pid, ref}} = s) do
    Process.demonitor(ref)
    {:noreply, %{s | monitor: nil}}
  end

  def handle_info({:EXIT, conn, _reason }, %{conn: conn} = s) do
    {:noreply, %{s | conn: nil}}
  end

  def handle_info({:DOWN, ref, :process, pid, _info}, %{monitor: {pid, ref}} = s) do
    {:stop, :normal, s}
  end

  def handle_info(_info, s) do
    {:noreply, s}
  end

  def terminate(_reason, %{conn: nil}) do
    :ok
  end

  def terminate(_reason, %{conn: conn}) do
    :emysql.remove_pool(conn)
  end

  defp new_state do
    %{conn: nil, params: nil, monitor: nil}
  end
end