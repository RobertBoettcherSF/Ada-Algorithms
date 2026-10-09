pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Find_Peak_Element; use Find_Peak_Element;

procedure Tests is
   --  -3 1 4 2 9 5 0 -1, then down by 1: peaks at 3 and 5.
   A : constant Input_Array :=
     [for I in Index => (case I is
                           when 1 => -3, when 2 => 1, when 3 => 4, when 4 => 2,
                           when 5 => 9, when 6 => 5, when 7 => 0, when 8 => -1,
                           when others => 7 - I)];
   --  Zigzag 0 1 0 1 ...: every even index is a peak.
   Zig  : constant Input_Array := [for I in Index => I mod 2];
   --  Strictly rising: the only peak is the last element.
   Up   : constant Input_Array := [for I in Index => I];
   --  Strictly falling: the only peak is the first element.
   Down : constant Input_Array := [for I in Index => -I];

   --  A peak among N = 32 values needs at most ceil (log2 32) = 5
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

   procedure Expect (X : Input_Array; Label : String; Only : Natural := 0) is
      R : constant Search_Result := Find_Peak (X);
   begin
      if not Is_Peak (X, R.Position) then
         raise Program_Error with Label & ":" & R.Position'Image & " is not a peak";
      end if;
      if Only /= 0 and then R.Position /= Only then
         raise Program_Error with Label & ": peak" & R.Position'Image & ", the only peak is" & Only'Image;
      end if;
      if R.Probes > Bound then
         raise Program_Error with Label & ":" & R.Probes'Image
           & " comparisons, more than floor (log2 N) + 2 =" & Bound'Image;
      end if;
   end Expect;
begin
   Expect (A, "-3 1 4 2 9 5 0 -1 ...");
   Expect (Zig, "zigzag");
   Expect (Up, "rising", Only => Length);
   Expect (Down, "falling", Only => 1);
   for P in Index loop
      Expect ([for I in Index => -abs (I - P)], "single peak at" & P'Image, Only => P);
   end loop;
   Put_Line ("Find_Peak_Element: PASS");
end Tests;
