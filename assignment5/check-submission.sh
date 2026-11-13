#!/usr/bin/env bash
# Usage: bash check-submission.sh [npa-05.sh [students.csv]]
#        bash check-submission.sh students.csv (check only the student list)
# Checks submission structure, not solution correctness. This is not a sandbox.
set -euo pipefail


check_student_list() {
    local file=$1 cmd
    for cmd in awk iconv; do
        command -v "$cmd" >/dev/null || { echo "Install $cmd to validate students.csv." >&2; return 2; }
    done
    if [[ ! -f "$file" || ! -r "$file" ]]; then
        echo "Student list check failed: students.csv is missing or unreadable." >&2
        return 2
    fi
    if ! iconv -f UTF-8 -t UTF-8 < "$file" >/dev/null 2>&1; then
        echo "Student list check failed: students.csv must contain UTF-8 text." >&2
        return 2
    fi
    # Names must fit on one record. Normalize LF, CRLF, and CR line endings.
    LC_ALL=C awk '
        BEGIN { RS = "\r\n|\n|\r" }
        function fail(message) {
            print "Student list check failed: " message > "/dev/stderr"
            failed = 1
            exit 2
        }
        function parse(line, fields, i, count, value, state, ch, key) {
            for (key in fields) delete fields[key]
            count = 0; value = ""; state = 0
            for (i = 1; i <= length(line); i++) {
                ch = substr(line, i, 1)
                if (state == 1) {
                    if (ch == "\"") {
                        if (substr(line, i + 1, 1) == "\"") { value = value "\""; i++ }
                        else state = 2
                    } else value = value ch
                } else if (state == 2) {
                    if (ch != ",") fail("unexpected text after a quoted field at row " NR)
                    fields[++count] = value; value = ""; state = 0
                } else if (ch == ",") {
                    fields[++count] = value; value = ""; state = 0
                } else if (state == 0 && ch == "\"") {
                    state = 1
                } else {
                    value = value ch; state = 3
                }
            }
            if (state == 1) fail("unclosed quote or multiline field at row " NR)
            fields[++count] = value
            return count
        }
        function trim(value) {
            sub(/^[[:space:]]+/, "", value); sub(/[[:space:]]+$/, "", value)
            return value
        }
        NR == 1 {
            bom = sprintf("%c%c%c", 239, 187, 191)
            if (substr($0, 1, 3) == bom) $0 = substr($0, 4)
            if (parse($0, fields) != 2 || fields[1] != "name" || fields[2] != "student_id")
                fail("expected CSV header name,student_id")
            next
        }
        $0 == "" { next }
        {
            if (parse($0, fields) != 2) fail("expected exactly two fields at row " NR)
            name = trim(fields[1]); identifier = trim(fields[2])
            if (name == "" || name ~ /[[:cntrl:]]/) fail("full name required on one line at row " NR)
            if (identifier !~ /^[0-9]+$/) fail("numeric student_id required at row " NR)
            normalized = identifier; sub(/^0+/, "", normalized)
            if (tolower(name) ~ /^(alex example|sam sample|robin demo|kim test)$/ ||
                normalized ~ /^(123456|234567|345678|456789)$/)
                fail("replace or remove the example entry at row " NR)
            key = "id:" identifier
            if (key in seen) fail("student_id appears more than once, at row " NR)
            seen[key] = 1
            members++
            if (members > 4) fail("groups may have at most 4 members")
        }
        END {
            if (failed) exit 2
            if (NR == 0 || members == 0) fail("list every group member; student list is empty")
            print "Student list valid (" members " " (members == 1 ? "member" : "members") ")."
        }
    ' < "$file"
}

if [[ $# -eq 0 ]]; then
    set -- npa-05.sh students.csv
fi
if [[ $# -gt 2 ]]; then
    echo "Usage: bash $0 [npa-05.sh [students.csv]]" >&2
    echo "       bash $0 students.csv (check only the student list)" >&2
    exit 2
fi

case "${1,,}" in
    *.csv)
        if [[ $# -ne 1 ]]; then
            echo "FAIL: a CSV-only check takes one file; use npa-05.sh [students.csv] to check both files." >&2
            exit 2
        fi
        check_student_list "$1"
        echo "Only the student list was checked. Run without arguments to check both files."
        exit 0
        ;;
    *.sh) ;;
    *)
        echo "FAIL: pass a .sh file to check the submission, or a .csv file to check only the student list." >&2
        exit 2
        ;;
esac

if [[ ! -f "$1" || ! -r "$1" ]]; then
    echo "FAIL: missing or unreadable npa-05.sh (or the specified script)." >&2
    exit 2
fi

_npa05_submission=$(cd -- "$(dirname -- "$1")" && printf '%s/%s\n' "$PWD" "$(basename -- "$1")")
bash -n -- "$_npa05_submission"
# This prefix belongs to the checker, not submission functions or state.
if ! awk '/^[[:space:]]*#/ { next } /_npa05_/ { exit 1 }' "$_npa05_submission"; then
    echo "FAIL: _npa05_ is reserved for checker internals." >&2
    exit 1
fi
_npa05_students=${2:-$(dirname -- "$_npa05_submission")/students.csv}
check_student_list "$_npa05_students"

# Permit only component initializers and the final source guard at source time.
# There is no reference template: component values and solution correctness are
# assessed separately. This is a structural self-check, not a security sandbox.
_npa05_quoted="(\"([^\"\\\\]|\\\\.)*\"|'[^']*')"
_npa05_token="($_npa05_quoted|[[:alnum:]_./:,+@%-]+)"
_npa05_assignment="^((NS|IF|IP|NET|SID)_[A-Z0-9_]+|NAMESPACES|ROUTERS|ROUTER_SIDS|LINKS|CAPTURE_DIR|CAPTURE_PIDS)=(${_npa05_token}|\([[:space:]]*(${_npa05_token}[[:space:]]*)*\))?$"
_npa05_work=$(mktemp -d)
trap 'rm -rf -- "$_npa05_work"' EXIT

set +e
(
    set -euo pipefail
    set -T
    _npa05_guard_seen=0
    # Invoked by DEBUG; match literal Bash syntax rather than expanding it.
    # shellcheck disable=SC2317,SC2016
    _npa05_check_command() {
        [[ "$2" == "$_npa05_submission" ]] || return 0
        if [[ "$1" == '[[ "${BASH_SOURCE[0]}" == "$0" ]]' ]] && (( ! _npa05_guard_seen )); then
            _npa05_guard_seen=1
            return 0
        fi
        if (( ! _npa05_guard_seen )); then
            if [[ "$1" == 'CAPTURE_DIR="${NPA05_CAPTURE_DIR:-$PWD/npa-05-captures}"' ]]; then
                return 0
            fi
            if [[ "$1" =~ $_npa05_assignment && "$1" != *'$('* && "$1" != *'$['* &&
                  "$1" != *'`'* && "$1" != *'${'* ]]; then
                return 0
            fi
        fi
        printf 'FAIL: unexpected source-time command: %s\n' "$1" >&2
        echo "Put solution commands and additional initializers inside functions." >&2
        exit 1
    }
    readonly -f _npa05_check_command
    readonly _npa05_submission _npa05_assignment
    trap '_npa05_check_command "$BASH_COMMAND" "${BASH_SOURCE[0]}"' DEBUG
    # shellcheck source=/dev/null
    source "$_npa05_submission"
    trap - DEBUG
    if (( ! _npa05_guard_seen )); then
        echo "FAIL: missing final source guard." >&2
        exit 1
    fi
    for _npa05_function in \
        create_namespaces create_links assign_addresses configure_host_routes \
        assign_sids configure_sid_routes enable_forwarding configure_end_actions \
        configure_srv6_routes send_probes capture_traffic verify_paths \
        fail teardown setup run_tests main; do
        if ! declare -F "$_npa05_function" >/dev/null; then
            echo "FAIL: missing function $_npa05_function." >&2
            exit 1
        fi
    done
    for _npa05_variable in NAMESPACES ROUTERS ROUTER_SIDS LINKS CAPTURE_DIR CAPTURE_PIDS; do
        if ! declare -p "$_npa05_variable" >/dev/null 2>&1; then
            echo "FAIL: missing component variable $_npa05_variable." >&2
            exit 1
        fi
    done
) > "$_npa05_work/stdout" 2> "$_npa05_work/stderr"
_npa05_status=$?
set -e

if (( _npa05_status != 0 )) || [[ -s "$_npa05_work/stdout" || -s "$_npa05_work/stderr" ]]; then
    cat "$_npa05_work/stdout" "$_npa05_work/stderr" >&2
    echo "FAIL: sourcing must return successfully and silently." >&2
    exit 1
fi
# Require the standard three-line guard, ignoring blank lines and comments.
if ! awk '\
    NF && $0 !~ /^[[:space:]]*#/ { first = second; second = third; third = $0 }
    END {
        exit !(first == "if [[ \"${BASH_SOURCE[0]}\" == \"$0\" ]]; then" &&
               second ~ /^[[:space:]]*main "\$@"[[:space:]]*$/ && third == "fi")
    }' "$_npa05_submission"; then
    echo "FAIL: keep the final source guard unchanged." >&2
    exit 1
fi

echo "Submission check passed (script interface and student list). This does not check the correctness of your solution."
