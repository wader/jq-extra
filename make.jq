# read jq test format:
# # comment
# expr
# input
# output*
# <blank>+
# ...
# <next test>
def from_jqtest:
  [ foreach (split("\n")[], "") as $l (
      { current_line: 0
      , nr: 1
      , emit: true
      };
      ( .current_line += 1
      | if .emit then
          ( .expr = null
          | .input = null
          | .output = []
          | .fail = null
          | .emit = null
          | .error = null
          )
        else .
        end
      | if $l | test("^\\s*#") then .
        elif $l | test("^\\s*$") then
          if .expr then
            ( .emit =
                { line
                , nr
                , expr
                , input
                , output
                , fail
                , error
                }
            | .nr += 1
            )
          else .
          end
        elif $l | test("^\\s*%%FAIL") then
          .fail = $l
        else
          if .expr == null then
            ( .line = .current_line
            | .expr = $l
            )
          elif .fail and .error == null then .error = $l
          elif .input == null then .input = $l
          else .output += [$l]
          end
        end
      );
      if .emit then .emit
      else empty
      end
    )
  ];

# fn(args) -> short description
#
# longer
# description
# here
#
# Examples:
# expr1 -> output1
# expr2 -> output2
#
# Test:
# expr
# input
# output
# output
def from_defs:
  def _find_def_comments:
    def _cut_by(start; end_):
      foreach .[] as $l (
        {acc: null, extract: null};
        if $l | start then
          ( .extract = null
          | .acc = [$l]
          )
        elif $l | end_ then
          ( .extract = .acc
          | .acc = null
          )
        elif .acc != null then
          ( .acc += [$l]
          )
        else
          .extract = null
        end;
        ( .extract
        | select(length > 0)
        )
      );
    ( split("\n")
    # only comments or whitespace
    | _cut_by(
        # start: # function_name - short description
        test("^# (.+) - ");
        # end: "def function name"
        test("^def")
      )
    );

  def _split_by(f):
    foreach (.[], null) as $l (
      {acc: [], extract: null};
      if $l | . == null or f then
        ( .extract = .acc
        | .acc = []
        )
      else
        ( .extract = null
        | .acc += [$l]
        )
      end;
      ( .extract
      | select(length > 0)
      )
    );

  ( _find_def_comments
  # strip "# "
  | map(.[2:])
  # split into header, example and tests
  | [_split_by(. == "Examples:" or . == "Tests:")] as [$header, $examples, $tests]
  | { name: ($header[0] | capture("^(?<n>.*) - .*").n)
    , short: ($header[0] | capture("^.* - (?<s>.*)").s)
    , long: ($header[1:] | map(select(. != "")) | join("\n"))
    , examples: ($examples | map(select(. != "")))
    , tests: ($tests | join("\n") | from_jqtest)}
  );

def to_test:
  ( .tests[]
  | (.expr, .input, .output[])
  , ""
  );

def to_html_anchor: gsub(" "; "_") | gsub("[^A-Za-z0-9_]"; "_");

def to_markdown:
		( sort_by(
        ( .name
        | [ gsub("^(from_|to_)?(?<n>[A-Za-z_]*).*"; .n)
          , gsub("^(?<n>[A-Za-z_]*).*"; .n)
          , length
          ]
        )
      )
		| ( .[]
      | "- [`\(.name)`](#\(.name | to_html_anchor))"
      )
    , ( .[]
      | ( "#### <a name=\"\(.name | to_html_anchor)\"></a>`\(.name)` - \(.short)"
        , (.long | select(. != ""))
        , (.examples | map("- `\(. )`" | gsub(" -> "; "` → `")) | join("\n"))
        , ""
        )
      )
		);

def jqtest_to_jq:
  [ .input
  , " | "
  , "["
  , .expr
  , "]"
  , " == "
  , "["
  , .output[]
  , "]"
  ] | join("");
