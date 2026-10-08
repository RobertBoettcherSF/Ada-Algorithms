--  Own tests for Third_Maximum_Number (see tests/SOURCES.txt).
--  For arrays with at least three distinct values, Third_Maximum must be the third largest distinct value.
pragma Ada_2022;
with Ada.Text_IO;
with Third_Maximum_Number; use Third_Maximum_Number;

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
   X : Int_Array;
   function Ref return Integer is
      Seen : Natural := 0;
   begin
      for V in reverse Value loop
         if (for some I in Index => X (I) = V) then
            Seen := Seen + 1;
            if Seen = 3 then return V; end if;
         end if;
      end loop;
      return Integer'First;
   end Ref;
begin
   for Iter in 1 .. 6_000 loop
      declare
         Hi : constant Integer := (if Iter mod 2 = 0 then -30 else 32);
      begin
         for I in Index loop
            X (I) := Next (-32, Hi);
         end loop;
         if Ref /= Integer'First then
            Report (Third_Maximum (X) = Ref, "random" & Iter'Image);
         end if;
      end;
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own distinct-value scan)");
end Own_Checks;
