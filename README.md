# jq-extra

Extra builtins for jq.

> [!WARNING]
> This is mostly a proof of concept at the moment.

## Install and update

To install first time or update run `make install`:

```sh
$ make install
Installing ~/.jq symlink
Rebuilding .jq
$ jq -r gron <<< '{"hello": "world"}'
. = {}
.hello = "world"
```

## Own functions

`make install` includes `src/*.jq` so you can put your own functions in `src/local.jq` for example.

## Functions
- [`from_base($base; $table)`](#from_basebase_table)
- [`from_base($base)`](#from_basebase)
- [`from_base`](#from_base)
- [`to_base($base; prefix; $table)`](#to_basebase_prefix_table)
- [`to_base($base; prefix)`](#to_basebase_prefix)
- [`to_base($base)`](#to_basebase)
- [`chunk($size)`](#chunksize)
- [`from_duration`](#from_duration)
- [`to_duration`](#to_duration)
- [`gron`](#gron)
- [`streaks_by(f)`](#streaks_byf)
- [`streaks`](#streaks)
#### <a name="from_basebase_table"></a>`from_base($base; $table)` - Convert string to number in base and custom digits table
- `"baab" | from_base(2; {"a": 0, "b": 1})` → `9`

#### <a name="from_basebase"></a>`from_base($base)` - Convert string to number in base.
- `"ff" | from_base(16)` → `255`

#### <a name="from_base"></a>`from_base` - Convert string to number and infer base.
- `"0xff" | from_base` → `255`

#### <a name="to_basebase_prefix_table"></a>`to_base($base; prefix; $table)` - Convert number to string in base using custom prefix and digits table.
- `9 | to_base(2; "2#"; "ab")` → `"2#baab"`

#### <a name="to_basebase_prefix"></a>`to_base($base; prefix)` - Convert number to string in base using custom prefix.
- `255 | to_base(16; "")` → `"ff"`

#### <a name="to_basebase"></a>`to_base($base)` - Convert number to string in base.
- `255 | to_base(16; "")` → `"0xff"`

#### <a name="chunksize"></a>`chunk($size)` - Split array or string into even chunks
- `[1,2,3,4,5,6] | chunk(2)` → `[[1, 2], [3, 4], [5, 6]]`

#### <a name="from_duration"></a>`from_duration` - From hh:mm::ss.s to seconds
Convert a duration string into seconds.
- `"01:02:03.45" | from_duration` → `3723.45`

#### <a name="to_duration"></a>`to_duration` - From seconds to hh::mm::ss.s
Convert seconds into duration string.
- `3723.45 | to_duration` → `"01:02:03.45"`

#### <a name="gron"></a>`gron` - Output all paths in input as expressions
Similar to https://github.com/tomnomnom/gron.
```sh
$ jq -r gron <<< '{"a":1}'`
. = {}
.a = 1
```
- `{a: [1], b: true} | gron` → `". = {}", ".a = []", ".a[0] = 1", ".b = true"`

#### <a name="streaks_byf"></a>`streaks_by(f)` - Group streaks based on condition
- `[1,2,3,4,5,6] | chunk(2)` → `[[1, 2], [3, 4], [5, 6]]`

#### <a name="streaks"></a>`streaks` - Group streaks of equal values
- `[1, 2, 2, 3] | streaks` → `[[1], [2, 2], [3]]`

## Development

```sh
# run tests
$ make test

# regenerate README.md documentation
$ make README.md
```

## TODO

- Functions:
  - `ungron`
  - `expr_to_path`/`path_to_expr`
  - More array functions
  - json5?
- Include/Exclude config?
- Test with jq, gojq and jaq
  - As all don't support run-tests maybe generate jq code?
- Use public domain license to be copy/paste friendly?

## License

See [LICENSE](LICENSE).
