-module(hackney_dev).
-compile([export_all]).

call(undefined, Method, Url, Path, Headers, Payload, Options) ->
    %io:format(user, "url: ~p~n", [Url]),
    %io:format(user, "method: ~p~n", [Method]),
    %io:format(user, "headers: ~p~n", [Headers]),
    %io:format(user, "body: ~p~n", [Payload]),
    {ok, Code, AnswerHeaders, Client} = hackney:request(Method, Url ++ Path, Headers, Payload, Options),
    {ok, Body, NewClient} = hackney:body(Client),
    %io:format(user, "~ncode: ~p~n", [Code]),
    %io:format(user, "headers: ~p~n", [AnswerHeaders]),
    %io:format(user, "body: ~p~n", [Body]),
    {Code, AnswerHeaders, Body, NewClient};

call(Client, Method, _Url, Path, Headers, Payload, _Options) ->
    NextReq = {Method, "/" ++ Path, Headers, Payload},
    {ok, Code, AnswerHeaders, Client1} = hackney:send_request(Client, NextReq),
    {ok, Body, Client2} = hackney:body(Client1),
    {Code, AnswerHeaders, Body, Client2}.

