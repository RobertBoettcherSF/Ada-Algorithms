pragma SPARK_Mode (Off);
with Ada.Text_IO; use Ada.Text_IO;
with Max_Product_Subarray; use Max_Product_Subarray;

procedure Tests is
   A : constant Element_Array := [2, 3, -2, 4, -1, 2];
   B : constant Element_Array := [-2, 0, -1, 4, 3, -2];

   --  own reference: the largest product over every non-empty contiguous subarray, in
   --  Long_Long_Integer so that no product is capped
   function Reference (V : Element_Array) return Long_Long_Integer is
      Best : Long_Long_Integer := Long_Long_Integer'First;
   begin
      for I in Index loop
         declare
            P : Long_Long_Integer := 1;
         begin
            for J in I .. Index'Last loop
               P := P * Long_Long_Integer (V (J));
               if P > Best then Best := P; end if;
            end loop;
         end;
      end loop;
      return Best;
   end Reference;

   --  an element whose products could leave Result must be rejected by the element type,
   --  not turned into a capped product (10 ** 6 is not 100_000)
   procedure Check_Rejected (X : Integer) is
      V : Element_Array;
   begin
      for I in Index loop
         V (I) := Element (X);
      end loop;
      Put_Line ("FAIL: element" & Integer'Image (X) & " accepted, Compute =" & Integer'Image (Compute (V))
                & ", true maximum =" & Long_Long_Integer'Image (Reference (V)));
      raise Program_Error;
   exception
      when Constraint_Error => null;
   end Check_Rejected;

   Lo : constant := -6;
   Hi : constant := 6;
   Digits_Of : array (Index) of Integer := [others => Lo];
   V : Element_Array;
   Checked : Natural := 0;
   Done : Boolean := False;
begin
   if Compute (A) /= 96 or else Compute (B) /= 24 then raise Program_Error; end if;
   --  exhaustive: every array over -6 .. 6 (13 ** 6 = 4_826_809 arrays) against the reference
   while not Done loop
      for I in Index loop
         V (I) := Element (Digits_Of (I));
      end loop;
      if Long_Long_Integer (Compute (V)) /= Reference (V) then
         Put_Line ("FAIL at array starting" & Integer'Image (V (1)));
         raise Program_Error;
      end if;
      Checked := Checked + 1;
      Done := True;
      for I in Index loop
         if Digits_Of (I) < Hi then
            Digits_Of (I) := Digits_Of (I) + 1; Done := False; exit;
         else
            Digits_Of (I) := Lo;
         end if;
      end loop;
   end loop;
   Check_Rejected (10);
   Check_Rejected (-10);
   Check_Rejected (7);
   Put_Line ("Max product subarray: PASS (" & Natural'Image (Checked) & " arrays)");
end Tests;
