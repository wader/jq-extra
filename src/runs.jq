# runs_by(f) - Group runs of equal values mapped by f
#
# Examples:
# [{a:1,b:2}, {a:2,b:2}, {a:3,b:2}] | runs_by(.b) -> [[{"a":1,"b":2},{"a":2,"b":2},{"a":3,"b":2}]]
#
# Tests:
# runs_by(.a)
# [{"a":1},{"a":1},{"a":2}]
# [[{"a":1},{"a":1}],[{"a":2}]]
def runs_by(f):
  ( . as $a
  | length as $l
  | if $l == 0 then []
    else
      ( [ foreach $a[] as $v (
            {cf: ($a[0] | f), index: 0, start: 0, extract: null};
            ( ($v | f) as $vf
            | (.index == 0 or (.cf == $vf)) as $equal
            | if $equal then
                ( .extract = null
                )
              else
                ( .cf = $vf
                | .extract = [.start, .index]
                | .start = .index
                )
              end
            | .index += 1
            );
            ( if .extract then .extract else empty end
            , if .index == $l then [.start, .index] else empty end
            )
          )
        ]
      | map($a[.[0]:.[1]])
      )
    end
  );
# runs - Group runs of equal values
#
# Examples:
# [1, 2, 2, 3] | runs -> [[1], [2, 2], [3]]
#
# Tests:
# runs
# [1, 2, 2, 3]
# [[1], [2, 2], [3]]
def runs: runs_by(.);
