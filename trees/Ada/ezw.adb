-- ezw.adb
-- Implementation body for the EZW Algorithm

package body EZW is

   function Compute_Initial_Threshold (Matrix : Wavelet_Matrix) return Threshold_Value is
      Max_Val   : Threshold_Value := 0;
      Threshold : Threshold_Value := 1;
   begin
      if Matrix'Length = 0 then
         raise Empty_Matrix_Error;
      end if;

      -- Find maximum absolute value
      for I in Matrix'Range loop
         if abs(Matrix(I)) > Wavelet_Value(Max_Val) then
            Max_Val := Threshold_Value(abs(Matrix(I)));
         end if;
      end loop;

      if Max_Val = 0 then
         return 0;
      end if;

      -- Calculate highest power of 2 <= Max_Val
      while (Threshold * 2) <= Max_Val loop
         Threshold := Threshold * 2;
      end loop;

      return Threshold;
   end Compute_Initial_Threshold;


   function Is_Zerotree_Root
     (Matrix    : Wavelet_Matrix;
      Index     : Positive;
      Threshold : Threshold_Value) return Boolean
   is
      -- 1D Quadtree representation mapping
      Child_1 : constant Positive := 4 * Index - 2;
      Child_2 : constant Positive := 4 * Index - 1;
      Child_3 : constant Positive := 4 * Index;
      Child_4 : constant Positive := 4 * Index + 1;
   begin
      -- Node itself must be less than threshold
      if Index <= Matrix'Last and then abs(Matrix(Index)) >= Wavelet_Value(Threshold) then
         return False;
      end if;

      -- All descendants must be less than threshold (recursive check)
      if Child_1 <= Matrix'Last and then not Is_Zerotree_Root(Matrix, Child_1, Threshold) then return False; end if;
      if Child_2 <= Matrix'Last and then not Is_Zerotree_Root(Matrix, Child_2, Threshold) then return False; end if;
      if Child_3 <= Matrix'Last and then not Is_Zerotree_Root(Matrix, Child_3, Threshold) then return False; end if;
      if Child_4 <= Matrix'Last and then not Is_Zerotree_Root(Matrix, Child_4, Threshold) then return False; end if;

      return True;
   end Is_Zerotree_Root;


   procedure Dominant_Pass
     (Matrix      : in out Wavelet_Matrix;
      Significant : in out Significance_Map;
      Threshold   : in     Threshold_Value;
      Stream      : in out Encoded_Stream)
   is
   begin
      if Matrix'Length = 0 then
         return;
      end if;

      for I in Matrix'Range loop
         if not Significant(I) then
            if abs(Matrix(I)) >= Wavelet_Value(Threshold) then
               -- Found a significant coefficient
               Stream.Count := Stream.Count + 1;
               if Stream.Count > Stream.Max_Size then raise Stream_Overflow_Error; end if;

               if Matrix(I) > 0 then
                  Stream.Symbols(Stream.Count) := POS;
               else
                  Stream.Symbols(Stream.Count) := NEG;
               end if;
               
               Significant(I) := True;
               -- Zero out the matrix value so it doesn't interrupt future ZTR checks
               Matrix(I) := 0;
            else
               -- Coefficient is insignificant; determine if ZTR or IZ
               Stream.Count := Stream.Count + 1;
               if Stream.Count > Stream.Max_Size then raise Stream_Overflow_Error; end if;

               if Is_Zerotree_Root(Matrix, I, Threshold) then
                  Stream.Symbols(Stream.Count) := ZTR;
               else
                  Stream.Symbols(Stream.Count) := IZ;
               end if;
            end if;
         end if;
      end loop;
   end Dominant_Pass;


   procedure Subordinate_Pass
     (Original_Matrix : in     Wavelet_Matrix;
      Significant     : in     Significance_Map;
      Threshold       : in     Threshold_Value;
      Stream          : in out Encoded_Stream)
   is
   begin
      for I in Original_Matrix'Range loop
         if Significant(I) then
            Stream.Count := Stream.Count + 1;
            if Stream.Count > Stream.Max_Size then raise Stream_Overflow_Error; end if;

            -- Extract the specific bit for refinement using integer division
            if (abs(Original_Matrix(I)) / Wavelet_Value(Threshold)) mod 2 = 1 then
               Stream.Symbols(Stream.Count) := SUB_1;
            else
               Stream.Symbols(Stream.Count) := SUB_0;
            end if;
         end if;
      end loop;
   end Subordinate_Pass;

end EZW;
