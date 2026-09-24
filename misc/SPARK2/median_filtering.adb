pragma Ada_2022;
package body Median_Filtering
  with SPARK_Mode => On
is
   subtype Window_Index is Positive range 1 .. 9;
   type Window is array (Window_Index) of Pixel;

   function Clamp_Row (R : Integer) return Row_Index
     with Global => null
   is
   begin
      if R < Integer (Row_Index'First) then
         return Row_Index'First;
      elsif R > Integer (Row_Index'Last) then
         return Row_Index'Last;
      else
         return Row_Index (R);
      end if;
   end Clamp_Row;

   function Clamp_Col (C : Integer) return Col_Index
     with Global => null
   is
   begin
      if C < Integer (Col_Index'First) then
         return Col_Index'First;
      elsif C > Integer (Col_Index'Last) then
         return Col_Index'Last;
      else
         return Col_Index (C);
      end if;
   end Clamp_Col;

   procedure Bubble_Sort (W : in out Window)
     with Global => null
   is
      Swapped : Boolean;
      Tmp     : Pixel;
   begin
      for Pass in 1 .. 8 loop
         Swapped := False;
         for I in 1 .. 9 - Pass loop
            if W (I) > W (I + 1) then
               Tmp := W (I);
               W (I) := W (I + 1);
               W (I + 1) := Tmp;
               Swapped := True;
            end if;
         end loop;
         exit when not Swapped;
      end loop;
   end Bubble_Sort;

   function Sample
     (Input : Image; R : Row_Index; C : Col_Index; DR, DC : Integer) return Pixel
     with
       Global => null,
       Pre    => DR in -1 .. 1 and then DC in -1 .. 1
   is
   begin
      return Input (Clamp_Row (Integer (R) + DR), Clamp_Col (Integer (C) + DC));
   end Sample;

   function Median_At (Input : Image; R : Row_Index; C : Col_Index) return Pixel
     with Global => null
   is
      W : Window;
   begin
      W :=
        [Sample (Input, R, C, -1, -1),
         Sample (Input, R, C, -1,  0),
         Sample (Input, R, C, -1,  1),
         Sample (Input, R, C,  0, -1),
         Sample (Input, R, C,  0,  0),
         Sample (Input, R, C,  0,  1),
         Sample (Input, R, C,  1, -1),
         Sample (Input, R, C,  1,  0),
         Sample (Input, R, C,  1,  1)];
      Bubble_Sort (W);
      return W (5);
   end Median_At;

   function Filter_3x3 (Input : Image) return Image is
      Result : Image;
   begin
      for R in Row_Index loop
         for C in Col_Index loop
            Result (R, C) := Median_At (Input, R, C);
         end loop;
      end loop;
      return Result;
   end Filter_3x3;

end Median_Filtering;
