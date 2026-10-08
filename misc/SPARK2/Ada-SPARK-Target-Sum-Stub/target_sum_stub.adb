pragma Ada_2022;
package body Target_Sum_Stub with SPARK_Mode => On is
   function Exists (A : Values; Goal : Target) return Boolean is
   begin
      -- Exhaustive bounded search over the 2**5 sign assignments.
      return
        A (1) + A (2) + A (3) + A (4) + A (5) = Goal
        or A (1) + A (2) + A (3) + A (4) - A (5) = Goal
        or A (1) + A (2) + A (3) - A (4) + A (5) = Goal
        or A (1) + A (2) + A (3) - A (4) - A (5) = Goal
        or A (1) + A (2) - A (3) + A (4) + A (5) = Goal
        or A (1) + A (2) - A (3) + A (4) - A (5) = Goal
        or A (1) + A (2) - A (3) - A (4) + A (5) = Goal
        or A (1) + A (2) - A (3) - A (4) - A (5) = Goal
        or A (1) - A (2) + A (3) + A (4) + A (5) = Goal
        or A (1) - A (2) + A (3) + A (4) - A (5) = Goal
        or A (1) - A (2) + A (3) - A (4) + A (5) = Goal
        or A (1) - A (2) + A (3) - A (4) - A (5) = Goal
        or A (1) - A (2) - A (3) + A (4) + A (5) = Goal
        or A (1) - A (2) - A (3) + A (4) - A (5) = Goal
        or A (1) - A (2) - A (3) - A (4) + A (5) = Goal
        or A (1) - A (2) - A (3) - A (4) - A (5) = Goal
        or -A (1) + A (2) + A (3) + A (4) + A (5) = Goal
        or -A (1) + A (2) + A (3) + A (4) - A (5) = Goal
        or -A (1) + A (2) + A (3) - A (4) + A (5) = Goal
        or -A (1) + A (2) + A (3) - A (4) - A (5) = Goal
        or -A (1) + A (2) - A (3) + A (4) + A (5) = Goal
        or -A (1) + A (2) - A (3) + A (4) - A (5) = Goal
        or -A (1) + A (2) - A (3) - A (4) + A (5) = Goal
        or -A (1) + A (2) - A (3) - A (4) - A (5) = Goal
        or -A (1) - A (2) + A (3) + A (4) + A (5) = Goal
        or -A (1) - A (2) + A (3) + A (4) - A (5) = Goal
        or -A (1) - A (2) + A (3) - A (4) + A (5) = Goal
        or -A (1) - A (2) + A (3) - A (4) - A (5) = Goal
        or -A (1) - A (2) - A (3) + A (4) + A (5) = Goal
        or -A (1) - A (2) - A (3) + A (4) - A (5) = Goal
        or -A (1) - A (2) - A (3) - A (4) + A (5) = Goal
        or -A (1) - A (2) - A (3) - A (4) - A (5) = Goal;
   end Exists;
end Target_Sum_Stub;
