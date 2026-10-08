--  Own tests for Missing_Number (see tests/SOURCES.txt).
--  For five distinct values from 0 .. 5 (README), Find must return the one that is absent.
pragma Ada_2022;
with Ada.Text_IO;
with Missing_Number; use Missing_Number;

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
   Perm : array (1 .. 6) of Natural;
   procedure Try (K : Positive; Miss : Natural) is
   begin
      if K > Length then
         for I in Index loop X (I) := Perm (I); end loop;
         Report (Find (X) = Miss, "permutation");
         return;
      end if;
      for V in 0 .. 5 loop
         if V /= Miss and then (for all J in 1 .. K - 1 => Perm (J) /= V) then
            Perm (K) := V;
            Try (K + 1, Miss);
         end if;
      end loop;
   end Try;
begin
   for Miss in 0 .. 5 loop
      Try (1, Miss);
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (all orders of every 5-of-6 choice, exhaustive)");
end Own_Checks;
