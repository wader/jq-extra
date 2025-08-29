
# count_by(f) - Count unique values in array based on condition
#
# Similar to `group_by(f)` but counts instead.
#
# Examples:
# [101,201,300] | count_by(. % 10) -> [[0,1],[1,2]]
#
# Tests:
# .[] | count_by(. % 2)
# [[1], [1,2], [1,2,2,2], [1,2,2,2,3]]
# [[1,1]]
# [[0,1],[1,1]]
# [[0,3],[1,1]]
# [[0,3],[1,2]]
def count_by(f):
  group_by(f) | map([(.[0] | f), length]);

# count - Count unique values in array
#
# Examples:
# ["a","b","b","b","c","c"] | count -> [["a",1],["b",3],["c",2]]
#
# Tests:
# .[] | count
# [[1], [1,2], [1,2,2,2], [1,2,2,2,3]]
# [[1,1]]
# [[1,1],[2,1]]
# [[1,1],[2,3]]
# [[1,1],[2,3],[3,1]]
def count: count_by(.);
