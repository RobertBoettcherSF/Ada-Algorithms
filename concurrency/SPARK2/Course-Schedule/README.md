# Course-Schedule

Bounded SPARK version of the course schedule question: 4 courses and 4 prerequisite pairs `(Course_Number, Required)`, where `Required` has to be taken before `Course_Number`. All the courses can be taken exactly when the prerequisite graph has no cycle (a course that requires itself counts as a cycle).

`Schedule` runs Kahn's algorithm. Each step takes a course whose prerequisites have all been taken and gives it the next rank. The result comes with a witness that the proof checks:

* `Ok`: `Rank` orders the courses so that every prerequisite has a smaller rank than the course that needs it (`Is_Order`), and `Stuck` is empty.
* not `Ok`: `Stuck` is a nonempty set of courses where each course needs another course of the set (`Is_Stuck`), so no course of the set can be taken first.

`Lemma_Exclusive` proves that both witnesses cannot exist for the same prerequisites. So `Ok`, and with it `Can_Finish`, is fixed by the input. A ghost count of the courses taken shows that 4 steps take every course.

`make test` builds and runs the tests (`tests.adb`, plus the exhaustive own checks in `own_checks.adb`). `make prove` runs the level-2 CVC5 proof (68 checks).

The first version of `Can_Finish` returned `Prerequisites (1).Required = 1` and never looked at the graph; see `tools/vv/findings_sweep.csv`.
