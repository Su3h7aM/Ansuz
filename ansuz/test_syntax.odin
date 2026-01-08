package ansuz

import "core:testing"
import "core:fmt"

@(test)
test_range_syntax :: proc(t: ^testing.T) {
    count := 0
    for i in 0..=<10 {
        count += 1
    }
    testing.expect(t, count == 11, "Range with ..= should include both ends")
}
