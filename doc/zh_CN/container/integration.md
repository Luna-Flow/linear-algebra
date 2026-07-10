# 接入 Luna-Flow 生态

外部库只应提供符合自身真实语义的能力。接入不是一次性实现所有接口，也不需要公开
内部存储表示。

## 选择结构能力边界

| 级别 | 提供的能力 | 可以参与的角色 |
|---|---|---|
| 0 | 无 | 使用自身 API 的独立类型 |
| 1 | `VectorReadOps` 或 `MatrixReadOps` | map、转换或转置的输入 |
| 2 | `VectorBuildOps` 或 `MatrixBuildOps` | map、转换或转置的输出 |
| 3 | 配套的 read 与 build | 泛型变换的输入和输出 |
| 4P | 持久编辑字典 | 受检的 copy-on-replacement 值 |
| 4M | 可变编辑字典 | 受检的原地更新目标 |

4P 与 4M 是由所有权模型决定的替代选择，不是要求所有后端逐级实现两者。视图通常只
提供 read 与可变编辑，不提供 build；外部句柄可以只提供 read；生成型容器也可以只
提供 build。

## 算法要求的能力

| 算法 | 输入要求 | 输出要求 | 标量关系 |
|---|---|---|---|
| `vector_map` | `VectorReadOps[V1, A]` | `VectorBuildOps[V2, B]` | 可从 `A` 变为 `B` |
| `matrix_map` | `MatrixReadOps[M1, A]` | `MatrixBuildOps[M2, B]` | 可从 `A` 变为 `B` |
| `vector_convert` | `VectorReadOps[V1, T]` | `VectorBuildOps[V2, T]` | 保持 `T` |
| `matrix_convert` | `MatrixReadOps[M1, T]` | `MatrixBuildOps[M2, T]` | 保持 `T` |
| `matrix_transpose` | `MatrixReadOps[M1, T]` | `MatrixBuildOps[M2, T]` | 保持 `T` |

read 不代表支持构造、编辑、算术、连续内存或低成本随机访问。build 不代表结果可以
读回。编辑字典也不代表 resize、insert、delete 或删除稀疏存储项。

## 数学能力相互独立

`algebra` 描述加法、转置和矩阵乘法等数学行为；`container` 描述观察与构造。
外部类型可以独立选择这两条能力轴：

- 只接入 container，可以在不声明标量或容器代数定律的情况下参与数据变换。
- 只接入 algebra，可以在不公开单个元素的情况下提供封闭数学操作。
- 同时提供两者时可以参与两类泛型算法，但任何一方都不会自动推出另一方。

不要仅为了容器互操作而给标量添加宽泛的全局 trait。只有类型真正满足对应操作与
定律时，才实现数学 trait。

## 适配器由谁维护

1. 如果依赖 `Luna-Flow/linear-algebra/container` 是自然的，由容器类型所属库发布操作
   字典 factory。
2. 如果两个项目都不适合直接依赖对方，由一个小型 bridge 包维护适配器。
3. `Luna-Flow/linear-algebra` 本体只维护本仓库实现的适配器。

这样可以避免核心包不断累积可选后端依赖。factory 的标量约束应仅包含后端真实需要的
能力。

## 完整外部适配器

这个示例拥有行优先数组，但只通过操作字典公开语义。转置目标使用 Luna 的 immutable
矩阵，从而实际验证不同实现之间的边界。

```moonbit check
///|
struct EcosystemOwnedMatrix[T] {
  rows : Int
  cols : Int
  data : Array[T]
}

///|
fn[T] ecosystem_owned_matrix_read_ops() -> @container.MatrixReadOps[
  EcosystemOwnedMatrix[T],
  T,
] {
  @container.MatrixReadOps::new(matrix => (matrix.rows, matrix.cols), (
    matrix,
    row,
    col,
  ) => {
    guard row >= 0 && row < matrix.rows && col >= 0 && col < matrix.cols else {
      return Err(
        @la_error.LinearAlgebraError::index_out_of_bounds(
          "Matrix index out of bounds",
        ),
      )
    }
    Ok(matrix.data[row * matrix.cols + col])
  })
}

///|
fn[T] ecosystem_owned_matrix_build_ops() -> @container.MatrixBuildOps[
  EcosystemOwnedMatrix[T],
  T,
] {
  @container.MatrixBuildOps::new((rows, cols, initializer) => {
    guard rows >= 0 && cols >= 0 else {
      return Err(
        @la_error.LinearAlgebraError::negative_dimension(
          "Matrix dimensions must be non-negative",
        ),
      )
    }
    Ok({
      rows,
      cols,
      data: Array::makei(rows * cols, index => {
        initializer(index / cols, index % cols)
      }),
    })
  })
}

///|
test "external container adapters preserve actual matrix semantics" {
  let source : EcosystemOwnedMatrix[Int] = (ecosystem_owned_matrix_build_ops().tabulate)(
    2,
    3,
    (row, col) => row * 10 + col,
  ).unwrap()
  let target : @immut.Matrix[Int] = @container.matrix_transpose(
    source,
    ecosystem_owned_matrix_read_ops(),
    @container_adapters.immutable_matrix_build_ops(),
  ).unwrap()
  inspect(target, content="|0, 10|\n|1, 11|\n|2, 12|")
  match (ecosystem_owned_matrix_read_ops().get)(source, -1, 0) {
    Err(error) => inspect(error.is_index_out_of_bounds(), content="true")
    Ok(_) => fail("negative row must fail")
  }
  let degenerate : EcosystemOwnedMatrix[Int] = (ecosystem_owned_matrix_build_ops().tabulate)(
    0,
    3,
    (_, _) => 0,
  ).unwrap()
  debug_inspect((degenerate.rows, degenerate.cols), content="(0, 3)")
}
```

后端仍负责检查负维度、保留 `0xN` 与 `Nx0`、用 `LinearAlgebraError` 报告非法坐标，
并遵守自己声明的所有权行为。

## 接入检查清单

- 只选择真实存储和所有权模型支持的字典。
- 受检访问与构造不得 panic。
- 测试首尾和非法索引、空与退化形状、initializer 坐标顺序。
- 持久编辑要证明源值不变；可变编辑要证明失败时没有部分修改。
- 对每个支持的方向至少测试一次泛型 map 或转换。
- 记录远程访问、解压或稀疏 materialization 等性能成本，但不要改变语义契约。

未来的优化 kernel 字典应是额外的 opt-in 能力，不能成为 read/build 互操作的前提。
