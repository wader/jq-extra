# read jq test format:
# # comment
# expr
# input
# output*
# <blank>+
# ...
# <next test>
def from_jqtest:
  def emit:
    ( .emit =
        { expr
        , nr
        , line
        , input
        , output
        , fail
        , error
        , comments
        }
    )
  ;
  [ foreach (split("\n")[], null) as $l (
      { emit: true
      , nr: 0
      , current_line: 0
      , comments: []
      };
      ( .current_line += 1
      | if .emit then
          ( .emit     = null
          | .expr     = null
          | .nr      += 1
          | .input    = null
          | .output   = []
          | .fail     = null
          | .error    = null
          | .comments = []
          )
        else .
        end
      | if $l then
          ( if $l | test("^\\s*#") then .comments += [$l]
          elif $l | test("^\\s*$") then
            ( if .expr
            then  emit
            else .comments += ["#"]
            end
            )
          elif $l | test("^\\s*%%FAIL") then .fail = $l
          elif .expr == null then
            ( .expr = $l
            | .line = .current_line
            )
          elif .fail and .error == null then .error   =  $l
          elif           .input == null then .input   =  $l
          else                               .output += [$l]
          end
          )
        else # final step: emit a final test/trailing comments
          ( if .expr or (.comments | length != 0)
          then emit
          else empty
          end
          )
        end
      );
      select(.emit) | .emit
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
      def emit($type): 
        if .lines | length != 0 then
          .emit = 
            { start_line
            , lines
            , $type
            , is_compressed,
            }
        else .
        end
      ;

      foreach (.[], null) as $l (
        { emit:          true
        , current_line:  0
        };
        ( .current_line   += 1
        | if .emit then
          ( .emit          = null
          | .start_line    = .current_line
          )
          else .
          end
        | if $l then
            if $l | start then
              ( emit("other")
              | .lines = [$l]
              )
            elif $l | end_ then
              ( emit("def")
              | .start_line    = .current_line
              | .is_compressed = (.lines[-1] | test("^#\\s*$") | not)
              | .lines         = [$l]
              )
            else .lines       += [$l]
            end
          else emit("other")
          end
        );
        ( select(.emit)
        | .emit
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
      , emit: null
      };
      ( .current_line += 1
      | if .start_line == null then .start_line = .current_line end
      | if $l | . == null or f then
          ( .emit =
              { start_line
              , lines
              }
          | .start_line = null
          | .lines = []
          )
        else
          ( .emit = null
          | .lines += [$l]
          )
        end
      );
      ( select(.emit)
      | .emit
      )
    );

  ( _find_def_comments as {$start_line, $lines, $type, $is_compressed}
  | if $type == "def" then
      ( $lines
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
        , header_raw: $header[0]
        , long: ($header[1:] | map(select(. != "")) | join("\n"))
        , long_raw: $header[1:]
        , examples: ($examples | map(select(. != "")))
        , examples_raw: $examples
        , tests: ($tests |  join("\n") | from_jqtest)
        , tests_raw: $tests
        , $tests_start_line
        , type: "def"
        }
      )
    else
      { $lines
      , type: "other"
      , $is_compressed
      }
    end
  );

def to_test:
  ( if .type == "def" then
      ( "# " + .header_raw
      , ( .long_raw[]
        | "# " + .
        )
      , "# Examples:"
      , ( .examples_raw[]
        | "# " + .
        )
      , "# Tests:"
      , ( .tests[]
        | if .expr then
            ( ( $ARGS.named.includes // ""
              | split(",")
              | map("include \(. | rtrimstr(".jq") | @json); " )
              | join("")
              ) + .expr
            , .input
            , .output[]
            , .comments[]
            , ""
            )
          else .comments[]
          end
        )
      )
    else
      ( if .is_compressed then
          ( "# " + .lines[0] + .lines[1]
          , .lines[2:][]
          | "# " + .
          )
        else
          ( .lines[]
          | "# " + .
          )
      end
      )
    end
  );

def to_html_anchor: gsub(" "; "_") | gsub("[^A-Za-z0-9_]"; "_");

def to_markdown:
  ( map(select(.type == "def"))
  | sort_by(
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

# jq -L src -nf <(jq -rRs -L .. 'include "make"; from_defs as {$tests_start_line, $tests, $type} | select($type == "def") | $tests[] | debug | jqtest_to_jq("chunk.jq"; $tests_start_line; ["chunk"])' src/chunk.jq)
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
