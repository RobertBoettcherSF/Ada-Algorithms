--  Own tests for Knapsack_01 (see tests/SOURCES.txt).
--  Maximum_Value must be the best total value of a subset within the weight limit, over all subsets.
pragma Ada_2022;
with Ada.Text_IO;
with Knapsack_01; use Knapsack_01;

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
   W : Weight_Array;
   V : Value_Array;
   function Ref (Limit : Natural) return Natural is
      Best : Natural := 0;
      SW, SV : Natural;
   begin
      for Mask in 0 .. 2 ** Item_Count - 1 loop
         SW := 0; SV := 0;
         for I in Item_Index loop
            if (Mask / 2 ** (I - 1)) mod 2 = 1 then
               SW := SW + W (I); SV := SV + V (I);
            end if;
         end loop;
         if SW <= Limit then Best := Natural'Max (Best, SV); end if;
      end loop;
      return Best;
   end Ref;
begin
   for Iter in 1 .. 5_000 loop
      for I in Item_Index loop
         W (I) := Next (1, (if Iter mod 2 = 0 then 4 else Capacity));
         V (I) := Next (0, 100);
      end loop;
      for L in Capacity_Index loop
         Report (Maximum_Value (W, V, L) = Ref (L), "random" & Iter'Image);
      end loop;
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own subset-enumeration reference)");
end Own_Checks;
