--  Own tests for Number_Of_1_Bits (see tests/SOURCES.txt).
--  Count_Ones must equal the own bit count.
pragma Ada_2022;
with Ada.Text_IO;
with Number_Of_1_Bits; use Number_Of_1_Bits;

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
   function Ref (V : Natural) return Natural is
      C : Natural := 0;
      X : Natural := V;
   begin
      while X > 0 loop
         C := C + X mod 2;
         X := X / 2;
      end loop;
      return C;
   end Ref;
begin
   for V in 0 .. 2 ** 16 loop
      Report (Count_Ones (V) = Ref (V), "small");
   end loop;
   for Iter in 1 .. 20_000 loop
      declare
         V : constant Input := Next (0, Input'Last);
      begin
         Report (Count_Ones (V) = Ref (V), "random");
      end;
   end loop;
   for K in 0 .. 29 loop   --  powers of two and all-ones values up to Input'Last
      Report (Count_Ones (2 ** K) = 1, "power of two");
      if K <= 28 then
         Report (Count_Ones (2 ** (K + 1) - 1) = K + 1, "all ones");
      end if;
   end loop;
   Report (Count_Ones (Input'Last) = Ref (Input'Last), "last");
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own bit-count reference)");
end Own_Checks;
