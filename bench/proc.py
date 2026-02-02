import json
import matplotlib.pyplot as plt
import numpy as np
import os

# 1. 加载清洗后的数据
DATA_FILE = 'cleaned_benchmarks.json'

def main():
    if not os.path.exists(DATA_FILE):
        print(f"错误: 找不到文件 {DATA_FILE}，请先运行清洗脚本。")
        return

    with open(DATA_FILE, 'r', encoding='utf-8') as f:
        data = json.load(f)

    # 获取所有测试项目
    projects = sorted(data.keys())

    for project in projects:
        scales_dict = data[project]
        # 对 Scale 进行数值排序
        sorted_scales = sorted(scales_dict.keys(), key=lambda x: int(x) if x.isdigit() else 0)
        
        # 找出该项目涉及的所有后端
        backends = set()
        for s in sorted_scales:
            backends.update(scales_dict[s].keys())
        backends = sorted(list(backends))
        
        if not backends: continue

        # 创建画布：增加宽度，利用 bbox_inches='tight' 确保完全显示
        num_backends = len(backends)
        fig, axes = plt.subplots(num_backends, 1, figsize=(14, 4 * num_backends), constrained_layout=True)
        if num_backends == 1:
            axes = [axes]
        
        fig.suptitle(f'Project: {project.upper()} Performance Analysis', fontsize=18, fontweight='bold')

        for ax, backend in zip(axes, backends):
            y_labels = []
            lib_vals = []
            native_vals = []
            two_d_vals = []
            naive_vals = []
            
            for scale in sorted_scales:
                if backend not in scales_dict[scale]: continue
                
                impls = scales_dict[scale][backend]
                
                # 动态选择基准 (Baseline)
                if 'naive' in impls:
                    baseline_key = 'naive'
                elif 'lib' in impls:
                    baseline_key = 'lib'
                else:
                    baseline_key = list(impls.keys())[0]
                
                baseline_time = impls[baseline_key]['mean']
                
                # 简化左侧标签，缩短占用空间
                y_labels.append(f"Size:{scale}\n(Ref:{baseline_key})")
                lib_vals.append(baseline_time / impls['lib']['mean'] if 'lib' in impls else 0)
                native_vals.append(baseline_time / impls['native']['mean'] if 'native' in impls else 0)
                two_d_vals.append(baseline_time / impls['2d']['mean'] if '2d' in impls else 0)
                naive_vals.append(baseline_time / impls['naive']['mean'] if 'naive' in impls else 0)

            if not y_labels:
                ax.set_title(f"Backend: {backend} - (No comparable data)")
                continue

            # 绘图逻辑
            y = np.arange(len(y_labels))
            height = 0.2 # 柱子宽度
            
            # 使用同一色系（蓝色系）的不同深浅
            ax.barh(y + 3*height, lib_vals, height, label='Library', color='#104E8B', alpha=0.9) # 正深蓝
            ax.barh(y + 2*height, native_vals, height, label='1D', color='#8A2BE2', alpha=0.9) # 紫罗兰
            ax.barh(y + height,   two_d_vals, height, label='2D (Nested)', color='#C8A2C8', alpha=0.9) # 丁香紫
            ax.barh(y,           naive_vals, height, label='Naive (Functional)', color='#87CEEB', alpha=0.9) # 天蓝

            ax.set_yticks(y + 1.5*height)
            ax.set_yticklabels(y_labels)
            ax.set_title(f'Backend: {backend.upper()}', fontsize=14, loc='left')
            ax.set_xlabel('Speedup (Naive = 1.0)')
            ax.axvline(1.0, color='black', linestyle='--', linewidth=1, alpha=0.5)
            
            # 增加网格密度，使差距更明显
            ax.grid(axis='x', which='both', linestyle=':', alpha=0.6)
            # 根据最大值动态调整辅助网格密度，避免出现百万级网格
            max_val = max(max(lib_vals), max(native_vals), max(two_d_vals), 1.0)
            if max_val < 20:
                ax.xaxis.set_minor_locator(plt.MultipleLocator(1.0))
            elif max_val < 100:
                ax.xaxis.set_minor_locator(plt.MultipleLocator(5.0))
            else:
                ax.xaxis.set_minor_locator(plt.MultipleLocator(max_val / 10.0))
            
            ax.legend(loc='lower right')

        # 保存结果
        output_name = f'chart_{project}.png'
        plt.savefig(output_name, bbox_inches='tight', dpi=120)
        plt.close()
        print(f"已生成项目图表: {output_name}")

if __name__ == "__main__":
    main()