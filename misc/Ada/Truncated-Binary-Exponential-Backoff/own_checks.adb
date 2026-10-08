--  Own checks (see tests/SOURCES.txt). Assume the backoff package is wrong or
--  does nothing; compare it with the definitions computed differently:
--  deterministic delays by repeated addition (Base**C * Slot as a sum),
--  randomized delays by their support and coverage (every multiple of the
--  slot time in 0 .. (2**C - 1) * Slot is drawn, nothing else), expected
--  delays as the exact mean of that uniform support, truncation as
--  min (C, Ceiling), and the state machine step by step.
pragma Ada_2022;
with Ada.Text_IO;
with Truncated_Binary_Exponential_Backoff; use Truncated_Binary_Exponential_Backoff;

procedure Own_Checks is
   Checked : Natural := 0;

   procedure Expect (Cond : Boolean; What : String) is
   begin
      if not Cond then
         Ada.Text_IO.Put_Line ("FAIL own check: " & What);
         raise Program_Error;
      end if;
      Checked := Checked + 1;
   end Expect;

   --  Base**C * Slot by repeated addition
   function Ref_Det (Base, C, Slot : Natural) return Long_Long_Integer is
      V : Long_Long_Integer := Long_Long_Integer (Slot);
   begin
      for I in 1 .. C loop
         declare
            Sum : Long_Long_Integer := 0;
         begin
            for J in 1 .. Base loop Sum := Sum + V; end loop;
            V := Sum;
         end;
      end loop;
      return V;
   end Ref_Det;

   function Rejects (Cfg : Backoff_Config) return Boolean is
   begin
      return Deterministic_Delay (Cfg, 1) < 0;   --  never: must raise
   exception
      when Invalid_Config => return True;
   end Rejects;
begin
   for Base in 2 .. 5 loop
      for Slot in 1 .. 7 loop
         for Ceil in 0 .. 6 loop
            declare
               Cfg : constant Backoff_Config := (Base_Type (Base), Ceiling_Type (Ceil), Slot_Time_Type (Slot));
            begin
               for C in 0 .. 8 loop
                  Expect (Long_Long_Integer (Deterministic_Delay (Cfg, Collision_Count_Type (C))) = Ref_Det (Base, C, Slot),
                          "Deterministic_Delay base" & Base'Image & " C" & C'Image & " slot" & Slot'Image);
                  Expect (Long_Long_Integer (Truncated_Deterministic_Delay (Cfg, Collision_Count_Type (C)))
                            = Ref_Det (Base, Natural'Min (C, Ceil), Slot),
                          "Truncated_Deterministic_Delay C" & C'Image & " ceiling" & Ceil'Image);
                  --  mean of the uniform support {0, Slot, ..., (2**C - 1) * Slot}, truncated
                  Expect (Natural (Expected_Delay (Cfg, Collision_Count_Type (C))) = (2 ** C - 1) * Slot / 2,
                          "Expected_Delay C" & C'Image & " slot" & Slot'Image);
                  Expect (Natural (Truncated_Expected_Delay (Cfg, Collision_Count_Type (C)))
                            = (2 ** Natural'Min (C, Ceil) - 1) * Slot / 2,
                          "Truncated_Expected_Delay C" & C'Image & " ceiling" & Ceil'Image);
               end loop;
            end;
         end loop;
      end loop;
   end loop;
   --  randomized: support and coverage over 4,000 draws for C in 0 .. 5
   for C in 0 .. 5 loop
      for Ceil in 0 .. 6 loop
         declare
            Slot : constant := 3;
            Cfg  : constant Backoff_Config := (2, Ceiling_Type (Ceil), Slot);
            Eff  : constant Natural := Natural'Min (C, Ceil);
            Seen_R, Seen_T : array (0 .. 31) of Boolean := [others => False];
         begin
            for Draw in 1 .. 4_000 loop
               declare
                  R : constant Natural := Natural (Randomized_Delay (Cfg, Collision_Count_Type (C)));
                  T : constant Natural := Natural (Truncated_Randomized_Delay (Cfg, Collision_Count_Type (C)));
               begin
                  Expect (R mod Slot = 0 and then R / Slot <= 2 ** C - 1, "Randomized_Delay support C" & C'Image);
                  Expect (T mod Slot = 0 and then T / Slot <= 2 ** Eff - 1, "Truncated_Randomized_Delay support C"
                          & C'Image & " ceiling" & Ceil'Image);
                  Seen_R (R / Slot) := True;
                  Seen_T (T / Slot) := True;
               end;
            end loop;
            for K in 0 .. 2 ** C - 1 loop
               Expect (Seen_R (K), "Randomized_Delay never drew" & K'Image & " slots for C" & C'Image);
            end loop;
            for K in 0 .. 2 ** Eff - 1 loop
               Expect (Seen_T (K), "Truncated_Randomized_Delay never drew" & K'Image & " slots");
            end loop;
         end;
      end loop;
   end loop;
   --  state machine
   declare
      S   : Backoff_State := (Collision_Count => 7, Current_Delay => 99);
      Cfg : constant Backoff_Config := (2, 3, 5);
   begin
      Initialize_State (S);
      Expect (S = (0, 0), "Initialize_State");
      for Step in 1 .. 6 loop
         Increment_Collision (S, Cfg, Use_Random => False);
         Expect (S.Collision_Count = Collision_Count_Type (Step)
                 and then Natural (S.Current_Delay) = 5 * 2 ** Natural'Min (Step, 3),
                 "Increment_Collision (deterministic) step" & Step'Image);
      end loop;
      for Step in 7 .. 9 loop
         Increment_Collision (S, Cfg);
         Expect (S.Collision_Count = Collision_Count_Type (Step) and then S.Current_Delay mod 5 = 0
                 and then Natural (S.Current_Delay) <= 5 * 7, "Increment_Collision (random) step" & Step'Image);
      end loop;
      Reset_State (S);
      Expect (S = (0, 0), "Reset_State");
   end;
   --  helpers and validation
   for C in 0 .. 20 loop
      Expect (Power_Of_Two (Collision_Count_Type (C)) = Natural (Ref_Det (2, C, 1)), "Power_Of_Two" & C'Image);
      for Ceil in 0 .. 20 loop
         Expect (Natural (Clamp_Collision_Count (Collision_Count_Type (C), Ceiling_Type (Ceil))) = Natural'Min (C, Ceil),
                 "Clamp_Collision_Count");
      end loop;
   end loop;
   Expect (Rejects ((2, 10, 0)), "Slot_Time 0 accepted");
   Ada.Text_IO.Put_Line ("PASS own checks:" & Checked'Image
                         & " checks (repeated-addition powers, uniform support and coverage, state steps)");
end Own_Checks;
