--  Standalone test suite for Linde_Buzo_Gray (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Linde_Buzo_Gray; use Linde_Buzo_Gray;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check
     (Condition : Boolean;
      Message   : String)
   is
   begin
      if Condition then
         Pass_Count := Pass_Count + 1;
         Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      New_Line;
      Put_Line ("=== " & Title & " ===");
   end Section;

   function Approx (A, B : Real; Tol : Real := 1.0E-5) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx;

   --  True if some codeword is within Tol of (X, Y).
   function Has_Center
     (Book : Codebook; X, Y : Real; Tol : Real := 0.5) return Boolean
   is
   begin
      for K in Book'Range (1) loop
         if Approx (Book (K, 1), X, Tol)
           and then Approx (Book (K, 2), Y, Tol)
         then
            return True;
         end if;
      end loop;
      return False;
   end Has_Center;

begin
   Put_Line ("Linde_Buzo_Gray test suite");
   Put_Line ("==========================");

   ---------------------------------------------------------------------
   Section ("1. Near helper");
   ---------------------------------------------------------------------
   declare
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-9), "Near tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects large delta");
      Check (Near (0.0, 1.0E-10, 1.0E-9), "Near custom Tol");
      Check (not Near (0.0, 1.0E-6, 1.0E-9), "Near custom Tol reject");
   end;

   ---------------------------------------------------------------------
   Section ("2. Distance / Squared_Distance");
   ---------------------------------------------------------------------
   declare
      A : constant Point := [1.0, 2.0];
      B : constant Point := [4.0, 6.0];
      C : constant Point := [0.0, 0.0, 0.0];
      D : constant Point := [1.0, 0.0, 0.0];
      Z : constant Point := [5.0, -1.0];
   begin
      Check (Approx (Squared_Distance (A, B), 25.0), "3-4-5 sq=25");
      Check (Approx (Distance (A, B), 5.0), "3-4-5 dist=5");
      Check (Approx (Squared_Distance (A, A), 0.0), "identical sq=0");
      Check (Approx (Distance (A, A), 0.0), "identical dist=0");
      Check (Approx (Squared_Distance (C, D), 1.0), "unit axis 3-D sq");
      Check (Approx (Squared_Distance (Z, [0.0, 0.0]), 26.0), "origin sq=26");
      Check (Distance (A, B) > 0.0, "positive for distinct");
      Check (Squared_Distance (A, B) > Squared_Distance (A, A),
             "sq grows with separation");
   end;

   ---------------------------------------------------------------------
   Section ("3. Extract / Nearest_Codeword / Assign");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0, 0.0],
         [10.0, 0.0],
         [1.0, 1.0]];
      Book : constant Codebook :=
        [[0.0, 0.0],
         [10.0, 0.0]];
      P0 : constant Point := Extract_Point (Data, 1);
      P1 : constant Point := Extract_Point (Data, 2);
      C0 : constant Point := Extract_Codeword (Book, 1);
      Q  : constant Point := [1.0, 0.0];
      Q2 : constant Point := [9.0, 0.0];
      Q3 : constant Point := [5.0, 0.0];
      Lab : constant Labels := Assign (Data, Book);
   begin
      Check (Approx (P0 (1), 0.0) and Approx (P0 (2), 0.0), "extract p1");
      Check (Approx (P1 (1), 10.0), "extract p2 x");
      Check (Approx (C0 (1), 0.0), "extract codeword1");
      Check (Nearest_Codeword (Q, Book) = 1, "nearest to left");
      Check (Nearest_Codeword (Q2, Book) = 2, "nearest to right");
      Check (Nearest_Codeword (Q3, Book) = 1, "tie → lowest index");
      Check (Lab (1) = 1, "assign p1 → 1");
      Check (Lab (2) = 2, "assign p2 → 2");
      Check (Lab (3) = 1, "assign p3 → 1");
   end;

   ---------------------------------------------------------------------
   Section ("4. Mean_Point as 1-word codebook");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0, 0.0],
         [2.0, 0.0],
         [0.0, 2.0],
         [2.0, 2.0]];
      M : constant Point := Mean_Point (Data);
      Book : Codebook (1 .. 1, 1 .. 2);
      Lab : Labels (1 .. 4);
      Params : Parameters := Default_Parameters;
      R : LBG_Result (N => 4, M => 1, D => 2);
   begin
      Check (Approx (M (1), 1.0), "mean x=1");
      Check (Approx (M (2), 1.0), "mean y=1");
      Book (1, 1) := M (1);
      Book (1, 2) := M (2);
      Lab := Assign (Data, Book);
      Check (Lab (1) = 1 and Lab (2) = 1 and Lab (3) = 1 and Lab (4) = 1,
             "all assigned to sole codeword");
      Check (Approx (Distortion (Data, Book, Lab), 8.0),
             "mean-only SSE=8 (4 pts × 2)");
      Params.Target_Size := 1;
      Params.Stop_Epsilon := 1.0E-9;
      R := Run_LBG (Data, Params);
      Check (R.Num_Codewords = 1, "LBG M=1 → 1 codeword");
      Check (Approx (R.Book (1, 1), 1.0) and Approx (R.Book (1, 2), 1.0),
             "LBG M=1 recovers global mean");
      Check (Approx (R.Distortion, 8.0), "LBG M=1 distortion=8");
   end;

   ---------------------------------------------------------------------
   Section ("5. Split_Codebook doubles size");
   ---------------------------------------------------------------------
   declare
      Book : constant Codebook :=
        [[1.0, 2.0],
         [3.0, 4.0]];
      Eps : constant Positive_Real := 0.1;
      Sp : constant Codebook := Split_Codebook (Book, Eps);
   begin
      Check (Sp'Length (1) = 4, "split 2 → 4");
      Check (Sp'Length (2) = 2, "dims preserved");
      Check (Approx (Sp (1, 1), 1.0) and Approx (Sp (1, 2), 2.0),
             "first = original y1");
      Check (Approx (Sp (2, 1), 1.1) and Approx (Sp (2, 2), 2.0),
             "second = y1+ε·e1");
      Check (Approx (Sp (3, 1), 3.0) and Approx (Sp (3, 2), 4.0),
             "third = original y2");
      Check (Approx (Sp (4, 1), 3.1) and Approx (Sp (4, 2), 4.0),
             "fourth = y2+ε·e1");
      declare
         One : constant Codebook := [[0.0, 0.0]];
         Two : constant Codebook := Split_Codebook (One, 1.0E-2);
      begin
         Check (Two'Length (1) = 2, "split 1 → 2");
         Check (Approx (Two (1, 1), 0.0), "y kept");
         Check (Approx (Two (2, 1), 1.0E-2), "y+ε");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("6. Centroid / Update_Centroids / empty keep");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0, 0.0],
         [1.0, 0.0],
         [10.0, 0.0],
         [11.0, 0.0]];
      Book : Codebook :=
        [[0.0, 0.0],
         [10.0, 0.0],
         [100.0, 100.0]];  -- will be empty
      Lab : Labels (1 .. 4);
      Empty : Empty_Flags (1 .. 3);
      Kept_X, Kept_Y : Real;
      C1 : Point (1 .. 2);
   begin
      Lab := Assign (Data, Book);
      Check (Lab (1) = 1 and Lab (2) = 1, "left cluster labels");
      Check (Lab (3) = 2 and Lab (4) = 2, "right cluster labels");
      C1 := Centroid (Data, Lab, 1);
      Check (Approx (C1 (1), 0.5) and Approx (C1 (2), 0.0),
             "centroid of left cell");
      Kept_X := Book (3, 1);
      Kept_Y := Book (3, 2);
      Update_Centroids (Data, Lab, Book, Empty);
      Check (not Empty (1) and not Empty (2), "cells 1,2 nonempty");
      Check (Empty (3), "cell 3 empty");
      Check (Approx (Book (3, 1), Kept_X) and Approx (Book (3, 2), Kept_Y),
             "empty cell keeps previous codevector");
      Check (Approx (Book (1, 1), 0.5), "updated centroid1");
      Check (Approx (Book (2, 1), 10.5), "updated centroid2");
   end;

   ---------------------------------------------------------------------
   Section ("7. Lloyd decreases / nonincreases distortion");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0, 0.0],
         [0.1, 0.0],
         [0.0, 0.1],
         [10.0, 10.0],
         [10.1, 10.0],
         [10.0, 10.1]];
      Init : constant Codebook :=
        [[1.0, 1.0],
         [9.0, 9.0]];
      Lab0 : constant Labels := Assign (Data, Init);
      D0 : constant Non_Negative := Distortion (Data, Init, Lab0);
      Params : Parameters := Default_Parameters;
      R : LBG_Result (N => 6, M => 2, D => 2);
   begin
      Params.Stop_Epsilon := 1.0E-9;
      Params.Max_Lloyd_Iters := 50;
      R := Run_Lloyd (Data, Init, Params);
      Check (R.Distortion <= D0 + 1.0E-9, "Lloyd distortion ≤ initial");
      Check (R.Num_Codewords = 2, "Lloyd keeps size 2");
      Check (R.Iters >= 1, "Lloyd ran ≥1 iter");
      Check (Approx (R.Avg_Distortion, R.Distortion / 6.0),
             "avg = total/N");
      --  Second Lloyd from result should not increase.
      declare
         R2 : constant LBG_Result := Run_Lloyd (Data, R.Book, Params);
      begin
         Check (R2.Distortion <= R.Distortion + 1.0E-9,
                "re-Lloyd nonincreasing");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("8. LBG to 2 codewords on two blobs");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0, 0.0],
         [0.2, 0.0],
         [0.0, 0.2],
         [0.1, 0.1],
         [10.0, 10.0],
         [10.2, 10.0],
         [10.0, 10.2],
         [10.1, 10.1]];
      Params : Parameters := Default_Parameters;
      R : LBG_Result (N => 8, M => 2, D => 2);
      Mean_Only : Non_Negative;
      Mean_Pt : constant Point := Mean_Point (Data);
      Book1 : Codebook (1 .. 1, 1 .. 2);
      Lab1 : Labels (1 .. 8);
   begin
      Params.Target_Size := 2;
      Params.Split_Epsilon := 0.1;
      Params.Stop_Epsilon := 1.0E-8;
      Params.Max_Lloyd_Iters := 100;
      R := Run_LBG (Data, Params);
      Check (R.Num_Codewords = 2, "LBG M=2 size");
      Check (Has_Center (R.Book, 0.075, 0.075, 0.5)
             or else Has_Center (R.Book, 0.1, 0.1, 0.5),
             "recovers near blob A center");
      Check (Has_Center (R.Book, 10.075, 10.075, 0.5)
             or else Has_Center (R.Book, 10.1, 10.1, 0.5),
             "recovers near blob B center");
      Book1 (1, 1) := Mean_Pt (1);
      Book1 (1, 2) := Mean_Pt (2);
      Lab1 := Assign (Data, Book1);
      Mean_Only := Distortion (Data, Book1, Lab1);
      Check (R.Distortion <= Mean_Only + 1.0E-9,
             "LBG M=2 distortion ≤ mean-only");
      Check (R.Distortion < Mean_Only * 0.5,
             "LBG M=2 much better than mean-only");
      --  Assignment consistency: each point's label matches Nearest
      declare
         Ok : Boolean := True;
         Pt : Point (1 .. 2);
      begin
         for P in Data'Range (1) loop
            Pt := Extract_Point (Data, P);
            if Natural (Nearest_Codeword (Pt, R.Book)) /= R.Lab (P) then
               Ok := False;
            end if;
         end loop;
         Check (Ok, "assignment consistent with Nearest_Codeword");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("9. LBG to 4 codewords on four blobs");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0, 0.0], [0.1, 0.0], [0.0, 0.1],
         [10.0, 0.0], [10.1, 0.0], [10.0, 0.1],
         [0.0, 10.0], [0.1, 10.0], [0.0, 10.1],
         [10.0, 10.0], [10.1, 10.0], [10.0, 10.1]];
      Params : Parameters := Default_Parameters;
      R : LBG_Result (N => 12, M => 4, D => 2);
   begin
      Params.Target_Size := 4;
      Params.Split_Epsilon := 0.05;
      Params.Stop_Epsilon := 1.0E-8;
      R := Run_LBG (Data, Params);
      Check (R.Num_Codewords = 4, "LBG M=4 size");
      Check (Has_Center (R.Book, 0.033, 0.033, 0.6), "blob (0,0)");
      Check (Has_Center (R.Book, 10.033, 0.033, 0.6), "blob (10,0)");
      Check (Has_Center (R.Book, 0.033, 10.033, 0.6), "blob (0,10)");
      Check (Has_Center (R.Book, 10.033, 10.033, 0.6), "blob (10,10)");
      Check (R.Distortion < 1.0, "M=4 low distortion on tight blobs");
   end;

   ---------------------------------------------------------------------
   Section ("10. Identical points");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[3.0, 4.0],
         [3.0, 4.0],
         [3.0, 4.0],
         [3.0, 4.0]];
      Params : Parameters := Default_Parameters;
      R2 : LBG_Result (N => 4, M => 2, D => 2);
      R1 : LBG_Result (N => 4, M => 1, D => 2);
   begin
      Params.Target_Size := 1;
      R1 := Run_LBG (Data, Params);
      Check (Approx (R1.Book (1, 1), 3.0) and Approx (R1.Book (1, 2), 4.0),
             "identical → mean at point");
      Check (Approx (R1.Distortion, 0.0), "identical M=1 distortion 0");
      Params.Target_Size := 2;
      Params.Split_Epsilon := 0.01;
      R2 := Run_LBG (Data, Params);
      Check (Approx (R2.Distortion, 0.0, 1.0E-6),
             "identical M=2 still ~0 distortion");
      Check (R2.Num_Codewords = 2, "identical M=2 size");
   end;

   ---------------------------------------------------------------------
   Section ("11. Design_Codebook alias / Avg_Distortion");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[1.0], [2.0], [3.0], [10.0], [11.0], [12.0]];
      Params : Parameters := Default_Parameters;
      R : LBG_Result (N => 6, M => 2, D => 1);
      Lab : Labels (1 .. 6);
   begin
      Params.Target_Size := 2;
      Params.Split_Epsilon := 0.1;
      R := Design_Codebook (Data, Params);
      Check (R.Num_Codewords = 2, "Design_Codebook alias works");
      Lab := Assign (Data, R.Book);
      Check (Approx (Average_Distortion (Data, R.Book, Lab),
                     Distortion (Data, R.Book, Lab) / 6.0),
             "Average_Distortion = Distortion/N");
      Check (Approx (R.Avg_Distortion, R.Distortion / 6.0),
             "result Avg_Distortion consistent");
      --  1-D two clusters around ~2 and ~11
      Check ((Approx (R.Book (1, 1), 2.0, 1.0)
              and then Approx (R.Book (2, 1), 11.0, 1.0))
             or else
             (Approx (R.Book (2, 1), 2.0, 1.0)
              and then Approx (R.Book (1, 1), 11.0, 1.0)),
             "1-D LBG recovers two cluster means");
   end;

   ---------------------------------------------------------------------
   Section ("12. Invalid arguments");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset := [[1.0, 2.0], [3.0, 4.0]];
      Raised : Boolean;
   begin
      Raised := False;
      begin
         declare
            Q : constant Point := [1.0, 2.0];
            B : constant Codebook := [[0.0]];
            K : Codeword_Index;
            pragma Unreferenced (K);
         begin
            K := Nearest_Codeword (Q, B);
         end;
      exception
         when Invalid_Argument => Raised := True;
      end;
      Check (Raised, "Nearest dim mismatch → Invalid_Argument");

      Raised := False;
      begin
         declare
            P0 : constant Parameters :=
              (Target_Size => 0, Split_Epsilon => 0.01,
               Stop_Epsilon => 1.0E-6, Max_Lloyd_Iters => 10);
            R : LBG_Result (N => 2, M => 0, D => 2);
            pragma Unreferenced (R);
         begin
            R := Run_LBG (Data, P0);
         end;
      exception
         when Invalid_Argument => Raised := True;
         when Constraint_Error => Raised := True;
      end;
      Check (Raised, "Target_Size=0 → Invalid_Argument or Constraint_Error");

      Raised := False;
      begin
         declare
            Lab : constant Labels := [1, 1];
            C : Point (1 .. 2);
            pragma Unreferenced (C);
         begin
            C := Centroid (Data, Lab, 2);  -- no points labeled 2
         end;
      exception
         when Invalid_Argument => Raised := True;
      end;
      Check (Raised, "Centroid empty cell → Invalid_Argument");

      Raised := False;
      begin
         declare
            Lab : constant Labels (1 .. 2) := [1, 99];
            Book : Codebook := [[0.0, 0.0]];
            Empty : Empty_Flags (1 .. 1);
         begin
            Update_Centroids (Data, Lab, Book, Empty);
         end;
      exception
         when Invalid_Argument => Raised := True;
      end;
      Check (Raised, "Update_Centroids bad label → Invalid_Argument");

      --  Caps are documented educational limits.
      Check (Integer'Image (Max_Points) = " 256", "Max_Points Image");
      Check (Integer'Image (Max_Dims) = " 16", "Max_Dims Image");
      Check (Integer'Image (Max_Codewords) = " 64", "Max_Codewords Image");
   end;

   ---------------------------------------------------------------------
   Section ("13. Permutation / label partition properties");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0, 0.0],
         [1.0, 0.0],
         [10.0, 0.0],
         [11.0, 0.0]];
      Params : Parameters := Default_Parameters;
      R : LBG_Result (N => 4, M => 2, D => 2);
      Count1, Count2 : Natural := 0;
   begin
      Params.Target_Size := 2;
      Params.Split_Epsilon := 0.5;
      R := Run_LBG (Data, Params);
      for P in R.Lab'Range loop
         Check (R.Lab (P) = 1 or else R.Lab (P) = 2,
                "label in 1..2 for p" & Integer'Image (P));
         if R.Lab (P) = 1 then
            Count1 := Count1 + 1;
         else
            Count2 := Count2 + 1;
         end if;
      end loop;
      Check (Count1 + Count2 = 4, "all points labeled");
      Check (Count1 >= 1 and Count2 >= 1, "both codewords used on 2-blobs");
      --  Distortion equals manual sum
      declare
         Manual : Real := 0.0;
         Pt, Cw : Point (1 .. 2);
      begin
         for P in Data'Range (1) loop
            Pt := Extract_Point (Data, P);
            Cw := Extract_Codeword (R.Book, Codeword_Index (R.Lab (P)));
            Manual := Manual + Squared_Distance (Pt, Cw);
         end loop;
         Check (Approx (Manual, R.Distortion),
                "manual SSE matches result Distortion");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("14. Lloyd fixed-size vs LBG split path");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0], [0.5], [1.0], [9.0], [9.5], [10.0]];
      Init : constant Codebook := [[0.0], [10.0]];
      Params : Parameters := Default_Parameters;
      RL : LBG_Result (N => 6, M => 2, D => 1);
      RG : LBG_Result (N => 6, M => 2, D => 1);
   begin
      Params.Stop_Epsilon := 1.0E-9;
      Params.Max_Lloyd_Iters := 80;
      RL := Run_Lloyd (Data, Init, Params);
      Params.Target_Size := 2;
      Params.Split_Epsilon := 0.1;
      RG := Run_LBG (Data, Params);
      Check (RL.Num_Codewords = 2 and RG.Num_Codewords = 2,
             "both produce 2 codewords");
      Check (RL.Distortion < 2.0, "Lloyd on good init low SSE");
      Check (RG.Distortion < 2.0, "LBG M=2 low SSE");
      Check (RL.Distortion >= 0.0 and RG.Distortion >= 0.0,
             "both distortions non-negative");
      --  Stronger: both recover ~0.5 and ~9.5
      Check ((Approx (RL.Book (1, 1), 0.5, 0.3)
              or else Approx (RL.Book (2, 1), 0.5, 0.3)),
             "Lloyd has ~0.5 center");
      Check ((Approx (RG.Book (1, 1), 0.5, 0.3)
              or else Approx (RG.Book (2, 1), 0.5, 0.3)),
             "LBG has ~0.5 center");
   end;

   ---------------------------------------------------------------------
   Section ("15. Relative stop / Max_Lloyd_Iters");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0, 0.0], [1.0, 0.0], [8.0, 0.0], [9.0, 0.0]];
      Init : constant Codebook := [[0.0, 0.0], [9.0, 0.0]];
      P_Tight : Parameters := Default_Parameters;
      P_One   : Parameters := Default_Parameters;
      R_Tight, R_One : LBG_Result (N => 4, M => 2, D => 2);
   begin
      P_Tight.Stop_Epsilon := 1.0E-12;
      P_Tight.Max_Lloyd_Iters := 100;
      R_Tight := Run_Lloyd (Data, Init, P_Tight);
      P_One.Stop_Epsilon := 0.0;
      P_One.Max_Lloyd_Iters := 1;
      R_One := Run_Lloyd (Data, Init, P_One);
      Check (R_One.Iters = 1, "Max_Lloyd_Iters=1 → exactly 1 iter");
      Check (R_Tight.Iters >= 1, "tight stop still ≥1 iter");
      Check (R_Tight.Distortion <= R_One.Distortion + 1.0E-9,
             "more iters ≤ fewer iters distortion");
   end;

   ---------------------------------------------------------------------
   Section ("16. Default_Parameters / Training_Set subtype");
   ---------------------------------------------------------------------
   declare
      TS : constant Training_Set :=
        [[1.0, 1.0],
         [2.0, 2.0],
         [8.0, 8.0],
         [9.0, 9.0]];
      R : constant LBG_Result :=
        Run_LBG (TS, (Target_Size => 2, Split_Epsilon => 0.05,
                      Stop_Epsilon => 1.0E-7, Max_Lloyd_Iters => 50));
   begin
      Check (Default_Parameters.Target_Size = 4, "default Target_Size=4");
      Check (Default_Parameters.Split_Epsilon > 0.0, "default Split_Epsilon>0");
      Check (R.Num_Codewords = 2, "Training_Set works with Run_LBG");
      Check (R.Distortion >= 0.0, "nonneg distortion");
      Check (R.Iters >= 1, "iters recorded");
   end;

   ---------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------
   New_Line;
   Put_Line ("==========================");
   Put_Line ("Passed :" & Natural'Image (Pass_Count));
   Put_Line ("Failed :" & Natural'Image (Fail_Count));
   Put_Line ("==========================");

   pragma Assert (Fail_Count = 0);

end Tests;
