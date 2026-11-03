"""Run Flutter test files in separate processes to isolate runner failures."""
import argparse
import hashlib
import json
import re
import shutil
import subprocess
from pathlib import Path

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('files', nargs='*', help='Optional test files; default: all tests.')
    args = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    paths = [root / file for file in args.files] if args.files else sorted((root / 'test').rglob('*_test.dart'))
    flutter = shutil.which('flutter')
    if not flutter:
        raise SystemExit('Flutter is not on PATH.')
    output = root / 'build/test_runs'
    output.mkdir(parents=True, exist_ok=True)
    results = []
    for path in paths:
        if not path.is_file() or not path.resolve().is_relative_to(root):
            raise SystemExit(f'Invalid test path: {path}')
        relative = path.relative_to(root).as_posix()
        name = f'{path.stem}_{hashlib.sha256(relative.encode()).hexdigest()[:8]}'
        for attempt in range(1, 3):
            log = output / f'{name}_attempt{attempt}.log'
            with log.open('w', encoding='utf-8') as stream:
                try:
                    run = subprocess.run([flutter, 'test', '--no-pub', '--concurrency=1', '--reporter=expanded', relative], cwd=root, stdout=stream, stderr=subprocess.STDOUT, timeout=120)
                    code = run.returncode
                except subprocess.TimeoutExpired:
                    stream.write('\nTest process timed out.\n')
                    code = 124
            text = log.read_text(encoding='utf-8', errors='replace')
            runner_only = ('did not complete' in text or 'No tests were found' in text or 'Failed to load' in text) and 'EXCEPTION CAUGHT' not in text and 'Expected:' not in text
            if code == 0 or not runner_only or attempt == 2:
                break
        count = re.findall(r'\+(\d+)(?: -\d+)?: All tests passed', text)
        result = {'file': relative, 'exit': code, 'attempts': attempt, 'tests': int(count[-1]) if count else None, 'log': log.relative_to(root).as_posix()}
        results.append(result)
        print(json.dumps(result), flush=True)
    (output / 'results.json').write_text(json.dumps(results, indent=2), encoding='utf-8')
    failures = [item for item in results if item['exit']]
    print(json.dumps({'files': len(results), 'passed': len(results) - len(failures), 'failed': len(failures), 'tests': sum(item['tests'] or 0 for item in results)}), flush=True)
    return 1 if failures else 0

if __name__ == '__main__':
    raise SystemExit(main())
