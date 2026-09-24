--  Strand_Sort body — extract nondecreasing strands, merge into output.

pragma Ada_2022;

package body Strand_Sort
  with SPARK_Mode => Off
is

   procedure Check_Bounds (A : Element_Array) is
   begin
      if A'Length > Max_N then
         raise Invalid_Argument
           with "array length exceeds Max_N";
      end if;
   end Check_Bounds;

   procedure Sort (A : in out Element_Array) is
      N : constant Natural := A'Length;
   begin
      Check_Bounds (A);

      if N <= 1 then
         return;
      end if;

      declare
         --  Remap to dense 1 .. N work space for simple strand extraction.
         Input      : Element_Array (1 .. N);
         Input_Len  : Natural := N;
         Output     : Element_Array (1 .. N) := [others => 0];
         Output_Len : Natural := 0;
         Strand     : Element_Array (1 .. N) := [others => 0];
         Strand_Len : Natural;
         Src        : Natural := A'First;
      begin
         for I in 1 .. N loop
            Input (I) := A (Src);
            Src := Src + 1;
         end loop;

         while Input_Len > 0 loop
            --  Extract one nondecreasing strand from Input(1 .. Input_Len).
            --  First remaining element always starts the strand.
            declare
               Remaining     : Element_Array (1 .. Input_Len);
               Remaining_Len : Natural := 0;
               Last_Taken    : Integer := Input (1);
            begin
               Strand_Len := 1;
               Strand (1) := Input (1);

               for I in 2 .. Input_Len loop
                  if Input (I) >= Last_Taken then
                     Strand_Len := Strand_Len + 1;
                     Strand (Strand_Len) := Input (I);
                     Last_Taken := Input (I);
                  else
                     Remaining_Len := Remaining_Len + 1;
                     Remaining (Remaining_Len) := Input (I);
                  end if;
               end loop;

               for I in 1 .. Remaining_Len loop
                  Input (I) := Remaining (I);
               end loop;
               Input_Len := Remaining_Len;
            end;

            --  Merge Strand(1 .. Strand_Len) into Output(1 .. Output_Len).
            declare
               Merged : Element_Array (1 .. Output_Len + Strand_Len);
               I      : Natural := 1;
               J      : Natural := 1;
               K      : Natural := 1;
            begin
               while I <= Output_Len and then J <= Strand_Len loop
                  if Output (I) <= Strand (J) then
                     Merged (K) := Output (I);
                     I := I + 1;
                  else
                     Merged (K) := Strand (J);
                     J := J + 1;
                  end if;
                  K := K + 1;
               end loop;

               while I <= Output_Len loop
                  Merged (K) := Output (I);
                  I := I + 1;
                  K := K + 1;
               end loop;

               while J <= Strand_Len loop
                  Merged (K) := Strand (J);
                  J := J + 1;
                  K := K + 1;
               end loop;

               Output_Len := Output_Len + Strand_Len;
               for X in 1 .. Output_Len loop
                  Output (X) := Merged (X);
               end loop;
            end;
         end loop;

         Src := A'First;
         for I in 1 .. N loop
            A (Src) := Output (I);
            Src := Src + 1;
         end loop;
      end;
   end Sort;

   function Is_Sorted (A : Element_Array) return Boolean is
   begin
      if A'Length <= 1 then
         return True;
      end if;
      for I in A'First + 1 .. A'Last loop
         if A (I - 1) > A (I) then
            return False;
         end if;
      end loop;
      return True;
   end Is_Sorted;

end Strand_Sort;
