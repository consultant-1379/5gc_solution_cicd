-module(yaws_dynopts).

-include("/lab/testtools/dallas/rhel764/Release/3R123B02/3pp/yaws/lib/yaws-2.0.8/include/yaws.hrl").
-include("/lab/testtools/dallas/rhel764/Release/3R123B02/3pp/yaws/lib/yaws-2.0.8/include/yaws_api.hrl").

-export([
    have_ssl_honor_cipher_order/0,
    have_ssl_client_renegotiation/0,
    have_ssl_sni/0,
    have_ssl_log_alert/0,
    have_ssl_handshake/0,
    have_erlang_now/0,
    have_rand/0,    have_start_error_logger/0,    have_http_uri_parse/0,
    have_safe_relative_path/0,

    unique_triple/0,
    get_time_tuple/0,
    now_secs/0,
    random_seed/3,
    random_uniform/1,
    connection_information/2,
    ssl_handshake/2,    start_error_logger/0,
    http_uri_parse/1,
    safe_relative_path/2,

    generate/1,
    purge_old_code/0,
    is_generated/0
   ]).


generate(_) -> ok.
purge_old_code() -> code:soft_purge(?MODULE).
is_generated() -> true.

have_ssl_honor_cipher_order()   -> ?HAVE_SSL_HONOR_CIPHER_ORDER.
have_ssl_client_renegotiation() -> ?HAVE_SSL_CLIENT_RENEGOTIATION.
have_ssl_log_alert()            -> ?HAVE_SSL_LOG_ALERT.

-ifdef(HAVE_ERLANG_NOW).
have_erlang_now() -> true.
unique_triple() ->
    now().
get_time_tuple() ->
    now().
now_secs() ->
    {M,S,_} = now(),
    (M*1000000)+S.
-else.
have_erlang_now() -> false.
unique_triple() ->
    {erlang:unique_integer([positive]),
     erlang:unique_integer([positive]),
     erlang:unique_integer([positive])}.
get_time_tuple() ->
    erlang:timestamp().
now_secs() ->
    {M,S,_} = erlang:timestamp(),
    (M*1000000)+S.
-endif.

-ifdef(HAVE_RAND).
have_rand() -> true.
random_seed(A,B,C) -> rand:seed(exsplus, {A,B,C}).
random_uniform(N)  -> rand:uniform(N).
-else.
have_rand() -> false.
random_seed(A,B,C) -> random:seed(A,B,C).
random_uniform(N)  -> random:uniform(N).
-endif.

-ifdef(HAVE_SSL_SNI).
have_ssl_sni() -> true.
connection_information(Sock, Items) -> 
    ssl:connection_information(Sock, Items).
-else.
have_ssl_sni() -> false.
connection_information(_, _) -> undefined.
-endif.

-ifdef(HAVE_SSL_HANDSHAKE).
have_ssl_handshake() -> true.
ssl_handshake(Sock, Timeout) ->
    ssl:handshake(Sock, Timeout).
-else.
have_ssl_handshake() -> false.
ssl_handshake(Sock, Timeout) ->
    case ssl:ssl_accept(Sock, Timeout) of        ok -> {ok, Sock};
        Error -> Error
    end.
-endif.
-ifdef(HAVE_START_ERROR_LOGGER).
have_start_error_logger() -> true.
start_error_logger() ->
    case logger:get_handler_config(error_logger) of
        {ok, _} -> ok;
        {error, _} ->
            logger:add_handler(error_logger, error_logger,
                               #{level => info, filter_default => log,                                 filters => []})
    end.
-else.
have_start_error_logger() -> false.
start_error_logger() -> ok.
-endif.
-ifdef(HAVE_HTTP_URI_PARSE).
have_http_uri_parse() -> true.
http_uri_parse(Uri) -> http_uri:parse(Uri).
-else.
have_http_uri_parse() -> false.
http_uri_parse(Uri) ->
    case uri_string:parse(Uri) of
        {error,_,_}=Error -> Error;
        UriMap ->
            Scheme = case maps:find(scheme, UriMap) of
                         {ok, S} -> list_to_existing_atom(S);
                         error -> ''
                     end,
            UserInfo = case maps:find(userinfo, UriMap) of
                           {ok, U} -> U;
                           error -> []
                       end,
            Host = case maps:find(host, UriMap) of
                       {ok, H} -> H;
                       error -> []
                   end,
            Port = case maps:find(port, UriMap) of
                       {ok, Po} -> Po;
                       error ->
                           case Scheme of
                               http -> 80;
                               https -> 443;
                               _ -> undefined
                           end
                   end,
            Path = case maps:find(path, UriMap) of
                       {ok, Pa} -> Pa;
                       error -> []
                   end,
            Query = case maps:find(query, UriMap) of
                        {ok, Q} -> [$?|Q];
                        error -> []
                    end,
            {ok, {Scheme, UserInfo, Host, Port, Path, Query}}
    end.
-endif.
-ifdef(HAVE_SAFE_RELATIVE_PATH).
have_safe_relative_path() -> true.
safe_relative_path(Filename, Cwd) ->
    filelib:safe_relative_path(Filename, Cwd).
-else.
have_safe_relative_path() -> false.
safe_relative_path(File, Cwd) ->
    yaws:safe_rel_path(File, Cwd).
-endif.