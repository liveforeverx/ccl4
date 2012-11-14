-module(hackney_dev).
-compile([export_all]).

start() ->
    Options = [{timeout, 150000}, {pool_size, 200}],
    hackney:start_pool(mypool, Options).

call(undefined, Method, Url, Headers, Payload, _) ->
    %io:format(user, "url: ~p~n", [Url]),
    %io:format(user, "method: ~p~n", [Method]),
    %io:format(user, "headers: ~p~n", [Headers]),
    %io:format(user, "body: ~p~n", [Payload]),
    Options = [{pool, mypool}],
    {ok, Code, AnswerHeaders, Client} = hackney:request(Method, Url, Headers, Payload, Options),
    {ok, Body, NewClient} = hackney:body(Client),
    %io:format(user, "~ncode: ~p~n", [Code]),
    %io:format(user, "headers: ~p~n", [AnswerHeaders]),
    %io:format(user, "body: ~p~n", [Body]),
    {Code, AnswerHeaders, Body, NewClient};

call(Client, Method, Url, Headers, Payload, _) ->
    {ok, Code, AnswerHeaders, Client} = hackney:send_request(Client, {Method, Url, Headers, Payload}),
    {ok, Body, NewClient} = hackney:body(Client),
    {Code, AnswerHeaders, Body, NewClient}.

