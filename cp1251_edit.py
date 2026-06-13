"""
cp1251_edit.py - Edit Lua files preserving windows-1251 encoding.

Usage from Python:
    from cp1251_edit import read_lua, write_lua, edit_lua

Usage from command line:
    python cp1251_edit.py read <file>
    python cp1251_edit.py replace <file> <old> <new>
    python cp1251_edit.py check [<dir>]
"""

import sys
import os
import glob


def read_lua(filepath):
    """Read a Lua file and return content as windows-1251 string."""
    with open(filepath, 'rb') as f:
        raw = f.read()
    return raw.decode('cp1251')


def write_lua(filepath, content):
    """Write content to a Lua file in windows-1251 encoding."""
    with open(filepath, 'wb') as f:
        f.write(content.encode('cp1251'))


def edit_lua(filepath, old_text, new_text):
    """Replace old_text with new_text in a cp1251 Lua file."""
    content = read_lua(filepath)
    if old_text not in content:
        print("ERROR: old_text not found in " + filepath)
        print("  Looking for: " + repr(old_text[:100]))
        return False
    new_content = content.replace(old_text, new_text, 1)
    write_lua(filepath, new_content)
    print("OK: " + filepath + " (" + str(len(content)) + " -> " + str(len(new_content)) + " chars)")
    return True


def check_encoding(filepath):
    """Check if a file is valid windows-1251 without corruption."""
    with open(filepath, 'rb') as f:
        raw = f.read()
    if b'\xef\xbf\xbd' in raw:
        return "CORRUPTED"
    try:
        raw.decode('cp1251')
        return "OK"
    except UnicodeDecodeError:
        return "NOT_CP1251"


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage:")
        print("  python cp1251_edit.py read <file>")
        print("  python cp1251_edit.py replace <file> <old> <new>")
        print("  python cp1251_edit.py check [<dir>]")
        sys.exit(1)

    cmd = sys.argv[1]

    if cmd == 'read':
        print(read_lua(sys.argv[2]))

    elif cmd == 'replace':
        if len(sys.argv) != 5:
            print("Usage: python cp1251_edit.py replace <file> <old_text> <new_text>")
            sys.exit(1)
        edit_lua(sys.argv[2], sys.argv[3], sys.argv[4])

    elif cmd == 'check':
        d = sys.argv[2] if len(sys.argv) > 2 else '.'
        lua_files = glob.glob(os.path.join(d, '*.lua')) + glob.glob(os.path.join(d, 'Tests', '*.lua'))
        for f in sorted(lua_files):
            status = check_encoding(f)
            marker = " X" if status != "OK" else ""
            print("  " + f + ": " + status + marker)

    else:
        print("Unknown command: " + cmd)
        sys.exit(1)
