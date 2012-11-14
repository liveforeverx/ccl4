-module(azure_helplib).
-compile([export_all]).

create_table(Name) ->
 "<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"yes\"?>
  <entry xmlns:d=\"http://schemas.microsoft.com/ado/2007/08/dataservices\"
    xmlns:m=\"http://schemas.microsoft.com/ado/2007/08/dataservices/metadata\"
    xmlns=\"http://www.w3.org/2005/Atom\">
    <title />
    <updated>2009-03-18T11:48:34.9840639-07:00</updated>
    <author>
      <name/>
    </author>
      <id/>
      <content type=\"application/xml\">
        <m:properties>
          <d:TableName>" ++ Name ++ "</d:TableName>
        </m:properties>
      </content>
    </entry>".

simple_id() ->
    <<Id:8/binary, _/binary>> = uuid_hex(),
    Id.

uuid_hex() ->
    % create uuid binary
    R1 = crypto:rand_uniform(0, 281474976710656),
    R2 = crypto:rand_uniform(0, 4096),
    R3 = crypto:rand_uniform(0, 4294967296),
    R4 = crypto:rand_uniform(0, 1073741824),
    UUIDBin = <<R1:48, 4:4, R2:12, 2:2, R3:32, R4: 30>>,

    % extract numbers for display
    <<TL:32, TM:16, THV:16, CSR:8, CSL:8, N:48>> = UUIDBin,
    list_to_binary(io_lib:format("~8.16.0b-~4.16.0b-~4.16.0b-~2.16.0b~2.16.0b-~12.16.0b",
                                 [TL, TM, THV, CSR, CSL, N])).

timestamp() ->
    encode_timestamp(erlang:universaltime()).

encode_timestamp({{Year, Month, Day}, {Hour, Minute, Second}}) ->
    list_to_binary(io_lib:fwrite("~4..0B-~2..0B-~2..0BT~2..0B:~2..0B:~2..0B", [Year, Month, Day, Hour, Minute, Second])).
