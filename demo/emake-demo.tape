# erun.nvim — Emake command demo
Output demo/emake-demo.gif
Set FontSize 20
Set Width 1200
Set Height 800
Set Theme "Catppuccin Mocha"
Set Shell bash
Set TypingSpeed 100ms
Set Padding 10

# Setup (hidden)
Hide
Type "cd demo/makeproject"
Enter
Sleep 500ms
Type "clear"
Enter
Sleep 300ms
Show

# Open nvim in the make project directory
Type "nvim -u ../init.lua Makefile"
Enter
Sleep 2s

# ═══════════════════════════════════════════
# Step 1: Run Emake with tab completion
# ═══════════════════════════════════════════
Type ":Emake "
Sleep 500ms

# Show tab completion of targets
Tab
Sleep 1.5s

# Select "build" target
Tab
Sleep 1s

Enter
Sleep 3s

# ═══════════════════════════════════════════
# Step 2: Edit command in panel to run "test"
# ═══════════════════════════════════════════
Ctrl+W
Type "j"
Sleep 500ms

# Go to the command line
Type "gg3j"
Sleep 500ms

# Change "build" to "test"
Type "0f "
Sleep 200ms
Type "ld$"
Sleep 200ms
Type "amake test"
Sleep 200ms
Escape
Sleep 500ms

# Rerun with edited command
Type "r"
Sleep 3s

# ═══════════════════════════════════════════
# Step 3: Try an invalid target to show warning
# ═══════════════════════════════════════════
Ctrl+W
Type "k"
Sleep 500ms

Type ":Emake nonexistent"
Enter
Sleep 3s

# Pause to show the diagnostic
Sleep 2s

# Quit
Type ":qa!"
Enter
Sleep 500ms
