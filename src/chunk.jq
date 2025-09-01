# chunks($size; s) - Collect stream s into sized chunks
#
# Examples:
# chunks(2; 1,2,3,4,5,6) -> [1, 2], [3, 4], [5, 6]
#
# Tests:
# .[] as [$input, $size] | $input | [chunks($size)]
# [[[], 1], [[], 2], [[1], 1], [[1], 2], [[1,2], 1], [[1,2], 2], [[1,2,3,4], 2], [[1,2,3,4], 3]]
# []
# []
# [[1]]
# [[1]]
# [[1],[2]]
# [[1,2]]
# [[1,2],[3,4]]
# [[1,2,3],[4]]
def chunks($size; s):
  foreach ((s | [.]), null) as $v (
    {acc: null, extract: null};
    if $v == null then .extract = .acc
    elif .acc == null then .acc = [$v[0]]
    elif .acc | length < $size then
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

# chunks($size) - Split array into sized chunks
#
# Examples:
# [1,2,3,4,5,6] | chunks(2) -> [1, 2], [3, 4], [5, 6]
#
# Tests:
# chunks(2) 
# [1,2,3,4,5,6]
# [1,2]
# [3,4]
# [5,6]
def chunks($size): chunks($size; .[]);
