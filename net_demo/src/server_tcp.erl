-module(server_tcp).
-export([start_server/1]).
-include_lib("base_header.hrl").

start_server(Port) ->
    Pid = spawn_link(fun() ->
                             %%参照 http://erlangdisplay.iteye.com/blog/1012785
                             %% 假如，我定义 的消息格式为
                             %%[4字节数据长度][4字节消息类型,具体的消息体].
                             %%[4字节数据长度]由{packet,4}指定,
                             %% 表示发过来的消息，前4个字节用个表明消息体的长度,gen_tcp在接收数据的时候，先读取前4个字节,
                             %%发现此4字节的整数是100的话，继续读取直到长度为100 ,作为一个数据包读取结束。
                             %% 注意,这个过程是gen_tcp 自动执行的我们接收到的Bin 是100，而非104 ,即前4个字节已经自动切除掉了
                             %%而指定{header,4 }后，接收到的Bin [Byte1, Byte2,Byte3,Byte4 | Binary]即 4+96
                             %%而这4个字节用来表时消息类型
                             {ok, Listen} = gen_tcp:listen(Port, [binary, {active, false},{packet ,?C2S_TCP_PACKET}]),
                             %% {ok, Listen} = gen_tcp:listen(Port, [binary, {active, false},{packet ,4},{header,4}]),
                             %% {ok, Listen} = gen_tcp:listen(Port, [binary, {active, false}]),
                             spawn(fun() -> acceptor(Listen) end),
                             timer:sleep(infinity) %sleep ,避免前当进程退出 ，因为tcp socket 是与启动它的进程绑定的，如果进程死，socket关。
                     end),
    {ok, Pid}.

acceptor(ListenSocket) ->
    {ok, Socket} = gen_tcp:accept(ListenSocket), %
    spawn(fun() -> acceptor(ListenSocket) end),  %每次一个客户端连接上来，启用另一个进程继续兼听，而当前进程则用来处理刚连接进来的client
    io:format("a new client is coming...~n",[]),
    handle(Socket).

handle(ClientSocket) ->
    inet:setopts(ClientSocket, [{active, once}]),
    receive
        {tcp, ClientSocket,Bin}  when is_binary(Bin) ->
            io:format("server handle command...~n",[]),
            case handle_data(Bin,ClientSocket)  of
                ok->
                    handle(ClientSocket) ;
                {error, Reason}->
                    self()!{exit,self(),Reason}
            end;
        {tcp_closed,SocketSocket}->
            handle_tcp_closed(SocketSocket)
                ;
        {tcp_error, _Socket, Reason}->
            io:format("tcp_error with reason ~p~n:",[Reason]);
        {exit,_FromPid,Reason}->                                %服务器端强迫客户端下线，正常用户的登录强迫同名匿名用户下线
            io:format("exit with reason~p~n",[Reason]) ,
            handle_tcp_closed(ClientSocket),
            exit(normal) ;
        Other ->
            io:format("other msg ~p~n",[Other]),
            handle(ClientSocket)
    end.
handle_tcp_closed(ClientSocket)->
    io:format(" tcp_closed:~p!~n",[ClientSocket])
        .

handle_data(Bin,ClientSocket) ->
    EncodeBin=
        try
            C2SProtocol=server_decode:decode(Bin) ,
            S2CProtocol=server_handle:handle(C2SProtocol),
            server_encode:encode(S2CProtocol)
        catch
            _:_->
                ok
        end,
    gen_tcp:send(ClientSocket,EncodeBin).