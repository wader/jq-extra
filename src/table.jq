# table($opts) - Format array of objects as a text table with options
#
# Keys become column headers, sorted alphabetically.
# String values are left aligned, number values are right aligned,
# other value types are formatted as JSON and left aligned.
# Missing keys are shown as empty cells.
#
# Options:
#   index: string  Add a leading column with this name containing the 0-based row index
#
# ```sh
# $ echo '[{"name":"Alice","age":30},{"name":"Bob","age":25}]' | jq -r 'table({index:"row"})'
# row  age  name
# ---  ---  -----
#   0   30  Alice
#   1   25  Bob
# ```
#
# Tests:
# table({index:"row"})
# [{"name":"Alice","age":30},{"name":"Bob","age":25}]
# "row  age  name \n---  ---  -----\n  0   30  Alice\n  1   25  Bob  "
#
# table({index:"i"})
# [{"name":"Alice"},{"age":30},{"name":"Bob","age":25}]
# "i  age  name \n-  ---  -----\n0       Alice\n1   30       \n2   25  Bob  "
def table($opts):
  if length == 0 then ""
  else
    ( . as $rows
    | $opts.index as $index_col
    | ( if $index_col then [$index_col] else [] end
      + ([.[] | keys[]] | unique)
      ) as $keys
    | def _str: if . == null then "" elif type == "string" then . else tojson end;
      def _pad($s; $w; $right):
        if $right then ((" " * ($w - ($s | length))) + $s)
        else ($s + (" " * ($w - ($s | length))))
        end;
      def _val($row; $ri; $k): if $k == $index_col then $ri else $row[$k] end;
      # Per-column alignment: right-align the index column and columns with any number value
      ( $keys
      | map(
          . as $k
          | if $k == $index_col then true
            else $rows | map(.[$k] | type == "number") | any
            end
        )
      ) as $right_align
      # Precompute each row as [s] so _str is called once per cell
    | ( [ range($rows | length) as $ri
        | $rows[$ri] as $row
        | [$keys[] as $k | _val($row; $ri; $k) | _str]
        ]
      ) as $cells
    | ( [ range($keys | length) as $i
        | [ ($keys[$i] | length)
          , ($cells | map(.[$i] | length) | max)
          ] | max
        ]
      ) as $widths
    | [ ( [ range($keys | length) as $i
          | _pad($keys[$i]; $widths[$i]; false)
          ]
        | join("  ")
        )
      , ( [ range($keys | length) as $i
          | "-" * $widths[$i]
          ]
        | join("  ")
        )
      , ( $cells[] as $row_cells
        | [ range($keys | length) as $i
          | _pad($row_cells[$i]; $widths[$i]; $right_align[$i])
          ]
        | join("  ")
        )
      ]
    | join("\n")
    )
  end;

# table - Format array of objects as a text table
#
# Keys become column headers, sorted alphabetically.
# String values are left aligned, number values are right aligned,
# other value types are formatted as JSON and left aligned.
# Missing keys are shown as empty cells.
#
# ```sh
# $ echo '[{"name":"Alice","age":30},{"name":"Bob","age":25}]' | jq -r 'table'
# age  name
# ---  -----
#  30  Alice
#  25  Bob
# ```
#
# Tests:
# table
# [{"name":"Alice","age":30},{"name":"Bob","age":25}]
# "age  name \n---  -----\n 30  Alice\n 25  Bob  "
#
# table
# [{"a":1},{"b":2},{"a":3,"b":4}]
# "a  b\n-  -\n1   \n   2\n3  4"
#
# table
# []
# ""
def table: table({});
