--  Standalone test suite for Canopy_Clustering (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line;
with Canopy_Clustering; use Canopy_Clustering;

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

   function Approx (A, B : Real; Tol : Real := 1.0E-6) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx;

begin
   Put_Line ("Canopy_Clustering test suite");
   Put_Line ("============================");

   ---------------------------------------------------------------------
   Section ("1. Near / Make_Parameters");
   ---------------------------------------------------------------------
   declare
      P : Parameters;
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-9), "Near tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects large delta");
      Check (Near (0.0, 1.0E-10, 1.0E-9), "Near custom Tol");
      Check (not Near (0.0, 1.0E-6, 1.0E-9), "Near custom Tol reject");

      P := Make_Parameters (1.0, 0.5);
      Check (Near (P.T1, 1.0) and then Near (P.T2, 0.5),
             "Make_Parameters T1=1 T2=0.5");
      Check (Near (Default_Parameters.T1, 1.0), "Default T1=1");
      Check (Near (Default_Parameters.T2, 0.5), "Default T2=0.5");

      begin
         P := Make_Parameters (0.5, 0.5);
         Check (False, "Make_Parameters T1=T2 should raise");
      exception
         when Invalid_Argument =>
            Check (True, "Make_Parameters T1=T2 raises");
      end;
      begin
         P := Make_Parameters (0.4, 0.5);
         Check (False, "Make_Parameters T1<T2 should raise");
      exception
         when Invalid_Argument =>
            Check (True, "Make_Parameters T1<T2 raises");
      end;
      begin
         P := Make_Parameters (1.0, 0.0);
         Check (False, "Make_Parameters T2=0 should raise");
      exception
         when Invalid_Argument =>
            Check (True, "Make_Parameters T2=0 raises");
      end;
      begin
         P := Make_Parameters (1.0, -0.1);
         Check (False, "Make_Parameters T2<0 should raise");
      exception
         when Invalid_Argument =>
            Check (True, "Make_Parameters T2<0 raises");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("2. Distance Euclidean L2");
   ---------------------------------------------------------------------
   declare
      Data : Dataset (1 .. 4, 1 .. 2);
   begin
      Data (1, 1) := 0.0; Data (1, 2) := 0.0;
      Data (2, 1) := 3.0; Data (2, 2) := 4.0;
      Data (3, 1) := 1.0; Data (3, 2) := 0.0;
      Data (4, 1) := 100.0; Data (4, 2) := 0.0;

      Check (Near (Distance (Data, 1, 1), 0.0), "self distance 0");
      Check (Near (Distance (Data, 1, 2), 5.0), "3-4-5 triangle");
      Check (Near (Distance (Data, 1, 3), 1.0), "unit step on X");
      Check (Distance (Data, 1, 4) > 99.0, "far point large dist");
      Check (Near (Distance (Data, 2, 1), 5.0), "symmetric distance");

      begin
         declare
            Dbg : constant Real := Distance (Data, 1, 99);
            pragma Unreferenced (Dbg);
         begin
            Check (False, "Distance bad id should raise");
         end;
      exception
         when Invalid_Argument =>
            Check (True, "Distance bad id raises");
         when Constraint_Error =>
            Check (True, "Distance bad id raises (constraint)");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("3. Empty and singleton");
   ---------------------------------------------------------------------
   declare
      Empty_Data : Dataset (1 .. 0, 1 .. 2);
      One : Dataset (1 .. 1, 1 .. 2);
      Params : constant Parameters := Make_Parameters (1.0, 0.5);
      R0 : constant Result := Run_Canopy (Empty_Data, Params);
   begin
      Check (R0.N = 0, "empty: N=0");
      Check (R0.C = 0, "empty: C=0");
      Check (Canopy_Count_Of (R0) = 0, "empty: Canopy_Count_Of=0");

      One (1, 1) := 3.0; One (1, 2) := 4.0;
      declare
         R1 : constant Result := Run_Canopy (One, Params);
      begin
         Check (R1.N = 1, "singleton: N=1");
         Check (R1.C = 1, "singleton: one canopy");
         Check (R1.Center_Ids (1) = 1, "singleton: center is point 1");
         Check (Point_In_Canopy (R1, 1, 1), "singleton: point in own canopy");
         Check (Near (R1.Centers (1, 1), 3.0)
                  and then Near (R1.Centers (1, 2), 4.0),
                "singleton: center coords match");
         Check (Canopies_Of (R1, 1).Count = 1,
                "singleton: membership count 1");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("4. Center is first removed (lowest index) point");
   ---------------------------------------------------------------------
   declare
      Data : Dataset (1 .. 3, 1 .. 1);
      Params : constant Parameters := Make_Parameters (1.0, 0.5);
   begin
      Data (1, 1) := 0.0;
      Data (2, 1) := 10.0;
      Data (3, 1) := 20.0;
      declare
         R : constant Result := Run_Canopy (Data, Params);
      begin
         Check (R.C = 3, "three distant points → 3 canopies");
         Check (R.Center_Ids (1) = 1, "first center = point 1");
         Check (R.Center_Ids (2) = 2, "second center = point 2");
         Check (R.Center_Ids (3) = 3, "third center = point 3");
         Check (Point_In_Canopy (R, 1, 1)
                  and then not Point_In_Canopy (R, 1, 2),
                "point1 only in canopy1");
         Check (Point_In_Canopy (R, 2, 2), "point2 in canopy2");
         Check (Point_In_Canopy (R, 3, 3), "point3 in canopy3");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("5. Two distant blobs → ≥2 canopies");
   ---------------------------------------------------------------------
   declare
      Data : Dataset (1 .. 6, 1 .. 2);
      Params : constant Parameters := Make_Parameters (2.0, 1.0);
   begin
      Data (1, 1) := 0.0; Data (1, 2) := 0.0;
      Data (2, 1) := 0.3; Data (2, 2) := 0.1;
      Data (3, 1) := 0.1; Data (3, 2) := 0.4;
      Data (4, 1) := 50.0; Data (4, 2) := 50.0;
      Data (5, 1) := 50.2; Data (5, 2) := 49.8;
      Data (6, 1) := 49.7; Data (6, 2) := 50.3;

      declare
         R : constant Result := Run_Canopy (Data, Params);
      begin
         Check (R.C >= 2, "two blobs: ≥2 canopies");
         Check (R.Center_Ids (1) = 1, "first canopy centered at point 1");
         Check (Point_In_Canopy (R, 1, 1), "blobA p1 in canopy1");
         Check (Point_In_Canopy (R, 2, 1), "blobA p2 in canopy1");
         Check (Point_In_Canopy (R, 3, 1), "blobA p3 in canopy1");
         Check (not Point_In_Canopy (R, 4, 1), "blobB p4 not in canopy1");
         Check (not Point_In_Canopy (R, 5, 1), "blobB p5 not in canopy1");
         Check (Canopy_Count_Of (R) = R.C, "Canopy_Count_Of matches R.C");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("6. Points within T2 removed from pool");
   ---------------------------------------------------------------------
   declare
      Data : Dataset (1 .. 3, 1 .. 1);
      Params : constant Parameters := Make_Parameters (1.0, 0.5);
   begin
      Data (1, 1) := 0.0;
      Data (2, 1) := 0.4;
      Data (3, 1) := 0.8;
      declare
         R : constant Result := Run_Canopy (Data, Params);
         P2_Is_Center : Boolean := False;
      begin
         Check (R.Center_Ids (1) = 1, "T2-remove: first center=1");
         Check (Point_In_Canopy (R, 2, 1), "p2 in canopy1 (dist<T1)");
         Check (Point_In_Canopy (R, 3, 1), "p3 in canopy1 (dist<T1)");
         for C in 1 .. Canopy_Index (R.C) loop
            if R.Center_Ids (C) = 2 then
               P2_Is_Center := True;
            end if;
         end loop;
         Check (not P2_Is_Center, "p2 within T2 never becomes a center");
         Check (R.C >= 1 and then R.C <= 2, "T2 case: 1 or 2 canopies");
         if R.C = 2 then
            Check (R.Center_Ids (2) = 3,
                   "second center is p3 if present");
         else
            Check (True, "single canopy when p3 also absorbed");
         end if;
      end;
   end;

   ---------------------------------------------------------------------
   Section ("7. Overlap when T1 large (multi-membership)");
   ---------------------------------------------------------------------
   declare
      Data : Dataset (1 .. 3, 1 .. 1);
      Params : constant Parameters := Make_Parameters (1.5, 0.3);
   begin
      Data (1, 1) := 0.0;
      Data (2, 1) := 1.0;
      Data (3, 1) := 2.0;
      declare
         R : constant Result := Run_Canopy (Data, Params);
         Overlap_Count : Natural := 0;
      begin
         Check (R.C >= 2, "overlap setup: ≥2 canopies");
         for P in 1 .. Point_Index (R.N) loop
            if Canopies_Of (R, P).Count > 1 then
               Overlap_Count := Overlap_Count + 1;
            end if;
         end loop;
         Check (Overlap_Count >= 1, "at least one multi-membership point");
         Check (Canopies_Of (R, 2).Count >= 2
                  or else Point_In_Canopy (R, 2, 1),
                "middle point participates in canopy1");
         if R.C >= 2 then
            Check (Point_In_Canopy (R, 2, 1), "p2 in first canopy");
         else
            Check (True, "skipped dual check (only one canopy)");
         end if;
      end;
   end;

   ---------------------------------------------------------------------
   Section ("8. All one canopy when T1 huge");
   ---------------------------------------------------------------------
   declare
      Data : Dataset (1 .. 5, 1 .. 2);
      Params : constant Parameters := Make_Parameters (1000.0, 500.0);
   begin
      Data (1, 1) := 0.0; Data (1, 2) := 0.0;
      Data (2, 1) := 1.0; Data (2, 2) := 1.0;
      Data (3, 1) := 2.0; Data (3, 2) := 0.0;
      Data (4, 1) := 0.0; Data (4, 2) := 3.0;
      Data (5, 1) := 4.0; Data (5, 2) := 4.0;
      declare
         R : constant Result := Run_Canopy (Data, Params);
      begin
         Check (R.C = 1, "huge T1/T2: single canopy");
         Check (R.Center_Ids (1) = 1, "huge: center is first point");
         for P in 1 .. Point_Index (5) loop
            Check (Point_In_Canopy (R, P, 1),
                   "huge: point" & P'Image & " in canopy1");
         end loop;
      end;
   end;

   ---------------------------------------------------------------------
   Section ("9. Invalid T1≤T2 / Point_In_Canopy range");
   ---------------------------------------------------------------------
   declare
      Data : Dataset (1 .. 2, 1 .. 1);
      Bad : Parameters;
   begin
      Data (1, 1) := 0.0;
      Data (2, 1) := 1.0;
      Bad.T1 := 1.0;
      Bad.T2 := 1.0;
      begin
         declare
            R : constant Result := Run_Canopy (Data, Bad);
            pragma Unreferenced (R);
         begin
            Check (False, "Run_Canopy T1=T2 should raise");
         end;
      exception
         when Invalid_Argument =>
            Check (True, "Run_Canopy T1=T2 raises");
      end;
      Bad.T1 := 0.5;
      Bad.T2 := 1.0;
      begin
         declare
            R : constant Result := Run_Canopy (Data, Bad);
            pragma Unreferenced (R);
         begin
            Check (False, "Run_Canopy T1<T2 should raise");
         end;
      exception
         when Invalid_Argument =>
            Check (True, "Run_Canopy T1<T2 raises");
      end;

      declare
         R_Ok : constant Result :=
           Run_Canopy (Data, Make_Parameters (2.0, 0.5));
      begin
         begin
            declare
               Dummy : constant Boolean := Point_In_Canopy (R_Ok, 1, 99);
               pragma Unreferenced (Dummy);
            begin
               Check (False, "Point_In_Canopy bad C should raise");
            end;
         exception
            when Invalid_Argument =>
               Check (True, "Point_In_Canopy bad C raises");
            when Constraint_Error =>
               Check (True, "Point_In_Canopy bad C raises (constraint)");
         end;
      end;
   end;

   ---------------------------------------------------------------------
   Section ("10. Hard labels: nearest center and first canopy");
   ---------------------------------------------------------------------
   declare
      Data : Dataset (1 .. 4, 1 .. 1);
      Params : constant Parameters := Make_Parameters (1.0, 0.3);
   begin
      Data (1, 1) := 0.0;
      Data (2, 1) := 0.4;
      Data (3, 1) := 1.2;
      Data (4, 1) := 10.0;
      declare
         R : constant Result := Run_Canopy (Data, Params);
         Near_Lab : constant Hard_Labels :=
           Hard_Labels_Nearest_Center (R, Data);
         First_Lab : constant Hard_Labels :=
           Hard_Labels_First_Canopy (R);
      begin
         Check (R.C >= 2, "hard-label setup: ≥2 canopies");
         Check (R.Center_Ids (1) = 1, "hard: first center=1");

         Check (Near_Lab (1) = 1, "nearest: center point → own canopy");
         Check (First_Lab (1) = 1, "first: center point → canopy1");
         Check (Near_Lab (4) /= 0, "nearest: far point labeled");
         Check (First_Lab (4) /= 0, "first: far point labeled");

         for P in 1 .. Point_Index (4) loop
            Check (Near_Lab (P) > 0, "nearest label >0 for p" & P'Image);
            Check (First_Lab (P) > 0, "first label >0 for p" & P'Image);
            Check (Point_In_Canopy (R, P, Canopy_Index (Near_Lab (P))),
                   "nearest label canopy covers p" & P'Image);
            Check (Point_In_Canopy (R, P, Canopy_Index (First_Lab (P))),
                   "first label canopy covers p" & P'Image);
         end loop;

         declare
            L : constant Canopy_Membership_List := Canopies_Of (R, 2);
         begin
            Check (L.Count >= 1, "p2 in ≥1 canopy");
            if L.Count >= 2 then
               declare
                  C_Near : constant Natural := Near_Lab (2);
                  Best : Real := Real'Last;
                  Dist : Real;
               begin
                  for I in 1 .. Canopy_Index (L.Count) loop
                     Dist := abs (Data (2, 1)
                       - R.Centers (L.Ids (I), 1));
                     if Dist < Best then
                        Best := Dist;
                     end if;
                  end loop;
                  Check (Approx (abs (Data (2, 1)
                           - R.Centers (Canopy_Index (C_Near), 1)), Best),
                         "nearest label is truly nearest for p2");
               end;
            else
               Check (True, "p2 single membership (ok)");
            end if;
         end;
      end;
   end;

   ---------------------------------------------------------------------
   Section ("11. Determinism: stable index order");
   ---------------------------------------------------------------------
   declare
      Data : Dataset (1 .. 5, 1 .. 2);
      Params : constant Parameters := Make_Parameters (1.5, 0.6);
   begin
      Data (1, 1) := 0.0; Data (1, 2) := 0.0;
      Data (2, 1) := 0.5; Data (2, 2) := 0.0;
      Data (3, 1) := 3.0; Data (3, 2) := 0.0;
      Data (4, 1) := 3.4; Data (4, 2) := 0.2;
      Data (5, 1) := 10.0; Data (5, 2) := 0.0;
      declare
         R1 : constant Result := Run_Canopy (Data, Params);
         R2 : constant Result := Run_Canopy (Data, Params);
         Same : Boolean := True;
      begin
         Check (R1.C = R2.C, "determinism: same canopy count");
         if R1.C = R2.C and then R1.C > 0 then
            for C in 1 .. Canopy_Index (R1.C) loop
               if R1.Center_Ids (C) /= R2.Center_Ids (C) then
                  Same := False;
               end if;
            end loop;
            for P in 1 .. Point_Index (R1.N) loop
               for C in 1 .. Canopy_Index (R1.C) loop
                  if R1.Memb (P, C) /= R2.Memb (P, C) then
                     Same := False;
                  end if;
               end loop;
            end loop;
         end if;
         Check (Same, "determinism: identical centers and membership");
         Check (R1.Center_Ids (1) = 1,
                "determinism: first center lowest index");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("12. Distance_To_Center / lists / helpers");
   ---------------------------------------------------------------------
   declare
      Data : Dataset (1 .. 3, 1 .. 2);
      Params : constant Parameters := Make_Parameters (5.0, 0.5);
   begin
      Data (1, 1) := 0.0; Data (1, 2) := 0.0;
      Data (2, 1) := 3.0; Data (2, 2) := 4.0;
      Data (3, 1) := 10.0; Data (3, 2) := 0.0;
      declare
         R : constant Result := Run_Canopy (Data, Params);
         L : Canopy_Membership_List;
      begin
         Check (R.C >= 1, "helpers: ≥1 canopy");
         Check (Near (Distance_To_Center (Data, 1, R.Centers, 1), 0.0),
                "Distance_To_Center center→self = 0");
         if Point_In_Canopy (R, 2, 1) then
            Check (Near (Distance_To_Center (Data, 2, R.Centers, 1), 5.0),
                   "Distance_To_Center 3-4-5");
         else
            Check (True, "p2 not in canopy1 (thresholds)");
         end if;

         L := Canopies_Of (R, 1);
         Check (L.Count >= 1, "Canopies_Of center nonempty");
         Check (L.Ids (1) = 1, "Canopies_Of center starts with canopy1");

         declare
            Empty_Data : Dataset (1 .. 0, 1 .. 2);
            RE : constant Result := Run_Canopy (Empty_Data, Params);
            HE : constant Hard_Labels := Hard_Labels_First_Canopy (RE);
         begin
            Check (HE'Length = 0, "empty hard labels length 0");
            Check (Canopy_Count_Of (RE) = 0, "empty Canopy_Count_Of");
         end;
      end;
   end;

   ---------------------------------------------------------------------
   Section ("13. Tight cluster absorbed; outlier separate");
   ---------------------------------------------------------------------
   declare
      Data : Dataset (1 .. 4, 1 .. 2);
      Params : constant Parameters := Make_Parameters (2.0, 1.0);
   begin
      Data (1, 1) := 0.0; Data (1, 2) := 0.0;
      Data (2, 1) := 0.2; Data (2, 2) := 0.1;
      Data (3, 1) := 0.1; Data (3, 2) := 0.3;
      Data (4, 1) := 20.0; Data (4, 2) := 0.0;
      declare
         R : constant Result := Run_Canopy (Data, Params);
         Outlier_Is_Center : Boolean := False;
      begin
         Check (R.C = 2, "tight+outlier: exactly 2 canopies");
         Check (R.Center_Ids (1) = 1, "tight+outlier: first center=1");
         for C in 1 .. Canopy_Index (R.C) loop
            if R.Center_Ids (C) = 4 then
               Outlier_Is_Center := True;
            end if;
         end loop;
         Check (Outlier_Is_Center, "outlier becomes a canopy center");
         Check (Point_In_Canopy (R, 2, 1)
                  and then Point_In_Canopy (R, 3, 1),
                "tight neighbors in canopy1");
         Check (not Point_In_Canopy (R, 4, 1), "outlier not in canopy1");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("14. Boundary: dist exactly T1 / T2 (strict <)");
   ---------------------------------------------------------------------
   declare
      Data : Dataset (1 .. 3, 1 .. 1);
      Params : constant Parameters := Make_Parameters (1.0, 0.5);
   begin
      Data (1, 1) := 0.0;
      Data (2, 1) := 1.0;
      Data (3, 1) := 0.5;
      declare
         R : constant Result := Run_Canopy (Data, Params);
      begin
         Check (R.Center_Ids (1) = 1, "boundary: center1=p1");
         Check (not Point_In_Canopy (R, 2, 1),
                "dist=T1 not assigned (strict <)");
         --  dist=T2=0.5 < T1=1.0 → assigned, but not removed from pool
         Check (Point_In_Canopy (R, 3, 1),
                "dist=T2 still assigned when T2 < T1");
         declare
            P3_Is_Center : Boolean := False;
         begin
            for C in 1 .. Canopy_Index (R.C) loop
               if R.Center_Ids (C) = 3 then
                  P3_Is_Center := True;
               end if;
            end loop;
            Check (P3_Is_Center,
                   "dist=T2 not removed → p3 can still center");
         end;
         Check (R.C = 3,
                "boundary equalities → three canopies");
      end;
   end;

   ---------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------
   New_Line;
   Put_Line ("=================================");
   Put_Line
     ("Passed:" & Pass_Count'Image & "  Failed:" & Fail_Count'Image);
   Put_Line ("=================================");
   pragma Assert (Fail_Count = 0);
   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;
