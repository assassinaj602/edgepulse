import csv
import os
import matplotlib.pyplot as plt
import numpy as np

def generate_figures():
    csv_path = '/media/win_drive2/New folder (4)/github_pr/edgepulse/research/experiment/results/joint_study.csv'
    output_dir = '/media/win_drive2/New folder (4)/github_pr/edgepulse/docs/assets/figures'
    os.makedirs(output_dir, exist_ok=True)

    with open(csv_path, 'r', encoding='utf-8') as f:
        rows = list(csv.DictReader(f))

    models = ['mobilenet-v3-small-tflite', 'resnet18-onnx', 'tinyllama-1.1b-gguf']
    scenarios = ['baseline', 'memory_pressure', 'malformed_input', 'thermal_stress']
    scenario_labels = ['Baseline', 'Memory Pressure', 'Malformed Input', 'Thermal Stress']

    # Group durations by (model, scenario)
    data = {}
    for m in models:
        data[m] = {}
        for s in scenarios:
            data[m][s] = []

    for r in rows:
        m = r['model_id']
        s = r['scenario']
        if m in data and s in data[m]:
            try:
                dur = float(r['duration_ms'])
                data[m][s].append(dur)
            except ValueError:
                pass

    plt.style.use('seaborn-v0_8-whitegrid' if 'seaborn-v0_8-whitegrid' in plt.style.available else 'default')

    # ---------------------------------------------------------
    # FIGURE 1: Grouped Bar Chart of Mean Latencies with Error Bars
    # ---------------------------------------------------------
    fig, ax = plt.subplots(figsize=(10, 6), dpi=300)
    x = np.arange(len(models))
    width = 0.2
    colors = ['#2b5c8f', '#4682b4', '#e67e22', '#d9534f']

    for i, s in enumerate(scenarios):
        means = [np.mean(data[m][s]) if data[m][s] else 0 for m in models]
        stds = [np.std(data[m][s]) if data[m][s] else 0 for m in models]
        rects = ax.bar(x + (i - 1.5) * width, means, width, yerr=stds, label=scenario_labels[i], color=colors[i], capsize=4)

    ax.set_ylabel('Inference Latency (ms)', fontsize=12, fontweight='bold')
    ax.set_title('Inference Latency Across Models and Injected Fault Scenarios (Tecno CH7n)', fontsize=14, fontweight='bold', pad=15)
    ax.set_xticks(x)
    ax.set_xticklabels(['MobileNetV3 (TFLite)', 'ResNet-18 (ONNX)', 'TinyLlama 1.1B (GGUF)'], fontsize=11, fontweight='bold')
    ax.legend(title='Scenario', fontsize=10, title_fontsize=11)
    ax.set_yscale('log')
    ax.set_ylim(80, 10000)
    plt.tight_layout()
    fig1_path = os.path.join(output_dir, 'joint_latency_bars.png')
    plt.savefig(fig1_path)
    plt.close()
    print(f'Saved Figure 1: {fig1_path} ({os.path.getsize(fig1_path)} bytes)')

    # ---------------------------------------------------------
    # FIGURE 2: Side-by-Side Boxplots
    # ---------------------------------------------------------
    fig, axes = plt.subplots(1, 3, figsize=(14, 5), dpi=300, sharey=False)
    model_titles = ['MobileNetV3 (TFLite)', 'ResNet-18 (ONNX)', 'TinyLlama 1.1B (GGUF)']

    for idx, m in enumerate(models):
        ax = axes[idx]
        box_data = [data[m][s] for s in scenarios]
        bp = ax.boxplot(box_data, tick_labels=['Base', 'Mem', 'Mal', 'Therm'], patch_artist=True)
        for box, col in zip(bp['boxes'], colors):
            box.set_facecolor(col)
            box.set_alpha(0.8)
        ax.set_title(model_titles[idx], fontsize=12, fontweight='bold')
        ax.set_ylabel('Latency (ms)' if idx == 0 else '', fontsize=11)
        ax.grid(True, linestyle='--', alpha=0.5)

    fig.suptitle('Distribution of Inference Timings Under Injected Fault Scenarios', fontsize=14, fontweight='bold', y=1.02)
    plt.tight_layout()
    fig2_path = os.path.join(output_dir, 'joint_latency_boxplots.png')
    plt.savefig(fig2_path)
    plt.close()
    print(f'Saved Figure 2: {fig2_path} ({os.path.getsize(fig2_path)} bytes)')

    # ---------------------------------------------------------
    # FIGURE 3: TinyLlama Malformed Input Histogram
    # ---------------------------------------------------------
    fig, ax = plt.subplots(figsize=(9, 5), dpi=300)
    base_gguf = data['tinyllama-1.1b-gguf']['baseline']
    mal_gguf = data['tinyllama-1.1b-gguf']['malformed_input']

    ax.hist(base_gguf, bins=10, alpha=0.7, label='Baseline', color='#2b5c8f', edgecolor='black')
    ax.hist(mal_gguf, bins=15, alpha=0.7, label='Malformed Input (SATE AI)', color='#e67e22', edgecolor='black')
    ax.set_xlabel('Inference Latency (ms)', fontsize=12, fontweight='bold')
    ax.set_ylabel('Frequency (Runs)', fontsize=12, fontweight='bold')
    ax.set_title('Bimodal Latency Distribution for TinyLlama 1.1B GGUF Under Malformed Input', fontsize=13, fontweight='bold', pad=15)
    ax.legend(fontsize=11)
    ax.annotate('Bimodal Outliers (~20,000 ms)\nRecursive Generation Loop',
                xy=(19700, 2), xytext=(12000, 3.5),
                arrowprops=dict(facecolor='black', shrink=0.05, width=1.5, headwidth=8),
                fontsize=10, fontweight='bold', bbox=dict(boxstyle='round,pad=0.5', facecolor='yellow', alpha=0.5))
    plt.tight_layout()
    fig3_path = os.path.join(output_dir, 'joint_tinyllama_malformed.png')
    plt.savefig(fig3_path)
    plt.close()
    print(f'Saved Figure 3: {fig3_path} ({os.path.getsize(fig3_path)} bytes)')

    # ---------------------------------------------------------
    # FIGURE 4: Percentage Latency Change vs Baseline
    # ---------------------------------------------------------
    fig, ax = plt.subplots(figsize=(10, 6), dpi=300)
    fault_scenarios = ['memory_pressure', 'malformed_input', 'thermal_stress']
    fault_labels = ['Memory Pressure', 'Malformed Input', 'Thermal Stress']
    x = np.arange(len(models))
    width = 0.25
    color_subset = ['#4682b4', '#e67e22', '#d9534f']

    for i, s in enumerate(fault_scenarios):
        changes = []
        for m in models:
            base_m = np.mean(data[m]['baseline']) if data[m]['baseline'] else 1.0
            scen_m = np.mean(data[m][s]) if data[m][s] else 1.0
            pct = ((scen_m - base_m) / base_m) * 100.0
            changes.append(pct)

        rects = ax.bar(x + (i - 1) * width, changes, width, label=fault_labels[i], color=color_subset[i])
        for rect in rects:
            h = rect.get_height()
            v_text = f'{h:+.1f}%' if abs(h) >= 1.0 else '0.0%'
            ax.annotate(v_text,
                        xy=(rect.get_x() + rect.get_width() / 2, h),
                        xytext=(0, 3 if h >= 0 else -12),
                        textcoords="offset points",
                        ha='center', va='bottom' if h >= 0 else 'top', fontsize=9, fontweight='bold')

    ax.set_ylabel('Latency Change vs Baseline (%)', fontsize=12, fontweight='bold')
    ax.set_title('Relative Performance Impact of Fault Injections Across Edge AI Models', fontsize=14, fontweight='bold', pad=15)
    ax.set_xticks(x)
    ax.set_xticklabels(['MobileNetV3 (TFLite)', 'ResNet-18 (ONNX)', 'TinyLlama 1.1B (GGUF)'], fontsize=11, fontweight='bold')
    ax.axhline(0, color='black', linewidth=1)
    ax.legend(title='Fault Scenario', fontsize=10, title_fontsize=11)
    plt.tight_layout()
    fig4_path = os.path.join(output_dir, 'joint_percentage_change.png')
    plt.savefig(fig4_path)
    plt.close()
    print(f'Saved Figure 4: {fig4_path} ({os.path.getsize(fig4_path)} bytes)')

if __name__ == '__main__':
    generate_figures()
