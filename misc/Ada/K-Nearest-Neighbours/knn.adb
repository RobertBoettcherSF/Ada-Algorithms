with Ada.Numerics.Generic_Elementary_Functions;
with Ada.Containers.Generic_Array_Sort;

package body Knn is

   package Math is new Ada.Numerics.Generic_Elementary_Functions (Feature_Value);
   use Math;

   -- Epsilon prevents division by zero in distance weighting when points overlap perfectly
   Epsilon : constant Distance_Value := 1.0e-9;

   type Neighbor_Record is record
      Distance : Distance_Value;
      Index    : Sample_Index;
   end record;

   type Neighbor_Array is array (Sample_Index range <>) of Neighbor_Record;

   function "<" (Left, Right : Neighbor_Record) return Boolean is
   begin
      return Left.Distance < Right.Distance;
   end "<";

   procedure Sort_Neighbors is new Ada.Containers.Generic_Array_Sort
     (Index_Type   => Sample_Index,
      Element_Type => Neighbor_Record,
      Array_Type   => Neighbor_Array);

   -- Calculates N-dimensional Euclidean distance between a specific row in the matrix and a query point
   function Euclidean_Distance (Row : Feature_Matrix;
                                Row_Idx : Sample_Index;
                                Query : Query_Vector) return Distance_Value is
      Sum : Feature_Value := 0.0;
      Diff : Feature_Value;
      Query_Idx : Feature_Index := Query'First;
   begin
      for J in Row'Range(2) loop
         Diff := Row (Row_Idx, J) - Query (Query_Idx);
         Sum := Sum + (Diff * Diff);
         if Query_Idx < Query'Last then
            Query_Idx := Query_Idx + 1;
         end if;
      end loop;
      return Distance_Value (Sqrt (Sum));
   end Euclidean_Distance;

   -- Computes distances to all points in the dataset and sorts them to find the closest neighbors
   function Get_Sorted_Neighbors (Train_X : Feature_Matrix; Query : Query_Vector) return Neighbor_Array is
      Neighbors : Neighbor_Array (Train_X'Range(1));
   begin
      for I in Train_X'Range(1) loop
         Neighbors (I) := (Distance => Euclidean_Distance (Train_X, I, Query),
                           Index    => I);
      end loop;
      Sort_Neighbors (Neighbors);
      return Neighbors;
   end Get_Sorted_Neighbors;

   -- Structure and sort routine for tracking label frequencies/weights during classification voting
   type Label_Weight is record
      Label  : Class_Label;
      Weight : Distance_Value;
   end record;

   type Label_Weight_Array is array (Positive range <>) of Label_Weight;

   function "<" (Left, Right : Label_Weight) return Boolean is
   begin
      return Left.Label < Right.Label;
   end "<";

   procedure Sort_Labels is new Ada.Containers.Generic_Array_Sort
     (Index_Type   => Positive,
      Element_Type => Label_Weight,
      Array_Type   => Label_Weight_Array);

   -- Accumulates sorted label weights to deduce the most dominant label in the top K
   function Tally_Votes (Votes : in out Label_Weight_Array) return Class_Label is
      Current_Label  : Class_Label;
      Current_Weight : Distance_Value := 0.0;
      Best_Label     : Class_Label := Votes(Votes'First).Label;
      Max_Weight     : Distance_Value := -1.0;
   begin
      Sort_Labels (Votes);

      Current_Label := Votes(Votes'First).Label;
      for I in Votes'Range loop
         if Votes(I).Label = Current_Label then
            Current_Weight := Current_Weight + Votes(I).Weight;
         else
            if Current_Weight > Max_Weight then
               Max_Weight := Current_Weight;
               Best_Label := Current_Label;
            end if;
            Current_Label := Votes(I).Label;
            Current_Weight := Votes(I).Weight;
         end if;
      end loop;

      -- Check final accumulated label
      if Current_Weight > Max_Weight then
         Best_Label := Current_Label;
      end if;

      return Best_Label;
   end Tally_Votes;


   -- 1. Classification (Majority Vote)
   function Predict_Classification
     (Train_X : Feature_Matrix;
      Train_Y : Label_Vector;
      Query   : Query_Vector;
      K       : K_Value) return Class_Label
   is
   begin
      if Train_X'Length(1) = 0 then raise Empty_Dataset_Error; end if;
      if Train_X'Length(1) /= Train_Y'Length then raise Length_Mismatch_Error; end if;
      if Train_X'Length(2) /= Query'Length then raise Dimension_Mismatch_Error; end if;
      if Natural(K) > Train_X'Length(1) then raise Invalid_K_Error; end if;

      declare
         Neighbors : constant Neighbor_Array := Get_Sorted_Neighbors (Train_X, Query);
         Votes     : Label_Weight_Array (1 .. Positive (K));
         Y_Offset  : constant Integer := Integer(Train_Y'First) - Integer(Train_X'First(1));
         N_Idx     : Sample_Index;
      begin
         for I in 1 .. Positive(K) loop
            N_Idx := Sample_Index (Integer (Neighbors'First) + I - 1);
            Votes(I) := (Label  => Train_Y(Sample_Index(Integer(Neighbors(N_Idx).Index) + Y_Offset)),
                         Weight => 1.0);
         end loop;

         return Tally_Votes (Votes);
      end;
   end Predict_Classification;


   -- 2. Regression (Uniform Average)
   function Predict_Regression
     (Train_X : Feature_Matrix;
      Train_Y : Target_Vector;
      Query   : Query_Vector;
      K       : K_Value) return Feature_Value
   is
   begin
      if Train_X'Length(1) = 0 then raise Empty_Dataset_Error; end if;
      if Train_X'Length(1) /= Train_Y'Length then raise Length_Mismatch_Error; end if;
      if Train_X'Length(2) /= Query'Length then raise Dimension_Mismatch_Error; end if;
      if Natural(K) > Train_X'Length(1) then raise Invalid_K_Error; end if;

      declare
         Neighbors : constant Neighbor_Array := Get_Sorted_Neighbors (Train_X, Query);
         Sum       : Feature_Value := 0.0;
         Y_Offset  : constant Integer := Integer(Train_Y'First) - Integer(Train_X'First(1));
         N_Idx     : Sample_Index;
      begin
         for I in 1 .. Positive(K) loop
            N_Idx := Sample_Index (Integer (Neighbors'First) + I - 1);
            Sum := Sum + Train_Y(Sample_Index(Integer(Neighbors(N_Idx).Index) + Y_Offset));
         end loop;

         return Sum / Feature_Value (K);
      end;
   end Predict_Regression;


   -- 3. Distance-Weighted Classification
   function Predict_Weighted_Classification
     (Train_X : Feature_Matrix;
      Train_Y : Label_Vector;
      Query   : Query_Vector;
      K       : K_Value) return Class_Label
   is
   begin
      if Train_X'Length(1) = 0 then raise Empty_Dataset_Error; end if;
      if Train_X'Length(1) /= Train_Y'Length then raise Length_Mismatch_Error; end if;
      if Train_X'Length(2) /= Query'Length then raise Dimension_Mismatch_Error; end if;
      if Natural(K) > Train_X'Length(1) then raise Invalid_K_Error; end if;

      declare
         Neighbors : constant Neighbor_Array := Get_Sorted_Neighbors (Train_X, Query);
         Votes     : Label_Weight_Array (1 .. Positive (K));
         Y_Offset  : constant Integer := Integer(Train_Y'First) - Integer(Train_X'First(1));
         N_Idx     : Sample_Index;
         Dist      : Distance_Value;
         W         : Distance_Value;
      begin
         for I in 1 .. Positive(K) loop
            N_Idx := Sample_Index (Integer (Neighbors'First) + I - 1);
            Dist  := Neighbors(N_Idx).Distance;
            W     := 1.0 / (Dist + Epsilon);
            Votes(I) := (Label  => Train_Y(Sample_Index(Integer(Neighbors(N_Idx).Index) + Y_Offset)),
                         Weight => W);
         end loop;

         return Tally_Votes (Votes);
      end;
   end Predict_Weighted_Classification;


   -- 4. Distance-Weighted Regression
   function Predict_Weighted_Regression
     (Train_X : Feature_Matrix;
      Train_Y : Target_Vector;
      Query   : Query_Vector;
      K       : K_Value) return Feature_Value
   is
   begin
      if Train_X'Length(1) = 0 then raise Empty_Dataset_Error; end if;
      if Train_X'Length(1) /= Train_Y'Length then raise Length_Mismatch_Error; end if;
      if Train_X'Length(2) /= Query'Length then raise Dimension_Mismatch_Error; end if;
      if Natural(K) > Train_X'Length(1) then raise Invalid_K_Error; end if;

      declare
         Neighbors : constant Neighbor_Array := Get_Sorted_Neighbors (Train_X, Query);
         Sum       : Feature_Value := 0.0;
         Weight_Sum: Distance_Value := 0.0;
         Y_Offset  : constant Integer := Integer(Train_Y'First) - Integer(Train_X'First(1));
         N_Idx     : Sample_Index;
         Dist      : Distance_Value;
         W         : Distance_Value;
         Val       : Feature_Value;
      begin
         for I in 1 .. Positive(K) loop
            N_Idx := Sample_Index (Integer (Neighbors'First) + I - 1);
            Dist  := Neighbors(N_Idx).Distance;
            W     := 1.0 / (Dist + Epsilon);
            Val   := Train_Y(Sample_Index(Integer(Neighbors(N_Idx).Index) + Y_Offset));

            Sum        := Sum + Val * Feature_Value (W);
            Weight_Sum := Weight_Sum + W;
         end loop;

         return Sum / Feature_Value (Weight_Sum);
      end;
   end Predict_Weighted_Regression;

end Knn;
