# arithmetic 教程

## 项目配置

先把共享抽象层依赖装好：

```sh
moon add Luna-Flow/linear-algebra@0.4.6
moon add Luna-Flow/luna-generic@0.3.3
moon add Luna-Flow/arithmetic@0.2.2
```

推荐的 `moon.pkg` 导入写法：

```moonbit nocheck
import {
  "Luna-Flow/linear-algebra/arithmetic" @la_arithmetic,
  "Luna-Flow/luna-generic" @lf_alg,
  "Luna-Flow/arithmetic" @lf_arith,
}
```

## 小案例：把带符号残差转成惩罚值

```moonbit check
///|
fn[T : @la_arithmetic.Abs] residual_penalty(value : T) -> T {
  @la_arithmetic.Abs::abs(value)
}

///|
test "Abs-based penalty helper compiles for Int" {
  inspect(residual_penalty(-3), content="3")
}
```

这个例子很小，但正好体现了 `arithmetic` 层的职责：

1. 从线性代数流程里拿到一个原始标量值。
2. 只声明当前真正需要的操作，这里是 `Abs`。
3. 把带符号残差转成惩罚值，而不额外声称它满足更强的代数结构。

当算法需要的是“一个能算的操作”，而不是“完整数学结构”时，这就是最合适的分层。

## 建议流程

1. 当算法需要 `abs`、带检查除法、带检查平方根、近似比较这类具体操作时，优先看 `arithmetic`。
2. 约束尽量收窄，这样更多标量类型都能复用你的算法。
3. 只有当算法依赖更强的结构语义时，再升级到 `algebra`。

## 实践建议

- 如果 `Luna-Flow/luna-generic` 或 `Luna-Flow/arithmetic` 已经表达了该能力，优先复用上游 trait。
- 只有当上游缺少合适名称时，才补本地的线性代数能力 trait。
- 不要拿 arithmetic-only trait 去替代更强的代数保证。
