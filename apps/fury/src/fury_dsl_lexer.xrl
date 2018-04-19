Definitions.

Digit      = [0-9]
LowerCase  = [a-z]
Whitespace = [\s\t]


Rules.

% numbers
-?{Digit}+            : {token, {int, TokenLine, list_to_integer(TokenChars)}}.
-?{Digit}+\.{Digit}+   : {token, {float, TokenLine, list_to_float(TokenChars)}}.

% string
"[^\"]+" : {token, {string, TokenLine, list_to_binary(strip(TokenChars, TokenLen))}}.

% symbols
[{}\[\]:,=] : {token, {list_to_atom(TokenChars), TokenLine}}.
\.\.        : {token, {'..', TokenLine}}.

% identifiers
({LowerCase}|_)+ : build_token(TokenLine, TokenChars).

% end of line
(\n)+ : skip_token.

% whitespace characters
{Whitespace}+ : skip_token.


Erlang code.

build_token(Line, TokenChars) ->
    case reserved_word(TokenChars) of
        true -> {token, {list_to_atom(TokenChars), Line}};
        false -> {token, {identifier, Line, list_to_binary(TokenChars)}}
    end.

strip(TokenChars, TokenLen) ->
    lists:sublist(TokenChars, 2, TokenLen - 2).

reserved_word("push") -> true;
reserved_word("join") -> true;
reserved_word("think") -> true;
reserved_word("do") -> true;
reserved_word("end") -> true;
reserved_word("for") -> true;
reserved_word("in") -> true;
reserved_word("true") -> true;
reserved_word("false") -> true;
reserved_word("null") -> true;
reserved_word(_) -> false.
