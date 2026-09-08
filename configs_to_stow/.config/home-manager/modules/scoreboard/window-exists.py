import json
import sys

tree = json.load(sys.stdin)


def walk(node):
    name = node.get("name") or ""
    if node.get("window") and name == "scoreboard":
        sys.exit(0)
    for child in node.get("nodes", []) + node.get("floating_nodes", []):
        walk(child)


walk(tree)
sys.exit(1)
