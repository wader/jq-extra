# streaks_by(f) - Group streaks based on condition
#
# Examples:
# [1,2,3,4,5,6] | chunk(2) -> [[1, 2], [3, 4], [5, 6]]
#
# Tests:
# streaks_by(.a)
# [{"a":1},{"a":1},{"a":2}]
# [[{"a":1},{"a":1}],[{"a":2}]]
def streaks_by(f):
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
# streaks - Group streaks of equal values
#
# Examples:
# [1, 2, 2, 3] | streaks -> [[1], [2, 2], [3]]
#
# Tests:
# streaks
# [1, 2, 2, 3]
# [[1], [2, 2], [3]]
def streaks: streaks_by(.);
