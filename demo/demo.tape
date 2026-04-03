# erun.nvim — real Go development workflow demo
Output demo/erun-demo.gif
Set FontSize 14
Set Width 1200
Set Height 800
Set Theme "Catppuccin Mocha"
Set Shell bash
Set TypingSpeed 100ms
Set Padding 10

# Reset demo state (hidden)
Hide
Type "cp demo/goproject/main_broken.go.bak demo/goproject/main.go && cd demo/goproject"
Enter
Sleep 500ms
Type "clear"
Enter
Sleep 300ms
Show

# Open nvim in the go project directory
Type "nvim -u ../init.lua main.go"
Enter
Sleep 2s

# ═══════════════════════════════════════════
# Step 1: Try to build — see compile error
# ═══════════════════════════════════════════
Type ":Erun go build ./..."
Sleep 200ms
Enter
Sleep 3s

# ═══════════════════════════════════════════
# Step 2: Focus panel and jump to error with Enter
# ═══════════════════════════════════════════
Ctrl+W
Type "j"
Sleep 500ms

# Search for the error line containing main.go
Type "/main.go"
Enter
Sleep 500ms

# Jump to file location with gf
Type "gf"
Sleep 1.5s

# ═══════════════════════════════════════════
# Step 3: Fix the error — delete the unused variable
# ═══════════════════════════════════════════
Type "dd"
Sleep 1s

# Save the file
Type ":w"
Enter
Sleep 1s

# ═══════════════════════════════════════════
# Step 4: Focus panel and rerun build with r
# ═══════════════════════════════════════════
Ctrl+W
Type "j"
Sleep 500ms

Type "r"
Sleep 3s

# ═══════════════════════════════════════════
# Step 5: Edit command in output buffer to "go run ."
# ═══════════════════════════════════════════

# Go to the command line (line 4: "$ go build ./...")
Type "gg3j"
Sleep 500ms

# Select after "$ " and change the command
Type "0f "
Sleep 200ms
Type "ld$"
Sleep 200ms
Type "ago run ."
Sleep 200ms
Escape
Sleep 500ms

# Rerun with edited command
Type "r"
Sleep 3s

# Pause to show the final result
Sleep 2s

# Quit
Type ":qa!"
Enter
Sleep 500ms
