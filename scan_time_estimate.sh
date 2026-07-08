find ./202606* -name method -print0 2>/dev/null |
xargs -0 awk -F= '
/^##\$PVM_ScanTime=/ {
    ms += $2
    n++
}
END {
    printf "Acquisitions: %d\n", n
    printf "Total scan time: %.2f hours\n", ms/3600000
}'
