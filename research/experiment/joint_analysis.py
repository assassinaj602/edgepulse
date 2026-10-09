import csv
import json
import math
import os

def load_data(csv_path):
    with open(csv_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        return list(reader)

def percentile(data, p):
    if not data:
        return 0.0
    sorted_data = sorted(data)
    k = (len(sorted_data) - 1) * (p / 100.0)
    f = math.floor(k)
    c = math.ceil(k)
    if f == c:
        return sorted_data[int(k)]
    return sorted_data[int(f)] * (c - k) + sorted_data[int(c)] * (k - f)

def mann_whitney_u(x, y):
    """Computes Mann-Whitney U statistic and normal approximation p-value."""
    n1, n2 = len(x), len(y)
    if n1 == 0 or n2 == 0:
        return 0.0, 1.0
    
    # Combined ranks
    combined = [(val, 'x') for val in x] + [(val, 'y') for val in y]
    combined.sort(key=lambda t: t[0])
    
    ranks = {}
    i = 0
    while i < len(combined):
        j = i
        while j < len(combined) and combined[j][0] == combined[i][0]:
            j += 1
        rank_val = (i + 1 + j) / 2.0
        for k in range(i, j):
            combined[k] = (combined[k][0], combined[k][1], rank_val)
        i = j
        
    r1 = sum(t[2] for t in combined if t[1] == 'x')
    u1 = r1 - (n1 * (n1 + 1)) / 2.0
    u2 = n1 * n2 - u1
    u = min(u1, u2)
    
    # Normal approximation with continuity correction
    mu = (n1 * n2) / 2.0
    sigma = math.sqrt((n1 * n2 * (n1 + n2 + 1)) / 12.0)
    if sigma == 0:
        z = 0.0
    else:
        z = (abs(u1 - mu) - 0.5) / sigma
        
    # Standard normal CDF approximation (erf based)
    p_val = 2.0 * (1.0 - 0.5 * (1.0 + math.erf(z / math.sqrt(2.0))))
    p_val = max(0.0, min(1.0, p_val))
    
    # Rank-biserial correlation effect size r
    effect_r = 1.0 - (2.0 * u) / (n1 * n2)
    return u, p_val, effect_r

def analyze():
    csv_path = '/media/win_drive2/New folder (4)/github_pr/edgepulse/research/experiment/results/joint_study.csv'
    rows = load_data(csv_path)

    # Group by (model_id, scenario)
    grouped = {}
    for r in rows:
        m = r['model_id']
        s = r['scenario']
        key = (m, s)
        if key not in grouped:
            grouped[key] = []
        grouped[key].append(r)

    summary = {}
    models = sorted(list(set(r['model_id'] for r in rows)))
    scenarios = ['baseline', 'memory_pressure', 'malformed_input', 'thermal_stress']

    print('=' * 85)
    print(f'{"JOINT SATE AI + EDGEPULSE EXPERIMENTAL STATISTICAL ANALYSIS":^85}')
    print('=' * 85)

    for m in models:
        summary[m] = {}
        print(f'\nModel: {m}')
        print('-' * 85)
        print(f'{"Scenario":<18} | {"N":<3} | {"Mean (ms)":<10} | {"Std (ms)":<9} | {"Median":<8} | {"Peak RSS":<9} | {"vs Base":<9} | {"p-val":<8}')
        print('-' * 85)

        base_durs = [float(r['duration_ms']) for r in grouped.get((m, 'baseline'), []) if r.get('duration_ms')]
        base_mean = sum(base_durs) / len(base_durs) if base_durs else 0.0

        for s in scenarios:
            s_rows = grouped.get((m, s), [])
            if not s_rows:
                continue
            durs = [float(r['duration_ms']) for r in s_rows if r.get('duration_ms')]
            rss_vals = [float(r['memory_peak_mb']) for r in s_rows if r.get('memory_peak_mb')]

            n = len(durs)
            mean_dur = sum(durs) / n if n > 0 else 0.0
            std_dur = math.sqrt(sum((x - mean_dur) ** 2 for x in durs) / n) if n > 0 else 0.0
            med_dur = percentile(durs, 50)
            p25_dur = percentile(durs, 25)
            p75_dur = percentile(durs, 75)
            min_dur = min(durs) if durs else 0.0
            max_dur = max(durs) if durs else 0.0
            mean_rss = sum(rss_vals) / len(rss_vals) if rss_vals else 0.0

            stat_u, p_val, effect_r = 0.0, 1.0, 0.0
            vs_base_pct = 0.0

            if s != 'baseline' and base_durs:
                vs_base_pct = ((mean_dur - base_mean) / base_mean) * 100.0
                stat_u, p_val, effect_r = mann_whitney_u(durs, base_durs)

            summary[m][s] = {
                'n': n,
                'mean_duration_ms': round(mean_dur, 2),
                'std_duration_ms': round(std_dur, 2),
                'median_duration_ms': round(med_dur, 2),
                'p25_duration_ms': round(p25_dur, 2),
                'p75_duration_ms': round(p75_dur, 2),
                'min_duration_ms': round(min_dur, 2),
                'max_duration_ms': round(max_dur, 2),
                'mean_peak_rss_mb': round(mean_rss, 2),
                'pct_change_vs_baseline': round(vs_base_pct, 2),
                'mann_whitney_u': round(stat_u, 2),
                'p_value': round(p_val, 6),
                'effect_size_r': round(effect_r, 4),
            }

            p_str = f'{p_val:.4f}' if s != 'baseline' else 'N/A'
            vs_str = f'{vs_base_pct:+6.1f}%' if s != 'baseline' else '0.0%'

            print(f'{s:<18} | {n:<3} | {mean_dur:10.1f} | {std_dur:9.1f} | {med_dur:8.1f} | {mean_rss:7.1f}MB | {vs_str:<9} | {p_str:<8}')

    output_json = '/media/win_drive2/New folder (4)/github_pr/edgepulse/research/experiment/results/joint_summary.json'
    with open(output_json, 'w', encoding='utf-8') as out:
        json.dump(summary, out, indent=2)

    print('\n' + '=' * 85)
    print(f'Analysis saved to: {output_json}')
    print('=' * 85)

if __name__ == '__main__':
    analyze()
