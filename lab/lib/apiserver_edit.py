#!/usr/bin/env python3
"""Surgically edit a kube-apiserver static-pod manifest (line/indent based).

The control-plane node has no python3, so the driver copies the manifest to the
host, runs this, and copies it back. Used so that resetting one question does not
clobber another question's work (a blanket restore-from-backup would).

usage: apiserver_edit.py FILE OP [args...]
  rmflag  PREFIX...        drop command flags starting with PREFIX
  setflag FLAG VALUE       set/replace '- FLAG=VALUE' (added after --authorization-mode)
  rmvol   NAME...          drop the volumeMount and volume list items named NAME
  addvol  NAME HOSTPATH MOUNTPATH RO   add a hostPath volume + volumeMount
"""
import sys


def indent_of(line):
    return len(line) - len(line.lstrip(" "))


def find_key(lines, key, max_indent=6):
    for i, l in enumerate(lines):
        s = l.strip()
        if s == key and indent_of(l) <= max_indent:
            return i
    return -1


def item_blocks(lines, key_idx):
    """(start, end) for each '- ' item of the list owned by the key at key_idx.

    In kubeadm manifests list items sit at the SAME indent as their key:

        volumes:
        - hostPath:
            path: /x
          name: n

    so an item indent of key_indent is normal and must be handled, as well as
    the more conventional deeper indent.
    """
    key_ind = indent_of(lines[key_idx])
    i = key_idx + 1
    item_ind = None
    while i < len(lines):
        l = lines[i]
        if not l.strip():
            i += 1
            continue
        ind = indent_of(l)
        if l.lstrip(" ").startswith("- ") and ind >= key_ind:
            item_ind = ind
            break
        if ind <= key_ind:
            return []          # the key owns no list
        i += 1
    if item_ind is None:
        return []

    blocks, start = [], None
    while i < len(lines):
        l = lines[i]
        if not l.strip():
            i += 1
            continue
        ind = indent_of(l)
        is_item = l.lstrip(" ").startswith("- ")
        if ind < item_ind:
            break
        if ind == item_ind:
            if is_item:
                if start is not None:
                    blocks.append((start, i))
                start = i
            else:
                break          # sibling key -> list is over
        i += 1
    if start is not None:
        blocks.append((start, i))
    return blocks


def list_item_indent(lines, key_idx):
    b = item_blocks(lines, key_idx)
    return indent_of(lines[b[0][0]]) if b else indent_of(lines[key_idx])


def rmflag(lines, prefixes):
    out = []
    for l in lines:
        s = l.strip()
        if s.startswith("- "):
            flag = s[2:]
            if any(flag == p or flag.startswith(p + "=") for p in prefixes):
                continue
        out.append(l)
    return out


def setflag(lines, flag, value):
    lines = rmflag(lines, [flag])
    for i, l in enumerate(lines):
        if l.strip().startswith("- --authorization-mode"):
            pad = " " * indent_of(l)
            lines.insert(i + 1, f"{pad}- {flag}={value}")
            return lines
    # fall back: right after the command's program name
    for i, l in enumerate(lines):
        if l.strip() == "- kube-apiserver":
            pad = " " * indent_of(l)
            lines.insert(i + 1, f"{pad}- {flag}={value}")
            return lines
    return lines


def rmvol(lines, names):
    for key in ("volumeMounts:", "volumes:"):
        changed = True
        while changed:
            changed = False
            ki = find_key(lines, key)
            if ki < 0:
                break
            for (a, b) in item_blocks(lines, ki):
                block = "\n".join(lines[a:b])
                if any(f"name: {n}" in block for n in names):
                    del lines[a:b]
                    changed = True
                    break
    return lines


def addvol(lines, name, hostpath, mountpath, ro):
    lines = rmvol(lines, [name])

    ki = find_key(lines, "volumeMounts:")
    if ki >= 0:
        ind = list_item_indent(lines, ki)
        pad = " " * ind
        lines[ki + 1:ki + 1] = [
            f"{pad}- mountPath: {mountpath}",
            f"{pad}  name: {name}",
            f"{pad}  readOnly: {ro}",
        ]

    ki = find_key(lines, "volumes:")
    if ki >= 0:
        ind = list_item_indent(lines, ki)
        pad = " " * ind
        lines[ki + 1:ki + 1] = [
            f"{pad}- hostPath:",
            f"{pad}    path: {hostpath}",
            f"{pad}    type: DirectoryOrCreate",
            f"{pad}  name: {name}",
        ]
    return lines


def apply_op(lines, op, args):
    if op == "rmflag":
        return rmflag(lines, args)
    if op == "setflag":
        return setflag(lines, args[0], args[1])
    if op == "rmvol":
        return rmvol(lines, args)
    if op == "addvol":
        return addvol(lines, args[0], args[1], args[2], args[3])
    sys.exit(f"unknown op: {op}")


def main():
    path, op = sys.argv[1], sys.argv[2]
    lines = open(path).read().split("\n")
    if op == "multi":
        # each remaining argv is one whitespace-separated op line
        for spec in sys.argv[3:]:
            parts = spec.split()
            if parts:
                lines = apply_op(lines, parts[0], parts[1:])
    else:
        lines = apply_op(lines, op, sys.argv[3:])
    open(path, "w").write("\n".join(lines))


main()
