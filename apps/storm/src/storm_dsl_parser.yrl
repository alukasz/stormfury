Nonterminals
grammar expr_list expr block data
value json list list_elements list_element
map map_elements map_element map_key
in_expr range var
colon_separator comma_separator open_bracket close_bracket open_curly close_curly
boolean
.


Terminals
int float string identifier
connect push think do end for in true false null
'{' '}' '[' ']' ':' ',' '..'
.


Rootsymbol grammar.

grammar -> expr_list : '$1'.

expr_list -> expr : ['$1'].
expr_list -> expr expr_list : ['$1' | '$2'].

% expressions
expr -> connect : {connect, []}.
expr -> push data : {push, ['$2']}.
expr -> think int : {think, [extract_value('$2')]}.
expr -> for in_expr block: {for, ['$2', '$3']}.

data -> int : extract_value('$1').
data -> string : extract_value('$1').
data -> json : '$1'.

% block
block -> do end : {block, []}.
block -> do expr_list end : {block, '$2'}.

% in
in_expr -> var in range : {in, ['$1', '$3']}.
var -> identifier : {var, [extract_value('$1')]}.

range -> int '..' int: {'..', [extract_value('$1'), extract_value('$3')]}.
range -> list : '$1'.

%% atomic values
value -> boolean : '$1'.
value -> null : nil.
value -> string : extract_value('$1').
value -> int : extract_value('$1').
value -> float : extract_value('$1').
value -> list : '$1'.
value -> map : '$1'.

boolean -> true : true.
boolean -> false : false.

% list
list -> open_bracket close_bracket : [].
list -> open_bracket list_elements close_bracket : '$2'.

list_elements -> list_element : ['$1'].
list_elements -> list_element comma_separator list_elements : ['$1' | '$3'].

list_element -> value : '$1'.

% map
map -> open_curly close_curly : #{}.
map -> open_curly map_elements close_curly : build_map('$2').

map_elements -> map_element: ['$1'].
map_elements -> map_element comma_separator map_elements : ['$1' | '$3'].

map_element -> map_key colon_separator value : {extract_value('$1'), '$3'}.

map_key -> string : '$1'.

% json
json -> list : '$1'.
json -> map : '$1'.

% helpers
colon_separator -> ':' : '$1'.
comma_separator -> ',' : '$1'.

open_bracket -> '[' : '$1'.
close_bracket -> ']': '$1'.

open_curly -> '{' : '$1'.
close_curly -> '}' : '$1'.


Erlang code.

build_map(Keywords) when is_list(Keywords)->
    Fun = fun({Key, Val}, Map) -> maps:put(Key, Val, Map) end,
    lists:foldl(Fun, #{}, Keywords).

extract_value({_, _, Val}) ->
    Val.
