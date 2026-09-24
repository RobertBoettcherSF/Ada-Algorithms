--  Implementation of Linde_Buzo_Gray (LBG vector quantization + Lloyd).

pragma Ada_2022;

with Ada.Numerics.Long_Elementary_Functions;

package body Linde_Buzo_Gray
  with SPARK_Mode => Off
is

   package Math renames Ada.Numerics.Long_Elementary_Functions;

   Floor_Dist : constant Real := 1.0E-30;
   --  Avoid division by zero in relative distortion change.

   -------------------------------------------------------------------------
   -- Near
   -------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   -------------------------------------------------------------------------
   -- Distance / Squared_Distance
   -------------------------------------------------------------------------

   function Squared_Distance (A, B : Point) return Non_Negative is
      Sum  : Real := 0.0;
      Diff : Real;
   begin
      if A'Length = 0 or else A'First /= B'First or else A'Last /= B'Last then
         raise Invalid_Argument with "Squared_Distance: length mismatch";
      end if;
      for I in A'Range loop
         Diff := A (I) - B (I);
         Sum := Sum + Diff * Diff;
      end loop;
      return Sum;
   end Squared_Distance;

   function Distance (A, B : Point) return Non_Negative is
      Sq : constant Non_Negative := Squared_Distance (A, B);
   begin
      if Sq = 0.0 then
         return 0.0;
      end if;
      return Non_Negative (Math.Sqrt (Long_Float (Sq)));
   end Distance;

   -------------------------------------------------------------------------
   -- Extract helpers
   -------------------------------------------------------------------------

   function Extract_Point
     (Data : Dataset; P : Point_Index) return Point
   is
      D      : constant Dim_Count := Data'Length (2);
      Result : Point (1 .. D);
      Off    : constant Integer := Data'First (2) - 1;
   begin
      if P not in Data'Range (1) or else D < 1 then
         raise Invalid_Argument with "Extract_Point: bad index/dims";
      end if;
      for J in 1 .. D loop
         Result (J) := Data (P, Dim_Index (J + Off));
      end loop;
      return Result;
   end Extract_Point;

   function Extract_Codeword
     (Book : Codebook; K : Codeword_Index) return Point
   is
      D      : constant Dim_Count := Book'Length (2);
      Result : Point (1 .. D);
      Off    : constant Integer := Book'First (2) - 1;
   begin
      if K not in Book'Range (1) or else D < 1 then
         raise Invalid_Argument with "Extract_Codeword: bad index/dims";
      end if;
      for J in 1 .. D loop
         Result (J) := Book (K, Dim_Index (J + Off));
      end loop;
      return Result;
   end Extract_Codeword;

   -------------------------------------------------------------------------
   -- Nearest_Codeword / Assign
   -------------------------------------------------------------------------

   function Nearest_Codeword
     (Query : Point; Book : Codebook) return Codeword_Index
   is
      Best       : Codeword_Index := Book'First (1);
      Best_Sq    : Real := 0.0;
      Cand_Sq    : Real;
      D          : constant Dim_Count := Book'Length (2);
      Q          : Point (1 .. D);
      Off_Q      : constant Integer := Query'First - 1;
      Cw         : Point (1 .. D);
      First_Word : Boolean := True;
   begin
      if Book'Length (1) < 1 or else D < 1 or else Query'Length /= D then
         raise Invalid_Argument with "Nearest_Codeword: empty or dim mismatch";
      end if;
      for J in 1 .. D loop
         Q (J) := Query (Dim_Index (J + Off_Q));
      end loop;
      for K in Book'Range (1) loop
         Cw := Extract_Codeword (Book, K);
         Cand_Sq := Squared_Distance (Q, Cw);
         if First_Word or else Cand_Sq < Best_Sq then
            Best_Sq := Cand_Sq;
            Best := K;
            First_Word := False;
         end if;
      end loop;
      return Best;
   end Nearest_Codeword;

   function Assign
     (Data : Dataset; Book : Codebook) return Labels
   is
      N      : constant Point_Count := Data'Length (1);
      Result : Labels (Data'Range (1));
      Pt     : Point (1 .. Data'Length (2));
   begin
      if N < 1 or else Book'Length (1) < 1
        or else Book'Length (2) /= Data'Length (2)
      then
         raise Invalid_Argument with "Assign: bad extents";
      end if;
      for P in Data'Range (1) loop
         Pt := Extract_Point (Data, P);
         Result (P) := Natural (Nearest_Codeword (Pt, Book));
      end loop;
      return Result;
   end Assign;

   -------------------------------------------------------------------------
   -- Update_Centroids / Centroid / Mean_Point
   -------------------------------------------------------------------------

   procedure Update_Centroids
     (Data  : Dataset;
      Lab   : Labels;
      Book  : in out Codebook;
      Empty : out Empty_Flags)
   is
      M_Count  : constant Codeword_Count := Book'Length (1);
      D        : constant Dim_Count := Book'Length (2);
      Counts   : array (Book'Range (1)) of Natural := [others => 0];
      Sums     : array (Book'Range (1), 1 .. D) of Real :=
                   [others => [others => 0.0]];
      Lab_K    : Codeword_Index;
      Dim_Off  : constant Integer := Data'First (2) - 1;
      Book_Off : constant Integer := Book'First (2) - 1;
   begin
      if Lab'Length /= Data'Length (1)
        or else Lab'First /= Data'First (1)
        or else Empty'Length /= M_Count
        or else Empty'First /= Book'First (1)
        or else D /= Data'Length (2)
      then
         raise Invalid_Argument with "Update_Centroids: extent mismatch";
      end if;

      for P in Data'Range (1) loop
         if Lab (P) < Natural (Book'First (1))
           or else Lab (P) > Natural (Book'Last (1))
         then
            raise Invalid_Argument with "Update_Centroids: bad label";
         end if;
         Lab_K := Codeword_Index (Lab (P));
         Counts (Lab_K) := Counts (Lab_K) + 1;
         for J in 1 .. D loop
            Sums (Lab_K, J) :=
              Sums (Lab_K, J) + Data (P, Dim_Index (J + Dim_Off));
         end loop;
      end loop;

      for K in Book'Range (1) loop
         if Counts (K) = 0 then
            Empty (K) := True;
            --  Keep previous codevector (documented empty-cell policy).
         else
            Empty (K) := False;
            for J in 1 .. D loop
               Book (K, Dim_Index (J + Book_Off)) :=
                 Sums (K, J) / Real (Counts (K));
            end loop;
         end if;
      end loop;
   end Update_Centroids;

   function Centroid
     (Data : Dataset; Lab : Labels; K : Codeword_Index) return Point
   is
      D       : constant Dim_Count := Data'Length (2);
      Result  : Point (1 .. D) := [others => 0.0];
      Count   : Natural := 0;
      Dim_Off : constant Integer := Data'First (2) - 1;
   begin
      if Lab'Length /= Data'Length (1) or else D < 1 then
         raise Invalid_Argument with "Centroid: bad extents";
      end if;
      for P in Data'Range (1) loop
         if Lab (P) = Natural (K) then
            Count := Count + 1;
            for J in 1 .. D loop
               Result (J) :=
                 Result (J) + Data (P, Dim_Index (J + Dim_Off));
            end loop;
         end if;
      end loop;
      if Count = 0 then
         raise Invalid_Argument with "Centroid: empty cell";
      end if;
      for J in 1 .. D loop
         Result (J) := Result (J) / Real (Count);
      end loop;
      return Result;
   end Centroid;

   function Mean_Point (Data : Dataset) return Point is
      D       : constant Dim_Count := Data'Length (2);
      N       : constant Point_Count := Data'Length (1);
      Result  : Point (1 .. D) := [others => 0.0];
      Dim_Off : constant Integer := Data'First (2) - 1;
   begin
      if N < 1 or else D < 1 then
         raise Invalid_Argument with "Mean_Point: empty data";
      end if;
      for P in Data'Range (1) loop
         for J in 1 .. D loop
            Result (J) :=
              Result (J) + Data (P, Dim_Index (J + Dim_Off));
         end loop;
      end loop;
      for J in 1 .. D loop
         Result (J) := Result (J) / Real (N);
      end loop;
      return Result;
   end Mean_Point;

   -------------------------------------------------------------------------
   -- Distortion / Average_Distortion
   -------------------------------------------------------------------------

   function Distortion
     (Data : Dataset; Book : Codebook; Lab : Labels) return Non_Negative
   is
      Sum : Real := 0.0;
      Pt  : Point (1 .. Data'Length (2));
      Cw  : Point (1 .. Book'Length (2));
      K   : Codeword_Index;
   begin
      if Lab'Length /= Data'Length (1)
        or else Book'Length (2) /= Data'Length (2)
        or else Book'Length (1) < 1
      then
         raise Invalid_Argument with "Distortion: bad extents";
      end if;
      for P in Data'Range (1) loop
         if Lab (P) < Natural (Book'First (1))
           or else Lab (P) > Natural (Book'Last (1))
         then
            raise Invalid_Argument with "Distortion: bad label";
         end if;
         K := Codeword_Index (Lab (P));
         Pt := Extract_Point (Data, P);
         Cw := Extract_Codeword (Book, K);
         Sum := Sum + Squared_Distance (Pt, Cw);
      end loop;
      return Sum;
   end Distortion;

   function Average_Distortion
     (Data : Dataset; Book : Codebook; Lab : Labels) return Non_Negative
   is
      N : constant Point_Count := Data'Length (1);
      Tot : constant Non_Negative := Distortion (Data, Book, Lab);
   begin
      if N < 1 then
         raise Invalid_Argument with "Average_Distortion: empty data";
      end if;
      return Tot / Real (N);
   end Average_Distortion;

   -------------------------------------------------------------------------
   -- Split_Codebook
   -------------------------------------------------------------------------

   function Split_Codebook
     (Book : Codebook; Epsilon : Positive_Real) return Codebook
   is
      Old_M    : constant Codeword_Count := Book'Length (1);
      D        : constant Dim_Count := Book'Length (2);
      Result   : Codebook (1 .. 2 * Old_M, 1 .. D);
      Book_Off : constant Integer := Book'First (2) - 1;
      Out_Idx  : Codeword_Index := 1;
      Y        : Real;
   begin
      if Old_M < 1 or else D < 1 or else Epsilon <= 0.0 then
         raise Invalid_Argument with "Split_Codebook: bad args";
      end if;
      if 2 * Old_M > Max_Codewords then
         raise Capacity_Exceeded with "Split_Codebook: exceeds Max_Codewords";
      end if;
      for K in Book'Range (1) loop
         --  Insert original y.
         for J in 1 .. D loop
            Y := Book (K, Dim_Index (J + Book_Off));
            Result (Out_Idx, J) := Y;
         end loop;
         Out_Idx := Out_Idx + 1;
         --  Insert y + ε·e_1 (perturb first coordinate only).
         --  Full-vector (ε,…,ε) only splits along the diagonal and fails
         --  to separate axis-aligned blobs; Wikipedia's ε is a small vector.
         for J in 1 .. D loop
            Y := Book (K, Dim_Index (J + Book_Off));
            if J = 1 then
               Result (Out_Idx, J) := Y + Epsilon;
            else
               Result (Out_Idx, J) := Y;
            end if;
         end loop;
         if K /= Book'Last (1) then
            Out_Idx := Out_Idx + 1;
         end if;
      end loop;
      return Result;
   end Split_Codebook;

   -------------------------------------------------------------------------
   -- Run_Lloyd
   -------------------------------------------------------------------------

   function Run_Lloyd
     (Data   : Dataset;
      Init   : Codebook;
      Params : Parameters := Default_Parameters) return LBG_Result
   is
      N        : constant Point_Count := Data'Length (1);
      M        : constant Codeword_Count := Init'Length (1);
      D        : constant Dim_Count := Data'Length (2);
      Result   : LBG_Result (N => N, M => M, D => D);
      Book     : Codebook (1 .. M, 1 .. D);
      Lab      : Labels (1 .. N);
      Empty    : Empty_Flags (1 .. M);
      Prev_D   : Real;
      Curr_D   : Real;
      Rel      : Real;
      Init_Off : constant Integer := Init'First (2) - 1;
      Init_Row : constant Integer := Init'First (1) - 1;
   begin
      if N < 1 or else M < 1 or else D < 1
        or else Init'Length (2) /= D
      then
         raise Invalid_Argument with "Run_Lloyd: bad extents";
      end if;
      for K in 1 .. M loop
         for J in 1 .. D loop
            Book (K, J) :=
              Init (Codeword_Index (Natural (K) + Init_Row),
                    Dim_Index (J + Init_Off));
         end loop;
      end loop;

      Lab := Assign (Data, Book);
      Curr_D := Distortion (Data, Book, Lab);
      Result.Iters := 0;
      Result.Converged := False;

      for Iter in 1 .. Params.Max_Lloyd_Iters loop
         Prev_D := Curr_D;
         Update_Centroids (Data, Lab, Book, Empty);
         Lab := Assign (Data, Book);
         Curr_D := Distortion (Data, Book, Lab);
         Result.Iters := Iter;

         if Prev_D <= Floor_Dist then
            Rel := abs (Prev_D - Curr_D);
         else
            Rel := abs (Prev_D - Curr_D) / Prev_D;
         end if;

         if Rel <= Params.Stop_Epsilon then
            Result.Converged := True;
            exit;
         end if;
      end loop;

      Result.Book := Book;
      Result.Lab := Lab;
      Result.Empty := Empty;
      Result.Distortion := Curr_D;
      Result.Avg_Distortion := Curr_D / Real (N);
      Result.Num_Codewords := M;
      return Result;
   end Run_Lloyd;

   -------------------------------------------------------------------------
   -- Run_LBG
   -------------------------------------------------------------------------

   function Run_LBG
     (Data   : Dataset;
      Params : Parameters := Default_Parameters) return LBG_Result
   is
      N           : constant Point_Count := Data'Length (1);
      D           : constant Dim_Count := Data'Length (2);
      Target      : constant Codeword_Count := Params.Target_Size;
      Mean        : Point (1 .. D);
      Curr_M      : Codeword_Count;
      Book        : Codebook (1 .. Max_Codewords, 1 .. D) :=
                      [others => [others => 0.0]];
      Lab         : Labels (1 .. N);
      Empty       : Empty_Flags (1 .. Max_Codewords) := [others => False];
      Total_Iters : Natural := 0;
      Final_D     : Non_Negative := 0.0;
      Result      : LBG_Result (N => N, M => Target, D => D);
      Sub_Params  : constant Parameters := Params;
      Converged   : Boolean := False;
   begin
      if N < 1 or else D < 1 then
         raise Invalid_Argument with "Run_LBG: empty data";
      end if;
      if Target < 1 then
         raise Invalid_Argument with "Run_LBG: Target_Size < 1";
      end if;
      --  Step 1: c0 = mean(training); codebook = {c0}; refine with Lloyd.
      Mean := Mean_Point (Data);
      declare
         Tiny : Codebook (1 .. 1, 1 .. D);
         R1   : LBG_Result (N => N, M => 1, D => D);
      begin
         for J in 1 .. D loop
            Tiny (1, J) := Mean (J);
         end loop;
         R1 := Run_Lloyd (Data, Tiny, Sub_Params);
         for J in 1 .. D loop
            Book (1, J) := R1.Book (1, J);
         end loop;
         Lab := R1.Lab;
         Empty (1) := R1.Empty (1);
         Final_D := R1.Distortion;
         Total_Iters := R1.Iters;
         Converged := R1.Converged;
      end;
      Curr_M := 1;

      --  Step 2: while |codebook| < M: split each y → {y, y+ε}; Lloyd.
      while Curr_M < Target loop
         declare
            Src     : Codebook (1 .. Curr_M, 1 .. D);
            Doubled : Codebook (1 .. 2 * Curr_M, 1 .. D);
            Take    : Codeword_Count;
         begin
            for K in 1 .. Curr_M loop
               for J in 1 .. D loop
                  Src (K, J) := Book (K, J);
               end loop;
            end loop;

            if Curr_M > Max_Codewords / 2 then
               raise Capacity_Exceeded
                 with "Run_LBG: cannot split further";
            end if;

            Doubled := Split_Codebook (Src, Params.Split_Epsilon);

            if Doubled'Length (1) > Target then
               Take := Target;
            else
               Take := Doubled'Length (1);
            end if;

            declare
               Init_Slice : Codebook (1 .. Take, 1 .. D);
               R          : LBG_Result (N => N, M => Take, D => D);
            begin
               for K in 1 .. Take loop
                  for J in 1 .. D loop
                     Init_Slice (K, J) := Doubled (K, J);
                  end loop;
               end loop;
               R := Run_Lloyd (Data, Init_Slice, Sub_Params);
               for K in 1 .. Take loop
                  for J in 1 .. D loop
                     Book (K, J) := R.Book (K, J);
                  end loop;
                  Empty (K) := R.Empty (K);
               end loop;
               Lab := R.Lab;
               Final_D := R.Distortion;
               Total_Iters := Total_Iters + R.Iters;
               Converged := R.Converged;
               Curr_M := Take;
            end;
         end;
      end loop;

      for K in 1 .. Target loop
         for J in 1 .. D loop
            Result.Book (K, J) := Book (K, J);
         end loop;
         Result.Empty (K) := Empty (K);
      end loop;
      Result.Lab := Lab;
      Result.Distortion := Final_D;
      Result.Avg_Distortion := Final_D / Real (N);
      Result.Iters := Total_Iters;
      Result.Num_Codewords := Target;
      Result.Converged := Converged;
      return Result;
   end Run_LBG;

end Linde_Buzo_Gray;
