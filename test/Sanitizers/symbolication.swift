// RUN: %target-build-swift %s -sanitize=address    -target %sanitizers-target-triple -o %t
// RUN: %target-build-swift %s -sanitize=address -g -target %sanitizers-target-triple -o %t.debug
// RUN: env %env-ASAN_OPTIONS=abort_on_error=0                           not %target-run %t       2>&1 | %FileCheck %s -check-prefix=OOP
// RUN: env %env-ASAN_OPTIONS=abort_on_error=0                           not %target-run %t.debug 2>&1 | %FileCheck %s -check-prefix=OOP-DEBUG
// RUN: env %env-ASAN_OPTIONS=abort_on_error=0,external_symbolizer_path= not %target-run %t       2>&1 | %FileCheck %s -check-prefix=IP
// RUN: env %env-ASAN_OPTIONS=abort_on_error=0,external_symbolizer_path= not %target-run %t.debug 2>&1 | %FileCheck %s -check-prefix=IP
// REQUIRES: executable_test
// REQUIRES: asan_runtime

// Check that Sanitizer reports are properly symbolicated, both out-of-process
// via atos (or llvm-symbolizer) and when falling back to in-process
// symbolication.

func foo() {
  let x = UnsafeMutablePointer<Int>.allocate(capacity: 1)
  x.deallocate()
  print(x.pointee)
}

func bar() {
  foo()
}

bar()


// Out-of-process with debug info
// OOP-DEBUG:      #0 0x{{[0-9a-f]+}} in foo() symbolication.swift:[[@LINE-11]]
// OOP-DEBUG-NEXT: #1 0x{{[0-9a-f]+}} in bar() symbolication.swift:[[@LINE-8]]
// OOP-DEBUG-NEXT: #2 0x{{[0-9a-f]+}} in main symbolication.swift:[[@LINE-6]]

// Out-of-process without debug info
// OOP:      #0 0x{{[0-9a-f]+}} in foo()+0x{{[0-9a-f]+}} (symbolication.swift.tmp:
// OOP-NEXT: #1 0x{{[0-9a-f]+}} in bar()+0x{{[0-9a-f]+}} (symbolication.swift.tmp:
// OOP-NEXT: #2 0x{{[0-9a-f]+}} in main+0x{{[0-9a-f]+}} (symbolication.swift.tmp:

// In-process
// IP:      #0 0x{{[0-9a-f]+}} in main.foo() -> ()+0x{{[0-9a-f]+}} {{.*}}symbolication.swift.tmp
// IP-NEXT: #1 0x{{[0-9a-f]+}} in main.bar() -> ()+0x{{[0-9a-f]+}} {{.*}}symbolication.swift.tmp
// IP-NEXT: #2 0x{{[0-9a-f]+}} in main+0x{{[0-9a-f]+}} {{.*}}symbolication.swift.tmp
