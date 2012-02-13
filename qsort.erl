 %% -*- coding:utf-8 -*-
-module(qsort).
-export([sort/1]).
%%快速排序

sort([])->
    [];
sort([H|T]) ->
    {Bigger,Smaller} = split(H,T),
     sort(Bigger)++ [H]++ sort(Smaller).

split(M,Rest)->
    split(M,Rest,[],[])
.

split(_M,[],Bigger,Smaller)->
    {Bigger,Smaller};
split(M,[H|Rest],Bigger,Smaller)when H >M ->
    split(M,Rest,[H|Bigger],Smaller);
split(M,[H|Rest],Bigger,Smaller)when H =< M ->
    split(M,Rest,Bigger,[H|Smaller]).
