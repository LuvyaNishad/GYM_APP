"""Reject private planning files in the index or outgoing Git changes."""

from pathlib import PurePosixPath
import re
import subprocess
import sys


PUBLIC_MARKDOWN = {
    "README.md",
    "ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md",
}
PRIVATE_DIRECTORIES = {".local", ".agents", ".claude", ".codex", "docs"}


def is_private(path):
    name = PurePosixPath(path)
    if name.parts and name.parts[0] in PRIVATE_DIRECTORIES:
        return True
    suffix = name.suffix.lower()
    if suffix == ".md":
        return path not in PUBLIC_MARKDOWN
    if suffix == ".txt":
        return name.name != "CMakeLists.txt"
    base = name.name.lower()
    if any(k in base for k in ("todo", "backlog", "scratch")) and suffix not in (
        ".dart", ".png", ".jpg", ".jpeg", ".webp", ".svg", ".json", ".arb",
    ):
        return True
    if base.startswith(("plan", "progress")) and suffix in (
        "", ".md", ".txt", ".notes", ".todo", ".plan", ".progress",
    ):
        return True
    return suffix == ".log"


def git(*args):
    return subprocess.run(
        ["git", *args], check=True, stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    ).stdout


def paths(output):
    return [part.decode("utf-8", errors="surrogateescape")
            for part in output.split(b"\0") if part]


def report(label, filenames):
    private = sorted({path for path in filenames if is_private(path)})
    if not private:
        return False
    print(f"Private-file guard blocked {label}:", file=sys.stderr)
    for path in private:
        print(f"  {path}", file=sys.stderr)
    return True


def check_index():
    return report("tracked files", paths(git("ls-files", "-z")))


def check_push():
    blocked = False
    checked_trees = set()
    checked_commits = set()
    for line in sys.stdin:
        fields = line.split()
        if len(fields) != 4:
            raise ValueError("Invalid pre-push input")
        local_ref, local_oid, _, remote_oid = fields
        if not all(re.fullmatch(r"[0-9a-fA-F]{40,64}", oid)
                   for oid in (local_oid, remote_oid)):
            raise ValueError("Invalid pre-push object ID")
        if set(local_oid) == {"0"}:
            continue
        if local_oid not in checked_trees:
            blocked |= report(
                f"push of {local_ref}",
                paths(git("ls-tree", "-r", "--name-only", "-z", local_oid)),
            )
            checked_trees.add(local_oid)

        remote_known = set(remote_oid) != {"0"} and subprocess.run(
            ["git", "cat-file", "-e", f"{remote_oid}^{{commit}}"],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        ).returncode == 0
        exclusions = [f"^{remote_oid}"] if remote_known else ["--not", "--remotes"]
        commits = git("rev-list", local_oid, *exclusions).decode("ascii").split()
        for commit in commits:
            if commit in checked_commits:
                continue
            # Check additions/edits in every outgoing commit, even if a later
            # commit deletes the file. Existing remote history is not rewritten.
            # Pure deletions are permitted.
            blocked |= report(
                f"outgoing commit {commit[:12]}",
                paths(git("diff-tree", "--root", "-m", "--no-commit-id",
                          "--name-only", "--diff-filter=ACMRT", "-r", "-z", commit)),
            )
            checked_commits.add(commit)
    return blocked


def main():
    if sys.argv[1:] not in ([], ["--pre-push"]):
        print("Usage: check_private_files.py [--pre-push]", file=sys.stderr)
        return 2
    try:
        blocked = check_push() if sys.argv[1:] else check_index()
    except (subprocess.CalledProcessError, ValueError) as error:
        print(f"Private-file guard could not verify Git state: {error}", file=sys.stderr)
        return 2
    if blocked:
        print("Keep internal notes in .local/BACKLOG.md and remove private files "
              "from Git. Do not force-add them or bypass this guard.", file=sys.stderr)
        return 1
    if not sys.argv[1:]:
        print("Private-file guard passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
