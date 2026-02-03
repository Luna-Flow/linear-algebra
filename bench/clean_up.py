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
    
    # 1. 识别实现类型 (Implementation Type)
    if op_part.startswith('naive_'):
        impl = 'naive'
    elif op_part.startswith('array1d_') or op_part.startswith('native_'):
        impl = 'array1d'
    elif op_part.startswith('array2d_') or op_part.startswith('2d_') or op_part.startswith('_2d_'):
        impl = 'array2d'
    elif op_part.startswith('lib_'):
        impl = 'lib'
    else:
        impl = 'other'
        
    # 2. 剥离所有前缀以提取核心项目名 (Test Item)
    op = op_part
    # 只剥离实现相关的前缀，保留操作相关的前缀 (如 mat_, vec_)
    prefixes = ['naive_', 'array1d_', 'array2d_', 'lib_', 'native_', 'array_1d_', 'array_2d_', '2d_', '_2d_']
    prefixes.sort(key=len, reverse=True)
    
    changed = True
    while changed:
        changed = False
        for p in prefixes:
            if op.startswith(p):
                op = op[len(p):]
                changed = True
                break
    
    # 统一重命名项目名，确保对齐
    mapping = {
        # 常见操作缩写化
        "matrix_mul": "mat_mul",
        "matrix_vector_mul": "mat_vec_mul",
        "vector_dot": "vec_dot",
        "matrix_acc": "mat_acc",
        "matrix_access": "mat_acc",
        "matrix_set_acc": "mat_set_acc",
        "matrix_det": "mat_det",
        "matrix_determinant": "mat_det",
        "matrix_inv": "mat_inv",
        "matrix_inverse": "mat_inv",
        "matrix_rank": "mat_rank",
        "matrix_mapi": "mat_mapi",
        "matrix_map_inplace": "mat_map_inplace",
        
        # 裸名补全
        "mul": "mat_mul",
        "vec_mul": "mat_vec_mul",
        "dot": "vec_dot",
        "acc": "mat_acc",
        "access": "mat_acc",
        "set_acc": "mat_set_acc",
        "mapi": "mat_mapi",
        "map_inplace": "mat_map_inplace",
        "det": "mat_det",
        "determinant": "mat_det",
        "rank": "mat_rank",
        "inv": "mat_inv",
        "inverse": "mat_inv"
    }
    if op in mapping:
        op = mapping[op]
    elif op in ["each", "each_row_col", "power"]:
        op = f"mat_{op}"
    elif op.startswith("matrix_"):
        op = op.replace("matrix_", "mat_")
    elif op.startswith("vector_"):
        op = op.replace("vector_", "vec_")
            
    return op, scale, impl

def main():
    output_file = 'cleaned_benchmarks.json'
    result_tree = {}

    # 尝试加载现有数据
    if os.path.exists(output_file):
        try:
            with open(output_file, 'r', encoding='utf-8') as f:
                result_tree = json.load(f)
            print(f"已加载现有数据: {output_file}")
        except Exception as e:
            print(f"无法读取现有数据 (将创建新文件): {e}")
            result_tree = {}

    for filename in FILES:
        if not os.path.exists(filename):
            print(f"Skipping {filename}: File not found")
            continue
            
        # 根据文件名识别后端
        backend_id = filename.replace('bench_', '').replace('.txt', '')
        
        # 先读取并验证文件内容
        new_entries_found = False
        temp_updates = [] # 暂存更新操作 (op, scale, impl, stats)

        with open(filename, 'r') as f:
            for line in f:
                line = line.strip()
                if not line.startswith('{'): continue
                try:
                    content = json.loads(line)
                    # 原始文件格式为 {"backend_name": [...]}
                    data_key = list(content.keys())[0]
                    entries = content[data_key]
                    if entries:
                        new_entries_found = True
                        for entry in entries:
                            for full_name, stats in entry.items():
                                op, scale, impl = get_info(full_name)
                                temp_updates.append((op, scale, backend_id, impl, stats))
                except Exception:
                    continue
        
        # 只有当文件中包含有效的新数据时，才更新主数据树
        if new_entries_found:
            print(f"Updating data form {filename}...")
            for op, scale, backend, impl, stats in temp_updates:
                # 构建嵌套结构: 项目 -> 规模 -> 后端 -> 实现 -> 结果
                if op not in result_tree: result_tree[op] = {}
                if scale not in result_tree[op]: result_tree[op][scale] = {}
                if backend not in result_tree[op][scale]: result_tree[op][scale][backend] = {}
                
                # 保存完整的统计结果
                result_tree[op][scale][backend][impl] = stats
        else:
             print(f"Skipping {filename}: No valid data found (preserving existing data for {backend_id})")

    # 保存为最终的 JSON 文件
    with open(output_file, 'w', encoding='utf-8') as out:
        json.dump(result_tree, out, indent=2, ensure_ascii=False)
    
    print(f"清洗完成！数据已保存至: {output_file}")

if __name__ == "__main__":
    main()