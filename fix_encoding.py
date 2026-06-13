# fix_encoding.py - Fix encoding of Lua files
# Restores windows-1251 encoding from a backup or re-applies edits

import sys
import os
import glob

def fix_encoding(filepath):
    """Read file, detect encoding, re-save as windows-1251"""
    with open(filepath, 'rb') as f:
        raw = f.read()
    
    # Check if file has UTF-8 replacement characters (ef bf bd)
    has_replacement = b'\xef\xbf\xbd' in raw
    
    if has_replacement:
        print(f"  {os.path.basename(filepath)}: HAS CORRUPTION (UTF-8 replacement chars)")
        return False
    
    # Try to decode as windows-1251
    try:
        content = raw.decode('cp1251')
        # Re-save to ensure consistent encoding
        with open(filepath, 'wb') as f:
            f.write(content.encode('cp1251'))
        print(f"  {os.path.basename(filepath)}: OK (windows-1251)")
        return True
    except UnicodeDecodeError:
        print(f"  {os.path.basename(filepath)}: NOT windows-1251")
        return False

if __name__ == '__main__':
    lua_files = glob.glob('*.lua') + glob.glob('Tests/*.lua')
    print("Checking Lua files encoding:")
    corrupted = []
    ok = []
    for f in sorted(lua_files):
        if fix_encoding(f):
            ok.append(f)
        else:
            corrupted.append(f)
    
    print(f"\n{len(ok)} OK, {len(corrupted)} corrupted")
    if corrupted:
        print("Corrupted files:", corrupted)
        print("\nTo restore, copy original files from QUIK machine:")
        print("  C:\\Users\\Nebelung\\Documents\\GitHub\\QuikAssistant\\")
