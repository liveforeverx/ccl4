-module(xmlsimple_dec).
-export([decode/1, extract/2, extract_cont/3]).

decode(Bin) when is_binary(Bin) ->
    decode(binary_to_list(Bin));
decode(List) when is_list(List) ->
    string:tokens(List, " <>\r\n").

extract(_Id, []) ->
    notfound;
extract(Id, [Id, Next, Next2 | _List]) ->
    case string:str(Next, "m:type=") of
        1 -> Next2;
        _ -> Next
    end;
extract(Id, [_ | List]) ->
    extract(Id, List).

extract_cont(Id, IdEnd, List) ->
    extract_cont(Id, IdEnd, List, []).
extract_cont(_, _, [], Result) ->
    {lists:reverse(Result), []};
extract_cont(true, IdEnd, [IdEnd | List], Result) ->
    {lists:reverse(Result), List};
extract_cont(true, IdEnd, [Next | List], Result) ->
    extract_cont(true, IdEnd, List, [Next | Result]);
extract_cont(Id, IdEnd, [Id | List], Result) ->
    extract_cont(true, IdEnd, List, Result);
extract_cont(Id, IdEnd, [_Other | List], Result) ->
    extract_cont(Id, IdEnd, List, Result ).
