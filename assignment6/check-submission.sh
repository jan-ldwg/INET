#!/usr/bin/env bash
# Check required files, Bash syntax and the student list. Does not run your code.
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


directory=${1:-.}
for file in npa-06-q3.sh npa-06-q4.sh firewall.nft generate_packets.py students.csv; do
    [[ -f "$directory/$file" ]] || { echo "Missing: $file" >&2; exit 1; }
done
bash -n "$directory/npa-06-q3.sh"
bash -n "$directory/npa-06-q4.sh"
check_student_list "$directory/students.csv"
echo 'Required files and Bash syntax checked. Test the actual tasks in your lab.'
