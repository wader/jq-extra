
# def table(colmap; render):
#   def _column_widths:
#     [ . as $rs
#     | range($rs[0] | length) as $i
#     | [$rs[] | colmap | (.[$i] | length)]
#     | max
#     ];
#   if length == 0 then ""
#   else
#     ( _column_widths as $cw
#     | . as $rs
#     | ( $rs[]
#       | . as $r
#       | [ range($r | length) as $i
#         | ($r | colmap | {column: $i, string: .[$i], maxwidth: $cw[$i]})
#         ]
#       | render
#       )
#     )
#   end;

def table:
    def rpad($w):
      ( (" " * $w)[0:$w-length]
      + .
      ); 
    ( length as $row_count
    | ( reduce (.[] | keys[]) as $k ({}; .[$k] = 0)
      ) as $cols
    | map(
        with_entries(
          .value |= tostring
        )  
      ) as $values
    | $cols
    | with_entries(
        ( . as {$key}
        | .value =
            ( $values
            | map(
                ( if has($key) then .[$key]
                   else "NA"
                   end
                )
              )
            )
         )
      ) as $values
    | $values
    | with_entries(
        ( . as {$key}
        | .value |= ([($key, .[]) | length] | max)
        )
      ) as $widths
    | $values
    | ( keys
      | map(rpad($widths[.]))
      | join("|")
      )
    , ( range($row_count) as $row
      | keys
      | map(. as $key | $values[$key][$row] | rpad($widths[$key]))
      | join("|")
      )
    );
