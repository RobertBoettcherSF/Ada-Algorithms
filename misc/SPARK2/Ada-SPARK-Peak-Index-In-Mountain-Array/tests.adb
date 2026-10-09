pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Peak_Index_In_Mountain_Array; use Peak_Index_In_Mountain_Array;

procedure Tests is
   --  1, 3, 7, 12, 10, 6, 2, 0, then down by 1 to -24: peak at 4.
   A : constant Mountain_Array :=
     [for I in Index => (case I is
                           when 1 => 1, when 2 => 3, when 3 => 7, when 4 => 12,
                           when 5 => 10, when 6 => 6, when 7 => 2, when 8 => 0,
                           when others => 8 - I)];

   --  Up by 1 to P, then down by 3.
   function Skewed (P : Index) return Mountain_Array is
     [for I in Index => (if I <= P then I else P - 3 * (I - P))];

   --  A peak among N = 32 values needs at most ceil (log2 31) = 5
   --  comparisons of neighbours; the bound asserted here is
   --  floor (log2 N) + 2 = 7.
   function Floor_Log2 (N : Positive) return Natural is
      K : Natural := 0;
      M : Positive := N;
   begin
      while M > 1 loop
         M := M / 2;
         K := K + 1;
      end loop;
      return K;
   end Floor_Log2;

   Bound : constant Natural := Floor_Log2 (Length) + 2;

   procedure Expect (M : Mountain_Array; Where : Index; Label : String) is
      R : constant Search_Result := Peak_Index (M);
   begin
      if R.Position /= Where then
         raise Program_Error with Label & ": peak" & R.Position'Image & ", expected" & Where'Image;
      end if;
      if R.Probes > Bound then
         raise Program_Error with Label & ":" & R.Probes'Image
           & " comparisons, more than floor (log2 N) + 2 =" & Bound'Image;
      end if;
   end Expect;
begin
   Expect (A, 4, "1 3 7 12 10 6 2 0 ...");
   for P in 2 .. Length - 1 loop
      Expect (Skewed (P), P, "skewed peak at" & P'Image);
   end loop;
   Put_Line ("Peak_Index_In_Mountain_Array: PASS");
end Tests;
