import json
import re
import os

# 配置文件名
FILES = ['bench_js.txt', 'bench_native.txt', 'bench_wasm-gc.txt', 'bench_wasm.txt']

def get_info(full_name):
    # 提取测试规模 (Scale)
    scale_match = re.search(r'scale\((\d+)\)', full_name)
    scale = scale_match.group(1) if scale_match else "unknown"
    
    # 提取头部名称
    op_part = full_name.split(' ')[0]
    
    # 1. 识别实现类型 (Implementation Type) - 基于初次识别
    if op_part.startswith('naive_'):
        impl = 'naive'
    elif op_part.startswith('native_'):
        impl = 'native'
    elif op_part.startswith('2d_') or op_part.startswith('m2d_') or op_part.startswith('_2d_'):
        impl = '2d'
    elif op_part.startswith('lib_'):
        impl = 'lib'
    else:
        impl = 'other'
        
    # 2. 剥离所有前缀以提取核心项目名 (Test Item)
    # 采用递归剥离，处理如 naive_m2d_ 这样的复合前缀
    op = op_part
    prefixes = ['naive_', 'native_', '2d_', 'lib_', 'm2d_', '_2d_', 'matrix_']
    prefixes.sort(key=len, reverse=True)
    
    changed = True
    while changed:
        changed = False
        for p in prefixes:
            if op.startswith(p):
                op = op[len(p):]
                changed = True
                break
    
    # 统一重命名一些常见的项目名，确保对齐
    mapping = {
        "mul": "matrix_mul",
        "vector_mul": "matrix_vector_mul",
        "dot": "vector_dot",
        "access": "matrix_access",
        "set_access": "matrix_set_access",
        "mapi": "matrix_mapi",
        "map_inplace": "matrix_map_inplace"
    }
    if op in mapping:
        op = mapping[op]
    else:
        # For things like 'determinant', 'rank', 'inverse'
        # ensure they have 'matrix_' prefix for consistency if it's a matrix op
        if op in ["determinant", "rank", "inverse", "each", "each_row_col", "power"]:
            op = f"matrix_{op}"
            
    return op, scale, impl

def main():
    result_tree = {}

    for filename in FILES:
        if not os.path.exists(filename):
            print(f"Skipping {filename}: File not found")
            continue
            
        # 根据文件名识别后端
        backend_id = filename.replace('bench_', '').replace('.txt', '')
        
        with open(filename, 'r') as f:
            for line in f:
                line = line.strip()
                if not line.startswith('{'): continue
                try:
                    content = json.loads(line)
                    # 原始文件格式为 {"backend_name": [...]}
                    data_key = list(content.keys())[0]
                    entries = content[data_key]
                    for entry in entries:
                        for full_name, stats in entry.items():
                            op, scale, impl = get_info(full_name)
                            
                            # 构建嵌套结构: 项目 -> 规模 -> 后端 -> 实现 -> 结果
                            if op not in result_tree: result_tree[op] = {}
                            if scale not in result_tree[op]: result_tree[op][scale] = {}
                            if backend_id not in result_tree[op][scale]: result_tree[op][scale][backend_id] = {}
                            
                            # 保存完整的统计结果
                            result_tree[op][scale][backend_id][impl] = stats
                except Exception:
                    continue

    # 保存为最终的 JSON 文件
    output_file = 'cleaned_benchmarks.json'
    with open(output_file, 'w', encoding='utf-8') as out:
        json.dump(result_tree, out, indent=2, ensure_ascii=False)
    
    print(f"清洗完成！数据已保存至: {output_file}")

if __name__ == "__main__":
    main()