
def path_to_expr:
  def _is_ident: type == "string" and test("^[a-zA-Z_][a-zA-Z_0-9]*$");
  # escape \ and "
  def _escape_ident: gsub("(?<g>[\\\\\"])"; "\\\(.g)");
  ( if length == 0 or (.[0] | type) != "string" then
      [""] + .
    end
  | map(
      if type == "number" then
        "[", ., "]"
      else
        ( # empty (special case for leading index or empty path) or key
          if . == "" or _is_ident then ".", .
          else
            ".[\"\(_escape_ident)\"]"
          end
        )
      end
    )
  | join("")
  );

# gron - Output all paths in input as expressions
#
# Similar to https://github.com/tomnomnom/gron.
# ```sh
# $ jq -r gron <<< '{"a":1}'`
# . = {}
# .a = 1
# ```
#
# Examples:
# {a: [1], b: true} | gron -> ". = {}", ".a = []", ".a[0] = 1", ".b = true"
#
# Tests:
# .[] | [gron]
# [[], {}, [1,2], {"a": 1, "b": 2}, {"a b": [1, 2, 3]}]
# [". = []"]
# [". = {}"]
# [". = []",".[0] = 1",".[1] = 2"]
# [". = {}",".a = 1",".b = 2"]
# [". = {}",".[\"a b\"] = []",".[\"a b\"][0] = 1",".[\"a b\"][1] = 2",".[\"a b\"][2] = 3"]
def gron:
  ( path(..) as $p
  | getpath($p)
  | ( if type == "object" then "{}"
      elif type == "array" then "[]"
      else tojson
      end
    ) as $v
  | "\($p | path_to_expr) = \($v)"
  );
