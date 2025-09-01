# runs_by(f; s) - Group runs of equal values mapped by f from stream s
#
# Examples:
# [{a:1,b:1}, {a:2,b:2}, {a:3,b:2}] | runs_by(.[]; .b) -> [[{"a":1,"b":1}], [{"a":2,"b":2},{"a":3,"b":2}]
#
# Tests:
# runs_by(.b; .[])
# [{"a":1, "b":1}, {"a":2, "b":2}, {"a":3, "b":2}]
# [{"a":1,"b":1}]
# [{"a":2,"b":2},{"a":3,"b":2}]
#
# runs_by(.; 1)
# null
# [1]
#
# runs_by(.; 1,2,2,1)
# null
# [1]
# [2,2]
# [1]
#
# runs_by(.; empty)
# null
def runs_by(f; s):
  foreach ((s | [.]), null) as $v (
    {acc: null, extract: null};
    if $v == null then .extract = .acc
    elif .acc == null then .acc = [$v[0]]
    elif ($v[0] | f) == (.acc[0] | f) then
      ( .extract = null
      | .acc += [$v[0]]
      )
    else
      ( .extract = .acc
      | .acc = [$v[0]]
      )
    end;
    .extract | values
  );

# runs_by(f) - Group runs of equal values mapped by f
#
# Examples:
# [1, 2, 2.4, 3] | runs_by(floor) -> [1], [2, 2.4], [3]
#
# Tests:
# runs_by(floor)
# [1, 2, 2.4, 3]
# [1]
# [2, 2.4]
# [3]
def runs_by(f): runs_by(f; .[]);

# runs - Group runs of equal values
#
# Examples:
# [1, 2, 2, 3] | runs -> [1], [2, 2], [3]
#
# Tests:
# runs
# [1, 2, 2, 3]
# [1]
# [2, 2]
# [3]
def runs: runs_by(.);
