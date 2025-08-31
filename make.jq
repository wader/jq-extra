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
        { current_line: 0
        , start_line: 0
        , lines: null
        , extract: null
        };
        ( .current_line += 1
        | if $l | start then
            ( .extract = null
            | .start_line = .current_line
            | .lines = [$l]
            )
          elif $l | end_ then
            ( .extract =
                { start_line
                , lines
                }
            | .lines = null
            )
          elif .lines != null then
            ( .lines += [$l]
            )
          else
            .extract = null
          end
        );
        ( .extract
        | select(.lines | length > 0)
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
      { current_line: 0
      , start_line: null
      , lines: []
      , extract: null
      };
      ( .current_line += 1
      | if .start_line == null then .start_line = .current_line end
      | if $l | . == null or f then
          ( .extract =
              { start_line
              , lines
              }
          | .start_line = null
          | .lines = []
          )
        else
          ( .extract = null
          | .lines += [$l]
          )
        end
      );
      ( .extract
      | select(length > 0)
      )
    );

  ( _find_def_comments as {$start_line, $lines}
  | $lines
  # strip "# "
  | map(.[2:])
  # split into header, example and tests
  | [_split_by(. == "Examples:" or . == "Tests:")] as
      [ {lines: $header}
      , {lines: $examples}
      , {lines: $tests, start_line: $tests_start_line}
      ]
  | { name: ($header[0] | capture("^(?<n>.*) - .*").n)
    , short: ($header[0] | capture("^.* - (?<s>.*)").s)
    , long: ($header[1:] | map(select(. != "")) | join("\n"))
    , examples: ($examples | map(select(. != "")))
    , tests: ($tests | join("\n") | from_jqtest)
    , $tests_start_line
    }
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

# jq -L src -nf <(jq -rRs -L .. 'include "make"; from_defs as {$tests_start_line, $tests} | $tests[] | debug | jqtest_to_jq("chunk.jq"; $tests_start_line; ["chunk"])' src/chunk.jq)
def jqtest_to_jq($name; $line_offset; $includes):
($includes | map("include \"\(.)\";") | join("\n")) +
"
try
  ( (\(.input) | [\(.expr)]) as $actual
  | [\(.output | join(", "))] as $expected
  | if $actual == $expected then
      \"\($name):\($line_offset + .line): PASS\"
    else
      \"\($name):\($line_offset + .line): FAIL: expected \\($expected) got \\($actual)\"
    end
  )
catch
  \"ERROR\"
";
