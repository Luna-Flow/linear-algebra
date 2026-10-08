# consistency API

`Luna-Flow/linear-algebra/consistency` is a test-only package. It has no public
items: its interface file is empty, and it exists to run cross-package
agreement tests between [`immut`](immut.md), [`mutable`](mutable.md) and
`immut.MatrixFn`.

Source: [`src/consistency/core_wbtest.mbt`](../../../src/consistency/core_wbtest.mbt).
What is compared and why is explained in the
[consistency design](../design/consistency.md).

## Public items

None. The package is not meant to be imported.

## Test suite

| Test | What must agree |
| --- | --- |
| `matrix core operations stay aligned` | storage order, `+`, `*`, transpose, trace of `immut` and `mutable` |
| `matrix constructors and conversions stay aligned` | `make`, `new`, `from_2d_array`, `from_array`, `to_2d_array`, degenerate shapes |
| `matrix and vector conversions stay aligned` | row, column and diagonal matrices from vectors |
| `semantic differences stay explicit` | the documented differences (in-place versus returned updates) |
| `shared same_index_swap stays aligned` | `swap_rows(i, i)` and `swap_cols(i, i)` are no-ops in both |
| `identity and transpose laws stay aligned` | $AI = A$, $IA = A$, $(AB)^{\mathsf T} = B^{\mathsf T} A^{\mathsf T}$ |
| `trace and multiplication associativity stay aligned` | $\operatorname{tr}(A^{\mathsf T}) = \operatorname{tr}(A)$, $(AB)C = A(BC)$ |
| `vector tensor and matrix conversion laws stay aligned` | outer products, row and column matrices |
| `cross-package matrix semiring laws on small integers` | quickcheck: associativity of `+`, distributivity, equal products |
| `zero-column multiplication stays aligned` | $(2 \times 0)(0 \times 0)$ products |
| `immut and fn_matrix stay aligned on core laws` | `Matrix` versus `MatrixFn` for `+`, transpose, determinant, `pow` |
| `all matrix implementations stay aligned under random small inputs` | quickcheck: all three implementations on random $2 \times 2$ inputs |

Run it with:

```sh
moon test -p consistency
```
