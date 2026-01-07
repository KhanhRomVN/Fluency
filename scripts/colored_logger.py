#!/usr/bin/env python3
import os
import sys
import pty
import re
import select
import termios
import tty
import time

# ANSI Color Codes
RESET = "\033[0m"
RED = "\033[31m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
BLUE = "\033[34m"
MAGENTA = "\033[35m"
CYAN = "\033[36m"
WHITE = "\033[37m"
GRAY = "\033[90m"

# Regex for Android Logcat style tags (e.g., I/flutter, W/System, E/Error)
LOG_PATTERN = re.compile(r"^([A-Z])/(.+?)(\(\s*\d+\))?:\s+(.*)$")

# Patterns to filter out (ignore these lines entirely)
IGNORE_PATTERNS = [
    re.compile(r"I/GED.*ged_boost_gpu_freq"),
    re.compile(r"D/BLASTBufferQueue"),
    re.compile(r"D/BufferQueueConsumer"),
    re.compile(r"I/OpenGLRenderer"),
    re.compile(r"W/Parcel.*Expecting binder but got null"),
    # Add more patterns as needed
]

def colorize_line(line_bytes):
    # Decode
    try:
        line_str = line_bytes.decode('utf-8')
    except UnicodeDecodeError:
        return line_bytes

    stripped = line_str.strip()
    
    # Check filters
    for pattern in IGNORE_PATTERNS:
        if pattern.search(stripped):
            return b"" 

    # Colorize
    match = LOG_PATTERN.match(stripped)
    if match:
        level, tag, pid, message = match.groups()
        color = WHITE
        if level == 'I': color = GREEN
        elif level == 'W': color = YELLOW
        elif level == 'E': color = RED
        elif level == 'D': color = CYAN
        elif level == 'V': color = GRAY
        
        # Preserve original line ending usually
        # But we reconstruct for color
        formatted = f"{color}[{level}/{tag}]{RESET}: {message}\r\n"
        return formatted.encode('utf-8')

    # Generic Flutter highlighting
    if "Error" in line_str or "Exception" in line_str:
        return f"{RED}{line_str}{RESET}".encode('utf-8')
    # Use startswith for Warning to avoid coloring sentences containing "warning"
    if line_str.lstrip().startswith("Warning"): 
         return f"{YELLOW}{line_str}{RESET}".encode('utf-8')

    return line_bytes

def main():
    # Parse args
    cmd = ["flutter", "run"]
    if len(sys.argv) > 1:
        if sys.argv[1] == "--test-command":
             cmd = sys.argv[2:]
        else:
             cmd = ["flutter", "run"] + sys.argv[1:]

    print(f"{BLUE}Starting customized flutter logger...{RESET}")
    print(f"{GRAY}Command: {' '.join(cmd)}{RESET}")

    # Fork PTY
    try:
        pid, master_fd = pty.fork()
    except OSError as e:
        print(f"{RED}Error forking pty: {e}{RESET}")
        return

    if pid == 0:
        # Child process
        try:
            os.execvp(cmd[0], cmd)
        except OSError as e:
            sys.stderr.write(f"Error executing command: {e}\n")
            sys.exit(1)
    
    # Parent process
    # Set Raw mode for stdin to pass all keys (Ctrl+C, etc) to child
    restore_tty = False
    original_mode = None
    try:
        fd_stdin = sys.stdin.fileno()
        if os.isatty(fd_stdin):
            original_mode = termios.tcgetattr(fd_stdin)
            tty.setraw(fd_stdin)
            restore_tty = True
    except termios.error:
        pass

    buffer = b""
    try:
        while True:
            try:
                # 0.05s timeout to detect "pauses" (prompts)
                rfds, _, _ = select.select([sys.stdin, master_fd], [], [], 0.05)
            except select.error:
                break # Interrupted syscall

            if not rfds:
                # Timeout: Flush buffer if any (likely a prompt)
                if buffer:
                    sys.stdout.buffer.write(buffer)
                    sys.stdout.buffer.flush()
                    buffer = b""
                continue

            # Handle Child Output
            if master_fd in rfds:
                try:
                    data = os.read(master_fd, 4096)
                except OSError:
                    data = b""
                
                if not data:
                    break # EOF from child
                
                buffer += data
                
                # Process complete lines
                while b'\n' in buffer:
                    line, sep, rest = buffer.partition(b'\n')
                    full_line = line + sep
                    processed = colorize_line(full_line)
                    sys.stdout.buffer.write(processed)
                    sys.stdout.buffer.flush()
                    buffer = rest
            
            # Handle User Input
            if sys.stdin in rfds:
                try:
                    input_data = os.read(fd_stdin, 1024)
                except OSError:
                    input_data = b""
                
                if not input_data:
                    break # Stdin closed
                
                # Write to child
                os.write(master_fd, input_data)

    except OSError:
        pass # Child exited
    finally:
        # Restore terminal
        if restore_tty and original_mode:
            termios.tcsetattr(fd_stdin, termios.TCSAFLUSH, original_mode)
        
        # Wait for child to ensure no zombie
        os.waitpid(pid, 0)

if __name__ == "__main__":
    main()
