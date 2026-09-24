-- vector_quantization.adb
-- Implementation of Vector Quantization algorithms

package body Vector_Quantization is

   ----------------------
   -- Distance_Squared --
   ----------------------
   function Distance_Squared (V1, V2 : Vector) return Float is
      Sum : Float := 0.0;
   begin
      if V1'Length /= V2'Length then
         raise Dimension_Mismatch;
      end if;
      
      for I in 0 .. V1'Length - 1 loop
         Sum := Sum + (V1(V1'First + I) - V2(V2'First + I)) ** 2;
      end loop;
      
      return Sum;
   end Distance_Squared;

   ------------
   -- Encode --
   ------------
   function Encode (Target : Vector; Book : Matrix) return Positive is
      Min_Dist : Float := Float'Last;
      Min_Idx  : Positive := Book'First(1);
      Dist     : Float;
      Dim      : constant Positive := Book'Length(2);
   begin
      if Target'Length /= Dim then
         raise Dimension_Mismatch;
      end if;

      for I in Book'Range(1) loop
         declare
            C : Vector(1 .. Dim);
         begin
            for J in 1 .. Dim loop
               C(J) := Book(I, Book'First(2) + J - 1);
            end loop;
            
            Dist := Distance_Squared (Target, C);
            if Dist < Min_Dist then
               Min_Dist := Dist;
               Min_Idx  := I;
            end if;
         end;
      end loop;
      return Min_Idx;
   end Encode;

   ------------
   -- Decode --
   ------------
   function Decode (Index : Positive; Book : Matrix) return Vector is
      Dim : constant Positive := Book'Length(2);
      Res : Vector(1 .. Dim);
   begin
      if Index < Book'First(1) or Index > Book'Last(1) then
         raise Constraint_Error;
      end if;
      
      for J in 1 .. Dim loop
         Res(J) := Book(Index, Book'First(2) + J - 1);
      end loop;
      return Res;
   end Decode;

   -------------------
   -- Calculate_MSE --
   -------------------
   function Calculate_MSE (Data : Matrix; Book : Matrix) return Float is
      Total_Sq_Error : Float := 0.0;
      Dim : constant Positive := Data'Length(2);
   begin
      if Data'Length(1) = 0 then
         return 0.0;
      end if;
      
      for I in Data'Range(1) loop
         declare
            Target : Vector(1 .. Dim);
            C_Idx  : Positive;
            C      : Vector(1 .. Dim);
         begin
            for J in 1 .. Dim loop
               Target(J) := Data(I, Data'First(2) + J - 1);
            end loop;
            
            C_Idx := Encode (Target, Book);
            C := Decode (C_Idx, Book);
            Total_Sq_Error := Total_Sq_Error + Distance_Squared (Target, C);
         end;
      end loop;
      
      return Total_Sq_Error / Float(Data'Length(1));
   end Calculate_MSE;

   ---------------
   -- Train_LBG --
   ---------------
   function Train_LBG
     (Data          : Matrix;
      Codebook_Size : Positive;
      Epsilon       : Float := 0.001;
      Max_Iter      : Positive := 100) return Matrix
   is
      Dim      : constant Positive := Data'Length(2);
      Num_Data : constant Natural  := Data'Length(1);
      
      Book        : Matrix(1 .. Codebook_Size, 1 .. Dim);
      Assignments : array (Data'Range(1)) of Positive;
      Counts      : array (1 .. Codebook_Size) of Natural;
      
      Prev_MSE : Float := Float'Last;
      Curr_MSE : Float;
      Iter     : Positive := 1;
   begin
      if Num_Data = 0 then
         raise Empty_Dataset;
      end if;
      
      if Codebook_Size > Num_Data then
         raise Invalid_Codebook;
      end if;

      -- 1. Initialization: Sub-sample data to create initial codebook
      for I in 1 .. Codebook_Size loop
         declare
            Src_Idx : Positive := Data'First(1) + ((I - 1) * Num_Data / Codebook_Size);
         begin
            for J in 1 .. Dim loop
               Book(I, J) := Data(Src_Idx, Data'First(2) + J - 1);
            end loop;
         end;
      end loop;

      -- 2. Iteration (Lloyd's Algorithm)
      loop
         -- Assign vectors to nearest centroids
         for I in Data'Range(1) loop
            declare
               Target : Vector(1 .. Dim);
            begin
               for J in 1 .. Dim loop
                  Target(J) := Data(I, Data'First(2) + J - 1);
               end loop;
               Assignments(I) := Encode(Target, Book);
            end;
         end loop;

         -- Reset accumulators
         for I in 1 .. Codebook_Size loop
            Counts(I) := 0;
            for J in 1 .. Dim loop
               Book(I, J) := 0.0;
            end loop;
         end loop;

         -- Sum assigned vectors
         for I in Data'Range(1) loop
            declare
               Cluster : constant Positive := Assignments(I);
            begin
               Counts(Cluster) := Counts(Cluster) + 1;
               for J in 1 .. Dim loop
                  Book(Cluster, J) := Book(Cluster, J) + Data(I, Data'First(2) + J - 1);
               end loop;
            end;
         end loop;

         -- Update centroids (Average)
         for I in 1 .. Codebook_Size loop
            if Counts(I) > 0 then
               for J in 1 .. Dim loop
                  Book(I, J) := Book(I, J) / Float(Counts(I));
               end loop;
            else
               -- Edge Case: Empty Cluster. Re-initialize to a data point to prevent dead centroids.
               for J in 1 .. Dim loop
                  Book(I, J) := Data(Data'First(1), Data'First(2) + J - 1);
               end loop;
            end if;
         end loop;

         -- 3. Check for convergence
         Curr_MSE := Calculate_MSE(Data, Book);
         exit when Iter >= Max_Iter or else abs(Prev_MSE - Curr_MSE) <= Epsilon;
         Prev_MSE := Curr_MSE;
         Iter := Iter + 1;
      end loop;

      return Book;
   end Train_LBG;

end Vector_Quantization;
