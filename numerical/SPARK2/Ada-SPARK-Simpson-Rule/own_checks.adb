--  Own tests for Simpson_Rule (see tests/SOURCES.txt).
--  Integrate (Steps) = composite Simpson rule for x**2 on [0, Steps] with unit
--  step, truncated to an integer.
pragma Ada_2022;
with Ada.Text_IO;
with Simpson_Rule; use Simpson_Rule;

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

   function Ref (N : Positive) return Integer is
      S : Integer := 0;
      W : Integer;
   begin
      for I in 0 .. N loop
         W := (if I = 0 or else I = N then 1 elsif I mod 2 = 1 then 4 else 2);
         S := S + W * I * I;
      end loop;
      return S / 3;      --  h / 3 with h = 1
   end Ref;
begin
   for N in Even_Steps loop
      if N mod 2 = 0 then
         Report (Integrate (N) = Ref (N), "Steps =" & N'Image);
      end if;
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own Simpson weighted sum, exhaustive)");
end Own_Checks;
