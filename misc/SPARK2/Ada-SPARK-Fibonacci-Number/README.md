# Ada-SPARK-Fibonacci-Number

Bounded iterative Fibonacci computation for n <= 32, with SPARK contracts and level-2 proof setup.

`Compute (N)` returns F (N) with F (0) = 0, F (1) = 1, F (k) = F (k - 1) + F (k - 2). Its postcondition states the result against the ghost function `Fib`, and the body proves that `Fib` satisfies the defining recurrence (`Is_Fibonacci`), so the contract is the Fibonacci sequence itself. The loop needs no saturating addition: F (k) <= F (32) = 2,178,309, so every sum fits `Result`, and `make prove` (level 2, CVC5) proves the absence of overflow and the postcondition (11 checks).
