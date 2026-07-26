#!/usr/bin/env python3
import subprocess
import json
import sys

def run(cmd):
    return json.loads(subprocess.check_output(cmd))

def get_all_windows(node):
    if node.get('window'):
        return [node['id']]
    windows = []
    for child in node.get('nodes', []) + node.get('floating_nodes', []):
        windows.extend(get_all_windows(child))
    return windows

def find_focused_workspace(node):
    def has_focused(n):
        if n.get('focused'):
            return True
        return any(has_focused(c) for c in n.get('nodes', []) + n.get('floating_nodes', []))
    if node.get('type') == 'workspace' and has_focused(node):
        return node
    for child in node.get('nodes', []) + node.get('floating_nodes', []):
        result = find_focused_workspace(child)
        if result:
            return result
    return None

def find_focused_window(node):
    if node.get('focused') and node.get('window'):
        return node
    for child in node.get('nodes', []) + node.get('floating_nodes', []):
        result = find_focused_window(child)
        if result:
            return result
    return None

tree = run(['i3-msg', '-t', 'get_tree'])
ws = find_focused_workspace(tree)
if not ws:
    sys.exit(1)

windows = get_all_windows(ws)
current_node = find_focused_window(tree)

if not windows or not current_node or current_node['id'] not in windows:
    sys.exit(1)

is_fullscreen = current_node.get('fullscreen_mode', 0) > 0
idx = windows.index(current_node['id'])
direction = sys.argv[1] if len(sys.argv) > 1 else 'next'
if direction == 'next':
    next_idx = (idx + 1) % len(windows)
else:
    next_idx = (idx - 1) % len(windows)

cmds = []
if is_fullscreen:
    cmds.append(f'[con_id={current_node["id"]}] fullscreen disable')
cmds.append(f'[con_id={windows[next_idx]}] focus')
if is_fullscreen:
    cmds.append(f'[con_id={windows[next_idx]}] fullscreen enable')

subprocess.run(['i3-msg', ' ; '.join(cmds)])
