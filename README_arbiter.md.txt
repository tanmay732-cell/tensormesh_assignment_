

### 1. Both requests at the same time (both held high)

| Cycle | req_A | req_B | Version 1 grant | Version 2 grant |
|---|---|---|---|---|
| 1 | 1 | 1 | A | A |
| 2 | 1 | 1 | A | B |
| 3 | 1 | 1 | A | A |
| 4 | 1 | 1 | A | B |

Version 1 grants A in every cycle. Version 2 grants A first (after reset the
last granted is B), then alternates A, B, A, B. In both versions only one grant
is high per cycle.

### 2. Problem with always giving A priority

B can starve. While A keeps requesting, B never gets a grant, however long it
waits. Simulation with both requests held high for 20 cycles:

| Version | A grants | B grants |
|---|---|---|
| 1 (fixed priority) | 20 | 0 |
| 2 (fair) | 10 | 10 |

### 3. How Version 2 guarantees fairness

Version 2 stores who was granted last (`last_B`). When both request, it grants
the other module, so a module that just won cannot win the next tie. The two
modules therefore alternate while both are requesting.

The longest B can wait is 1 cycle: at most one A grant can come between B's
request and B's grant, so B is served by its second cycle of waiting at the
latest.

## Testbench coverage

- A alone, B alone, both together, neither.
- Both held high for 12 cycles (Version 2 must alternate).
- Both held high for 20 cycles with grant counts (see Answer 2).
- 2000 cycles of random requests and data.
- A checker on every cycle that fails if both grants are high, if `out_data`
  does not match the granted source, if `out_valid` is wrong, or if a grant
  differs from the expected one.

## Assumptions

- Version 1 does not use `clk` or `rst`. They are kept so both versions share
  the same interface.
- Reset is synchronous and active high.
