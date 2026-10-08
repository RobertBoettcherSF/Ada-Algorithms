--  Own checks (see tests/SOURCES.txt). This folder is a demo: agents are
--  numeric records (fitness, complexity) chosen from a list the caller
--  supplies; there is no code, no self-modification and no proof. The one
--  claim that can be checked is the selection rule. Random populations:
--  * Evolve_Exhaustive returns Base or a candidate that passes
--    Verify_Strict, and no passing candidate evaluates higher (brute-force
--    maximum over the list); a returned candidate is marked Strict_Proof;
--  * Evolve_Preemptive returns the first candidate (in list order) that
--    passes Verify_Heuristic and reaches Evaluate (Base) + Threshold, or
--    Base when none does (thresholds keep the target below the maximum).
pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Darwin_Godel_Machine; use Darwin_Godel_Machine;

procedure Own_Checks is
   Seed : Long_Long_Integer := 20261008;
   Failures, Rounds : Natural := 0;

   function Rand (Lo, Hi : Integer) return Integer is   --  Park-Miller
   begin
      Seed := (Seed * 16807) mod 2147483647;
      return Lo + Integer (Seed mod Long_Long_Integer (Hi - Lo + 1));
   end Rand;

   procedure Fail (What : String) is
   begin
      Put_Line ("FAIL own check: " & What);
      Failures := Failures + 1;
   end Fail;

   function Random_Agent (Id : Positive) return Agent_State is
     (Create_Agent (Id, Fitness_Value (Rand (0, 400)) / 4.0, Complexity_Value (Rand (0, 300))));
begin
   for Round in 1 .. 2000 loop
      declare
         Env  : constant Environment_State := (if Round mod 2 = 0 then Static_Env else Dynamic_Env);
         Base : constant Agent_State := Random_Agent (1);
         Pop  : Agent_Array (1 .. Rand (1, 6));
         Thr  : constant Fitness_Value := Fitness_Value (Rand (1, 200)) / 4.0;
      begin
         for I in Pop'Range loop
            Pop (I) := Random_Agent (I + 1);
         end loop;
         Rounds := Rounds + 1;
         declare
            R : constant Agent_State := Evolve_Exhaustive (Base, Pop, Env);
            Best : Fitness_Value := Evaluate (Base, Env);
         begin
            for C of Pop loop
               if Verify_Strict (Base, C, Env) and then Evaluate (C, Env) > Best then
                  Best := Evaluate (C, Env);
               end if;
            end loop;
            if R.Id = Base.Id then
               if Best > Evaluate (Base, Env) then
                  Fail ("Evolve_Exhaustive kept Base although a verified candidate is better");
               end if;
            elsif not (for some C of Pop => C.Id = R.Id and then Verify_Strict (Base, C, Env)) then
               Fail ("Evolve_Exhaustive accepted a candidate that fails Verify_Strict");
            elsif Evaluate (R, Env) /= Best or else R.Level /= Strict_Proof then
               Fail ("Evolve_Exhaustive did not return the best verified candidate");
            end if;
         end;
         declare
            R : constant Agent_State := Evolve_Preemptive (Base, Pop, Env, Thr);
            Want : Natural := 0;
         begin
            for I in Pop'Range loop
               if Verify_Heuristic (Base, Pop (I), Env)
                 and then Float (Evaluate (Pop (I), Env)) >= Float (Evaluate (Base, Env)) + Float (Thr)
               then
                  Want := Pop (I).Id;
                  exit;
               end if;
            end loop;
            if (Want = 0 and then R.Id /= Base.Id) or else (Want /= 0 and then (R.Id /= Want or else R.Level /= Heuristic)) then
               Fail ("Evolve_Preemptive returned agent" & R.Id'Image & ", first qualifying is" & Want'Image);
            end if;
         end;
      end;
   end loop;
   --  near the top of the fitness range: a gain smaller than the threshold
   --  must not be accepted (Base 9_990 + threshold 50 is unreachable)
   declare
      Base : constant Agent_State := Create_Agent (1, 9_990.0, 10);
      Top  : constant Agent_State := Create_Agent (2, 10_000.0, 10);
      R    : constant Agent_State := Evolve_Preemptive (Base, [1 => Top], Static_Env, 50.0);
   begin
      if R.Id /= Base.Id then
         Fail ("Evolve_Preemptive accepted a gain of 10 for threshold 50 at the top of the range");
      end if;
   end;
   Put_Line ("own checks: selection rule checked on" & Rounds'Image & " random populations (demo folder)");
   if Failures > 0 then
      raise Program_Error with "own checks:" & Failures'Image & " failures";
   end if;
end Own_Checks;
