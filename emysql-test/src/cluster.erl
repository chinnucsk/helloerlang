-module(cluster).
-export([slaves/1]).

%% Argument:
%% Hosts: List of hostname (string)
%% cluster:slaves(["gateway", "yaws1", "yaws2", "mnesia1", "mnesia2", "eddieware"]).

slaves([]) ->
    ok;
slaves([Host|Hosts]) ->
    Args = erl_system_args(),
    NodeName = "cluster",
    {ok, Node} = slave:start_link(Host, NodeName, Args),
    io:format("Erlang node started = [~p]~n", [Node]),
    slaves(Hosts).

erl_system_args()->
    Shared = case init:get_argument(shared) of
                 error -> " ";
                 {ok,[[]]} -> " -shared "
             end,
    lists:append(["-rsh ssh -setcookie ",
                  atom_to_list(erlang:get_cookie()),
                  Shared, " +Mea r10b "]).

%% Do not forget to start erlang with a command like:
%% erl -rsh ssh -sname clustmaster
%% slave:start_link("jf.org","c2","-rsh ssh -setcookie DJQWUOCYZCIZNETCXWES  +Mea r10b ")
