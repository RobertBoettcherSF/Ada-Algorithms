--  Own tests for Move_Zeroes (see tests/SOURCES.txt).
--  Move must keep the non-zero values in order at the front and put the zeros at the end.
pragma Ada_2022;
with Ada.Text_IO;
with Move_Zeroes; use Move_Zeroes;

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
   X, Y, R : Input_Array;
begin
   --  every array over {0, 1, 2}, then random ones with many zeros
   for Iter in 1 .. 3 ** Length + 4_000 loop
      if Iter <= 3 ** Length then
         declare
            C : Natural := Iter - 1;
         begin
            for I in Index loop
               X (I) := C mod 3;
               C := C / 3;
            end loop;
         end;
      else
         for I in Index loop
            X (I) := (if Next (0, 1) = 0 then 0 else Next (0, 20));
         end loop;
      end if;
      --  own reference: stable compaction
      R := [others => 0];
      declare
         K : Natural := 0;
      begin
         for I in Index loop
            if X (I) /= 0 then K := K + 1; R (K) := X (I); end if;
         end loop;
      end;
      Y := Move (X);
      Report (Y = R, "input" & Iter'Image);
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own stable-compaction reference)");
end Own_Checks;
