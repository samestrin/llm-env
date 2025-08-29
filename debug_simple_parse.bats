#!/usr/bin/env bats

@test "simple file reading test" {
    # Create test config
    export TEST_HOME="$BATS_TMPDIR/simple-$$"
    mkdir -p "$TEST_HOME"
    
    cat > "$TEST_HOME/test.conf" << 'EOF'
[test_provider]
base_url=https://api.example.com/v1
enabled=true
EOF

    echo "File contents:" >&3
    cat "$TEST_HOME/test.conf" >&3
    echo "---" >&3
    
    # Test basic reading
    while IFS= read -r line || [[ -n "$line" ]]; do
        echo "Read line: '$line'" >&3
    done < "$TEST_HOME/test.conf"
    
    true  # Always pass
}