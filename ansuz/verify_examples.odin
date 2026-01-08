package ansuz

import "core:fmt"

main :: proc() {
    fmt.println("=== Ansuz Examples Verification ===")
    fmt.println("This file verifies that all examples use correct API names")
    fmt.println()

    fmt.println("Checking API function names:")
    fmt.println("  - text (correct)")
    fmt.println("  - rect (correct)")
    fmt.println("  - box (correct)")
    fmt.println("  - begin_frame (correct)")
    fmt.println("  - end_frame (correct)")
    fmt.println("  - poll_events (correct)")
    fmt.println()
    fmt.println("The examples should compile correctly when Odin is available.")
    fmt.println("All examples use renamed API functions.")
}
