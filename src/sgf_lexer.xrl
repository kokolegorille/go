Definitions.

PROPVALUE  = ((\[\])|(\[[^\[\]]+\])|(\[[^\[\]]+(\[.+\])+[^\[\]]+\]))+
PROPIDENT  = [A-Z]+
WHITESPACE = [\s\t\n\r]

Rules.

\(            : {token, {game_tree_start, TokenLine}}.
\)            : {token, {game_tree_end, TokenLine}}.
;             : {token, {node_start, TokenLine}}.
{PROPIDENT}   : {token, {propident, TokenLine, TokenChars}}.
{PROPVALUE}   : {token, {propvalue, TokenLine, TokenChars}}.
{WHITESPACE}+ : skip_token.
{EOF}         : {token, {eof, TokenLine, TokenChars}}.

Erlang code.
