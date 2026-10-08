# consistency tutorial

This page is for contributors: it shows how to run the cross-package agreement
tests and how to add one when you add an operation to both `immut` and
`mutable`. The reasoning is in the [consistency design](../design/consistency.md).

| I want to | Use |
| --- | --- |
| run the agreement tests | `moon test -p consistency` |
| check a new operation in both packages | a test comparing `to_array` of both results |
| check an algebraic law on random inputs | a quickcheck property over small `Int` matrices |
| pin down an intended difference | a test of the documented behaviour |

## Quick start

From the repository root:

```sh
moon test -p consistency
```

All tests run on the default target; the package has no target-specific code.

## Everyday tasks

### Add an agreement test

Build the same input in both packages, apply the operation, and compare a
common observation. The shape of such a test, as it would appear in
`src/consistency/core_wbtest.mbt`:

```moonbit nocheck
///|
test "anti_trace stays aligned" {
  let imm = @immut.Matrix::from_2d_array([[1, 2], [3, 4]])
  let mut_m = @mutable.Matrix::from_2d_array([[1, 2], [3, 4]])
  inspect(
    imm.anti_trace().unwrap(),
    content=mut_m.anti_trace().unwrap().to_string(),
  )
}
```

### Add a law as a property

Use `quick_check_fn` with tuples of small integers, and return a `Bool` that
compares both sides of the law in both packages. Integers keep the comparison
exact.

The same idea works in your own code. This check, compiled with the manual,
compares the two packages on a product:

```moonbit check
///|
test "products agree across packages" {
  let rows = [[1, -2], [3, 4]]
  let i = @immut.Matrix::from_2d_array(rows)
  let m = @mutable.Matrix::from_2d_array(rows)
  debug_inspect((i * i).to_array() == (m * m).to_array(), content="true")
}
```

## Going further

When an operation is intentionally different between the packages, add a test
that states the difference and mention it in both API pages.

## Common pitfalls

- **Comparing `Double` results with `==`.** Kernels sum in different orders;
  keep agreement tests on integers.
- **Comparing `to_string` across element types.** Use `to_array` when the
  printed forms may differ only in formatting.

## Next steps

- [consistency API](../api/consistency.md) for the list of tests.
- [immut API](../api/immut.md) and [mutable API](../api/mutable.md).
