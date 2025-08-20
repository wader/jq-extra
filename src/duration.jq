# from_duration - From hh:mm::ss.s to seconds
#
# Convert a duration string into seconds.
#
# Examples:
# "01:02:03.45" | from_duration -> 3723.45
#
# Tests:
# from_duration
# "01:02:03.45"
# 3723.45
def from_duration:
  ( reduce (split(":") | reverse[]) as $p (
      {m: 1, n: 0};
      ( .n = .n + ($p | tonumber) * .m
      | .m *= 60
      )
    )
  | .n
  );

# to_duration - From seconds to hh::mm::ss.s
#
# Convert seconds into duration string.
#
# Examples:
# 3723.45 | to_duration -> "01:02:03.45"
#
# Tests:
# to_duration
# 3723.45
# "01:02:03.45"
def to_duration:
  def intfloor: (. % (.+1));
  def intdiv($n): (. - (. % $n)) / $n;
  def pad($s): $s[length:] + .;
  ( intfloor as $n # int floor
  | (tostring | split(".")[1]) as $frac # hack: use string for decimal fractions
  | $n
  | [ recurse(if . > 0 then intdiv(60) else empty end)
    | . % 60
    | tostring
    | pad("00")
    ]
  | reverse[1:]
  | join(":") + if $frac then "." + $frac else "" end
  );
