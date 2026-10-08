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
with Ada.Environment_Variables;
with Ada.Text_IO; use Ada.Text_IO;
with Darwin_Godel_Machine; use Darwin_Godel_Machine;

procedure Own_Checks is
   --  Random test inputs: fixed default seed, printed at start; AA_SEED=<n> overrides it.
   function AA_Seed (Default : Long_Long_Integer) return Long_Long_Integer is
      V : constant String := Ada.Environment_Variables.Value ("AA_SEED", "");
      S : Long_Long_Integer := Default;
   begin
      if V /= "" then
         S := Long_Long_Integer (1 + abs (Long_Long_Integer'Value (V)) mod 2_147_483_646);
      end if;
      Ada.Text_IO.Put_Line ("AA_SEED =" & Long_Long_Integer'Image (S) & (if V = "" then " (default)" else " (from AA_SEED)"));
      return S;
   end AA_Seed;
   Seed : Long_Long_Integer := AA_Seed (20261008);
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
   --  Boundaries of the stated rules (values computed by hand from the
   --  rules, see tests/SOURCES.txt): fitness must rise strictly; Verify_Strict
   --  allows a complexity increase of at most 50; in Dynamic_Env each unit of
   --  complexity above 100 costs 0.1 fitness.
   declare
      At_101 : constant Agent_State := Create_Agent (1, 10.0, 101);
      At_100 : constant Agent_State := Create_Agent (2, 10.0, 100);
   begin
      if abs (Float (Evaluate (At_101, Dynamic_Env)) - 9.9) > 1.0E-4 then
         Fail ("Evaluate: fitness 10, complexity 101, dynamic should be 9.9, got" & Evaluate (At_101, Dynamic_Env)'Image);
      end if;
      if Evaluate (At_100, Dynamic_Env) /= 10.0 then
         Fail ("Evaluate: complexity 100 carries no penalty, got" & Evaluate (At_100, Dynamic_Env)'Image);
      end if;
   end;
   declare
      Base : constant Agent_State := Create_Agent (1, 10.0, 0);
      C50  : constant Agent_State := Create_Agent (2, 20.0, 50);
      C51  : constant Agent_State := Create_Agent (3, 20.0, 51);
   begin
      if not Verify_Strict (Base, C50, Static_Env) then
         Fail ("Verify_Strict must accept a complexity increase of exactly 50");
      end if;
      if Verify_Strict (Base, C51, Static_Env) then
         Fail ("Verify_Strict must reject a complexity increase of 51");
      end if;
   end;
   declare
      Base : constant Agent_State := Create_Agent (1, 10.0, 0);
      Same : constant Agent_State := Create_Agent (2, 10.0, 0);
   begin
      if Verify_Heuristic (Base, Same, Static_Env) then
         Fail ("Verify_Heuristic must reject an equal evaluation (fitness must rise)");
      end if;
   end;
   Put_Line ("own checks: selection rule checked on" & Rounds'Image & " random populations (demo folder)");
   if Failures > 0 then
      raise Program_Error with "own checks:" & Failures'Image & " failures";
   end if;
end Own_Checks;
