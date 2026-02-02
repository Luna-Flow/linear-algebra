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

        # Display name mapping
        IMPL_DISPLAY = {
            'lib': 'Library Impl',
            'array1d': 'Optimized 1D Array Impl',
            'array2d': 'Optimized 2D Array Impl',
            'naive': 'Naive Impl'
        }

        for ax, backend in zip(axes, backends):
            y_labels = []
            lib_vals = []
            array1d_vals = []
            array2d_vals = []
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
                
                # 简化左侧标签
                display_baseline = IMPL_DISPLAY.get(baseline_key, baseline_key)
                y_labels.append(f"Size:{scale}\n(Ref:{display_baseline})")
                
                def get_speedup(key):
                    if key in impls and impls[key]['mean'] > 0:
                        return baseline_time / impls[key]['mean']
                    return 0

                lib_vals.append(get_speedup('lib'))
                array1d_vals.append(get_speedup('array1d'))
                array2d_vals.append(get_speedup('array2d'))
                naive_vals.append(get_speedup('naive'))

            if not y_labels:
                ax.set_title(f"Backend: {backend} - (No comparable data)")
                continue

            # 绘图逻辑
            y = np.arange(len(y_labels))
            height = 0.2
            
            # 使用对数坐标轴处理悬殊差异
            ax.set_xscale('log')
            
            def add_labels(rects):
                for rect in rects:
                    width = rect.get_width()
                    if width > 0:
                        ax.annotate(f'{width:.1f}x',
                                    xy=(width, rect.get_y() + rect.get_height() / 2),
                                    xytext=(3, 0),
                                    textcoords="offset points",
                                    ha='left', va='center', fontsize=9)

            b1 = ax.barh(y + 3*height, lib_vals, height, label=IMPL_DISPLAY['lib'], color='#104E8B', alpha=0.9)
            b2 = ax.barh(y + 2*height, array1d_vals, height, label=IMPL_DISPLAY['array1d'], color='#8A2BE2', alpha=0.9)
            b3 = ax.barh(y + height,   array2d_vals, height, label=IMPL_DISPLAY['array2d'], color='#C8A2C8', alpha=0.9)
            b4 = ax.barh(y,           naive_vals, height, label=IMPL_DISPLAY['naive'], color='#87CEEB', alpha=0.9)

            add_labels(b1); add_labels(b2); add_labels(b3); add_labels(b4)

            ax.set_yticks(y + 1.5*height)
            ax.set_yticklabels(y_labels)
            ax.set_title(f'Backend: {backend.upper()}', fontsize=14, loc='left')
            ax.set_xlabel('Speedup (Log Scale, higher is better)', fontsize=10)
            ax.axvline(1.0, color='black', linestyle='--', linewidth=1, alpha=0.5)
            
            # 增加网格：对数坐标下需要显示主次网格
            ax.grid(True, which='major', linestyle='-', alpha=0.4)
            ax.grid(True, which='minor', linestyle=':', alpha=0.2)
            
            # 设置下限，对数坐标不能为0
            ax.set_xlim(left=0.1)
            
            ax.legend(loc='lower right', fontsize=9)

        # 保存结果
        output_name = f'chart_{project}.png'
        plt.savefig(output_name, bbox_inches='tight', dpi=120)
        plt.close()
        print(f"已生成项目图表: {output_name}")

if __name__ == "__main__":
    main()