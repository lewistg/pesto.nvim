#!/usr/bin/bash

set -euo pipefail

while IFS= read -r uri; do
    case "$uri" in
        "bytestream://localhost:8980/blobs/477b2a3983637d7633933691800642a388a38e1dd81ebe12304a603dc3b3dfba/226")
            printf 'bytestream://localhost:8980/blobs/477b2a3983637d7633933691800642a388a38e1dd81ebe12304a603dc3b3dfba/226\t{"data": "bWFpbi5jYzogSW4gZnVuY3Rpb24gJ2ludCBtYWluKGludCwgY2hhcioqKSc6Cm1haW4uY2M6NTo1OiBlcnJvcjogJ3gnIHdhcyBub3QgZGVjbGFyZWQgaW4gdGhpcyBzY29wZQogICAgNSB8ICAgICB4ICsgeTsKICAgICAgfCAgICAgXgptYWluLmNjOjU6OTogZXJyb3I6ICd5JyB3YXMgbm90IGRlY2xhcmVkIGluIHRoaXMgc2NvcGUKICAgIDUgfCAgICAgeCArIHk7CiAgICAgIHwgICAgICAgICBeCg=="}\n'
            printf 'bytestream://localhost:8980/blobs/477b2a3983637d7633933691800642a388a38e1dd81ebe12304a603dc3b3dfba/226\t\n'
            ;;
        *)
            echo "unmocked uri: $uri"
            exit 1
            ;;
    esac
done
