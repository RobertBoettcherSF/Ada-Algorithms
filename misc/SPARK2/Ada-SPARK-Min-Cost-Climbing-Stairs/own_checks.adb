--  Own tests for Min_Cost_Climbing_Stairs (see tests/SOURCES.txt).
--  Compute must be the cheapest way up: start on step 1 or 2, pay each step stood on,
--  move 1 or 2 steps; the top is past the last step (the standard problem statement).
pragma Ada_2022;
with Ada.Environment_Variables;
with Ada.Text_IO;
with Min_Cost_Climbing_Stairs; use Min_Cost_Climbing_Stairs;

procedure Own_Checks is
   Failures : Natural := 0;
   Cases    : Natural := 0;

   --  Park-Miller "minimal standard" generator (x := 16807 x mod (2**31 - 1)).
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
   Seed : Long_Long_Integer := AA_Seed (20_261_008);
   function Next (Lo, Hi : Integer) return Integer is
   begin
      Seed := (Seed * 16_807) mod 2_147_483_647;
      return Integer (Long_Long_Integer (Lo)
                      + Seed mod (Long_Long_Integer (Hi) - Long_Long_Integer (Lo) + 1));
   end Next;

   procedure Report (Ok : Boolean; Label : String) is
   begin
      Cases := Cases + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 5 then
            Ada.Text_IO.Put_Line ("  FAIL own check: " & Label);
         end if;
      end if;
   end Report;

   X : Cost_Array;
   Past_Top : constant Boolean := True;   --  the climb ends past the last step
   Never : constant Natural := 1_000_000;                --  "no such path"
   function Ref (From : Positive) return Natural is   --  cheapest from standing on step From
   begin
      if From > Cost_Count then
         return (if Past_Top then 0 else Never);         --  past the top: done, or overshoot
      end if;
      if From = Cost_Count and then not Past_Top then
         return X (From);                                --  the climb ends on the last step
      end if;
      return X (From) + Natural'Min (Ref (From + 1), Ref (From + 2));
   end Ref;
   function Best return Natural is (Natural'Min (Ref (1), Ref (2)));
begin
   --  free steps and an expensive last step: jump from step 5 past the top
   X := [others => 0];
   X (Cost_Count) := 100;
   Report (Compute (X) = 0, "0 0 0 0 0 100 -> 0");
   for Code in 0 .. 3 ** Cost_Count - 1 loop
      declare
         C : Natural := Code;
      begin
         for I in Index loop
            X (I) := C mod 3;
            C := C / 3;
         end loop;
      end;
      Report (Compute (X) = Best, "small");
   end loop;
   for Iter in 1 .. 5_000 loop
      for I in Index loop
         X (I) := Next (0, 100);
      end loop;
      Report (Compute (X) = Best, "random" & Iter'Image);
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own path-enumeration reference)");
end Own_Checks;
