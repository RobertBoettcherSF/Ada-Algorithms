--  Own tests for Min_Cost_Climbing_Stairs (see tests/SOURCES.txt).
--  Compute must be the cheapest way up: start on step 1 or 2, pay each step stood on,
--  move 1 or 2 steps. Whether the climb ends past the last step or on it (paying it)
--  is not fixed by the README; one input fixes it, every other input must agree.
pragma Ada_2022;
with Ada.Text_IO;
with Min_Cost_Climbing_Stairs; use Min_Cost_Climbing_Stairs;

procedure Own_Checks is
   Failures : Natural := 0;
   Cases    : Natural := 0;

   --  Park-Miller "minimal standard" generator (x := 16807 x mod (2**31 - 1)).
   Seed : Long_Long_Integer := 20_261_008;
   function Next (Lo, Hi : Integer) return Integer is
   begin
      Seed := (Seed * 16_807) mod 2_147_483_647;
      return Integer (Long_Long_Integer (Lo)
                      + Seed mod (Long_Long_Integer (Hi) - Long_Long_Integer (Lo) + 1));
   end Next;
   pragma Warnings (Off, Next);

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

   --  Own reference: straight insertion sort.
   type IArr is array (Positive range <>) of Integer;
   procedure Ins_Sort (A : in out IArr) is
      T : Integer;
      J : Positive;
   begin
      for I in A'First + 1 .. A'Last loop
         T := A (I);
         J := I;
         while J > A'First and then A (J - 1) > T loop
            A (J) := A (J - 1);
            J := J - 1;
         end loop;
         A (J) := T;
      end loop;
   end Ins_Sort;
   pragma Warnings (Off, Ins_Sort);
   X : Cost_Array;
   Past_Top : Boolean;
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
   --  fixing input: free steps, an expensive last step
   X := [others => 0];
   X (Cost_Count) := 100;
   Past_Top := Compute (X) = 0;
   Report (Compute (X) in 0 | 100, "convention input gives 0 (past the top) or 100 (on the last step)");
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
