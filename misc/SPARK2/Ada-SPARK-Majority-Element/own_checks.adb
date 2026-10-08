--  Own tests for Majority_Element (see tests/SOURCES.txt).
--  For inputs with a strict majority value (README), Find must return that value.
pragma Ada_2022;
with Ada.Text_IO;
with Majority_Element; use Majority_Element;

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
   X : Input_Array;
   M : Value;
begin
   for Iter in 1 .. 6_000 loop
      M := Next (Value'First, Value'Last);
      --  4 .. 7 copies of M at random places, the rest random other values
      declare
         K : constant Natural := Next (4, Length);
         Put : Natural := 0;
         P : Index;
      begin
         for I in Index loop
            loop
               X (I) := Next (Value'First, Value'Last);
               exit when X (I) /= M;
            end loop;
         end loop;
         while Put < K loop
            P := Next (1, Length);
            if X (P) /= M then X (P) := M; Put := Put + 1; end if;
         end loop;
      end;
      Report (Find (X) = M, "random" & Iter'Image);
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (planted strict majority)");
end Own_Checks;
