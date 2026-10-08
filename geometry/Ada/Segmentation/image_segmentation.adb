--  ===================================================================
--  Package Body: Image_Segmentation
--  Implementation of classical image processing segmentation variants.
--  ===================================================================

package body Image_Segmentation is

   ------------------------------------------------------------------
   -- Helpers
   ------------------------------------------------------------------
   function Get_Height (Img : Image_Grid) return Natural is
   begin
      return Img'Length (1);
   end Get_Height;

   function Get_Width (Img : Image_Grid) return Natural is
   begin
      return Img'Length (2);
   end Get_Width;

   procedure Validate_Matching_Dimensions (Img1, Img2 : Image_Grid) is
   begin
      if Img1'First (1) /= Img2'First (1) or else
         Img1'Last (1) /= Img2'Last (1) or else
         Img1'First (2) /= Img2'First (2) or else
         Img1'Last (2) /= Img2'Last (2) then
         raise Invalid_Image_Dimensions with "Grid dimensions do not match.";
      end if;
   end Validate_Matching_Dimensions;

   ------------------------------------------------------------------
   -- 1. Thresholding Variants
   ------------------------------------------------------------------
   procedure Global_Threshold
     (Input     : Image_Grid;
      Output    : out Image_Grid;
      Threshold : Pixel_Intensity) is
   begin
      Validate_Matching_Dimensions (Input, Output);

      for R in Input'Range (1) loop
         for C in Input'Range (2) loop
            if Input (R, C) >= Threshold then
               Output (R, C) := 255;
            else
               Output (R, C) := 0;
            end if;
         end loop;
      end loop;
   end Global_Threshold;

   procedure Otsu_Threshold
     (Input             : Image_Grid;
      Output            : out Image_Grid;
      Optimal_Threshold : out Pixel_Intensity) is

      type Histogram_Array is array (Pixel_Intensity) of Natural;
      Hist         : Histogram_Array := (others => 0);
      Total_Pixels : constant Float :=
        Float (Input'Length (1) * Input'Length (2));

      Sum_Total : Float := 0.0;
      Sum_B     : Float := 0.0;
      Weight_B  : Float := 0.0;
      Weight_F  : Float := 0.0;

      Max_Var : Float             := -1.0;
      Best_T  : Pixel_Intensity := 0;
   begin
      Validate_Matching_Dimensions (Input, Output);

      if Total_Pixels = 0.0 then
         raise Invalid_Image_Dimensions with "Empty image provided.";
      end if;

      for R in Input'Range (1) loop
         for C in Input'Range (2) loop
            Hist (Input (R, C)) := Hist (Input (R, C)) + 1;
         end loop;
      end loop;

      for I in Pixel_Intensity loop
         Sum_Total := Sum_Total + Float (I) * Float (Hist (I));
      end loop;

      for T in Pixel_Intensity loop
         Weight_B := Weight_B + Float (Hist (T));
         if Weight_B > 0.0 then
            Weight_F := Total_Pixels - Weight_B;
            if Weight_F = 0.0 then
               exit;
            end if;

            Sum_B := Sum_B + Float (T) * Float (Hist (T));

            declare
               Mean_B      : constant Float := Sum_B / Weight_B;
               Mean_F      : constant Float :=
                 (Sum_Total - Sum_B) / Weight_F;
               Diff        : constant Float := Mean_B - Mean_F;
               Between_Var : constant Float :=
                 Weight_B * Weight_F * (Diff * Diff);
            begin
               if Between_Var >= Max_Var then
                  Max_Var := Between_Var;
                  Best_T  := T;
               end if;
            end;
         end if;
      end loop;

      Optimal_Threshold := Best_T;
      Global_Threshold (Input, Output, Optimal_Threshold);
   end Otsu_Threshold;

   ------------------------------------------------------------------
   -- 2. K-Means Segmentation
   ------------------------------------------------------------------
   procedure KMeans_Segmentation
     (Input         : Image_Grid;
      Labels        : out Label_Grid;
      K             : Positive;
      Max_Iter      : Positive := 100;
      Centroids_Out : out Cluster_Array) is

      type Centroid_Array is array (1 .. K) of Float;
      Centroids : Centroid_Array;
      Sums      : array (1 .. K) of Long_Integer := (others => 0);
      Counts    : array (1 .. K) of Natural      := (others => 0);
      Changed   : Boolean := False;
   begin
      if K > Centroids_Out'Length then
         raise Invalid_Cluster_Count with "Centroids output array too small.";
      end if;

      for I in 1 .. K loop
         Centroids (I) := Float (I - 1) * (255.0 / Float (K));
      end loop;

      for Iter in 1 .. Max_Iter loop
         Changed := False;
         Sums    := (others => 0);
         Counts  := (others => 0);

         for R in Input'Range (1) loop
            for C in Input'Range (2) loop
               declare
                  Val      : constant Float := Float (Input (R, C));
                  Min_Dist : Float          := 999999.0;
                  Best_K   : Pixel_Label    := 1;
               begin
                  for K_Idx in 1 .. K loop
                     declare
                        Dist : constant Float :=
                          Abs (Val - Centroids (K_Idx));
                     begin
                        if Dist < Min_Dist then
                           Min_Dist := Dist;
                           Best_K   := Pixel_Label (K_Idx);
                        end if;
                     end;
                  end loop;

                  if Labels (R, C) /= Best_K then
                     Labels (R, C) := Best_K;
                     Changed       := True;
                  end if;

                  Sums (Natural (Best_K)) :=
                    Sums (Natural (Best_K)) + Long_Integer (Input (R, C));
                  Counts (Natural (Best_K)) :=
                    Counts (Natural (Best_K)) + 1;
               end;
            end loop;
         end loop;

         for K_Idx in 1 .. K loop
            if Counts (K_Idx) > 0 then
               Centroids (K_Idx) :=
                 Float (Sums (K_Idx)) / Float (Counts (K_Idx));
            end if;
         end loop;

         exit when not Changed;
      end loop;

      for I in 1 .. K loop
         Centroids_Out (Centroids_Out'First + I - 1) :=
           Pixel_Intensity (Natural (Centroids (I)));
      end loop;
   end KMeans_Segmentation;

   ------------------------------------------------------------------
   -- 3. Region Growing
   ------------------------------------------------------------------
   procedure Region_Growing
     (Input        : Image_Grid;
      Labels       : out Label_Grid;
      Seeds        : Position_Vectors.Vector;
      Tolerance    : Pixel_Intensity;
      Connectivity : Connectivity_Mode := Four_Connected) is

      Queue         : Position_Vectors.Vector;
      Current_Label : Pixel_Label := 1;

      Dx_4 : constant array (1 .. 4) of Integer := (-1, 1, 0, 0);
      Dy_4 : constant array (1 .. 4) of Integer := (0, 0, -1, 1);

      Dx_8 : constant array (1 .. 8) of Integer :=
        (-1, 1, 0, 0, -1, -1, 1, 1);
      Dy_8 : constant array (1 .. 8) of Integer :=
        (0, 0, -1, 1, -1, 1, -1, 1);

      Num_Neighbors : constant Positive :=
        (if Connectivity = Four_Connected then 4 else 8);
   begin
      for R in Labels'Range (1) loop
         for C in Labels'Range (2) loop
            Labels (R, C) := 0;
         end loop;
      end loop;

      for Seed of Seeds loop
         if Seed.Row not in Input'Range (1) or else
            Seed.Col not in Input'Range (2) then
            raise Seed_Out_Of_Bounds with "Seed position out of image grid.";
         end if;

         if Labels (Seed.Row, Seed.Col) = 0 then
            Labels (Seed.Row, Seed.Col) := Current_Label;
            Queue.Clear;
            Queue.Append (Seed);

            declare
               Seed_Val : constant Pixel_Intensity :=
                 Input (Seed.Row, Seed.Col);
            begin
               while not Queue.Is_Empty loop
                  declare
                     P : constant Pixel_Position := Queue.First_Element;
                  begin
                     Queue.Delete_First;

                     for N in 1 .. Num_Neighbors loop
                        declare
                           NR : constant Integer :=
                             Integer (P.Row) +
                             (if Connectivity = Four_Connected then Dx_4 (N)
                              else Dx_8 (N));
                           NC : constant Integer :=
                             Integer (P.Col) +
                             (if Connectivity = Four_Connected then Dy_4 (N)
                              else Dy_8 (N));
                        begin
                           if NR in Integer (Input'First (1)) ..
                                    Integer (Input'Last (1)) and then
                              NC in Integer (Input'First (2)) ..
                                    Integer (Input'Last (2)) then
                              declare
                                 R_Dim : constant Dimension := Dimension (NR);
                                 C_Dim : constant Dimension := Dimension (NC);
                              begin
                                 if Labels (R_Dim, C_Dim) = 0 then
                                    declare
                                       Val_Diff : constant Integer :=
                                         Abs (Integer (Input (R_Dim, C_Dim)) -
                                              Integer (Seed_Val));
                                    begin
                                       if Val_Diff <= Integer (Tolerance) then
                                          Labels (R_Dim, C_Dim) :=
                                            Current_Label;
                                          Queue.Append
                                            ((Row => R_Dim, Col => C_Dim));
                                       end if;
                                    end;
                                 end if;
                              end;
                           end if;
                        end;
                     end loop;
                  end;
               end loop;
            end;
            Current_Label := Current_Label + 1;
         end if;
      end loop;
   end Region_Growing;

   ------------------------------------------------------------------
   -- 4. Edge-Based Segmentation
   ------------------------------------------------------------------
   procedure Edge_Based_Segmentation
     (Input     : Image_Grid;
      Output    : out Image_Grid;
      Op        : Gradient_Operator := Sobel;
      Threshold : Pixel_Intensity   := 50) is

      Gx, Gy : Integer;
      Mag    : Integer;

      type Kernel_Matrix is array (-1 .. 1, -1 .. 1) of Integer;

      Sobel_X : constant Kernel_Matrix :=
        ((-1, 0, 1), (-2, 0, 2), (-1, 0, 1));
      Sobel_Y : constant Kernel_Matrix :=
        ((-1, -2, -1), (0, 0, 0), (1, 2, 1));

      Prewitt_X : constant Kernel_Matrix :=
        ((-1, 0, 1), (-1, 0, 1), (-1, 0, 1));
      Prewitt_Y : constant Kernel_Matrix :=
        ((-1, -1, -1), (0, 0, 0), (1, 1, 1));

      K_X : constant Kernel_Matrix :=
        (if Op = Sobel then Sobel_X else Prewitt_X);
      K_Y : constant Kernel_Matrix :=
        (if Op = Sobel then Sobel_Y else Prewitt_Y);
   begin
      Validate_Matching_Dimensions (Input, Output);

      for R in Output'Range (1) loop
         for C in Output'Range (2) loop
            Output (R, C) := 0;
         end loop;
      end loop;

      for R in Input'First (1) + 1 .. Input'Last (1) - 1 loop
         for C in Input'First (2) + 1 .. Input'Last (2) - 1 loop
            Gx := 0;
            Gy := 0;

            for DR in -1 .. 1 loop
               for DC in -1 .. 1 loop
                  declare
                     Row_Idx : constant Dimension :=
                       Dimension (Integer (R) + DR);
                     Col_Idx : constant Dimension :=
                       Dimension (Integer (C) + DC);
                     Val     : constant Integer :=
                       Integer (Input (Row_Idx, Col_Idx));
                  begin
                     Gx := Gx + Val * K_X (DR, DC);
                     Gy := Gy + Val * K_Y (DR, DC);
                  end;
               end loop;
            end loop;

            Mag := Abs (Gx) + Abs (Gy);
            if Mag >= Integer (Threshold) * 4 then
               Output (R, C) := 255;
            else
               Output (R, C) := 0;
            end if;
         end loop;
      end loop;
   end Edge_Based_Segmentation;

   ------------------------------------------------------------------
   -- 5. Watershed Segmentation
   ------------------------------------------------------------------
   procedure Watershed_Segmentation
     (Input  : Image_Grid;
      Labels : out Label_Grid) is

      Current_Label : Pixel_Label := 1;
   begin
      for R in Labels'Range (1) loop
         for C in Labels'Range (2) loop
            Labels (R, C) := 0;
         end loop;
      end loop;

      for Intensity in Pixel_Intensity loop
         for R in Input'Range (1) loop
            for C in Input'Range (2) loop
               if Input (R, C) <= Intensity and then Labels (R, C) = 0 then
                  Labels (R, C) := Current_Label;
                  Current_Label := Current_Label + 1;
               end if;
            end loop;
         end loop;
      end loop;
   end Watershed_Segmentation;

end Image_Segmentation;
