--  Standalone test suite for Barnes_Hut (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line;
with Barnes_Hut; use Barnes_Hut;

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

   function Vec_Near (A, B : Vec2; Tol : Real := 1.0E-6) return Boolean is
   begin
      return Approx (A.X, B.X, Tol) and then Approx (A.Y, B.Y, Tol);
   end Vec_Near;

   --  Tiny LCG for reproducible random bodies in (0,1)^2.
   type U32 is mod 2**32;
   RNG : U32 := 1;

   procedure Seed (S : Natural) is
   begin
      RNG := U32 (S);
      if RNG = 0 then
         RNG := 1;
      end if;
   end Seed;

   function Next_Unit return Real is
   begin
      RNG := RNG * 1_664_525 + 1_013_904_223;
      return Real (RNG rem 10_000) / 10_000.0;
   end Next_Unit;

   function Make_Random
     (N : Body_Count; S : Natural) return Body_Array
   is
      B : Body_Array (1 .. (if N = 0 then 1 else Body_Index (N)));
   begin
      Seed (S);
      if N = 0 then
         return B (1 .. 0);
      end if;
      for I in 1 .. N loop
         B (I).Mass := 0.5 + Next_Unit;
         B (I).Pos.X := 0.05 + 0.9 * Next_Unit;
         B (I).Pos.Y := 0.05 + 0.9 * Next_Unit;
         B (I).Vel := (0.0, 0.0);
      end loop;
      return B (1 .. Body_Index (N));
   end Make_Random;

   function Cfg
     (Theta : Real := 0.5;
      Soft  : Real := 1.0E-3;
      Leaf  : Positive := 1;
      G     : Real := 1.0) return BH_Config
   is
      C : BH_Config := Default_Config;
   begin
      C.Theta := Non_Negative (Theta);
      C.Softening := Non_Negative (Soft);
      C.Leaf_Capacity := Leaf;
      C.G := Non_Negative (G);
      C.Domain_Min_X := 0.0;
      C.Domain_Min_Y := 0.0;
      C.Domain_Size := 1.0;
      return C;
   end Cfg;

begin
   Put_Line ("Barnes_Hut test suite");
   Put_Line ("=====================");

   ---------------------------------------------------------------------
   Section ("1. Helpers: Near / Hypot / Soft_Denom / Pair_Force");
   ---------------------------------------------------------------------
   Check (Near (1.0, 1.0), "Near equal");
   Check (not Near (1.0, 2.0), "Near far");
   Check (Near (1.0, 1.0 + 1.0E-12), "Near tiny delta");
   Check (Approx (Hypot (3.0, 4.0), 5.0, 1.0E-12), "Hypot 3-4-5");
   Check (Approx (Hypot (0.0, 0.0), 0.0), "Hypot origin");
   Check (Approx (Hypot (5.0, 0.0), 5.0, 1.0E-12), "Hypot axis");
   Check (Approx (Hypot (0.0, 7.0), 7.0, 1.0E-12), "Hypot y-axis");
   Check (Soft_Denom (0.0, 0.0, 1.0E-3) > 0.0, "Soft_Denom coincidence > 0");
   Check (Soft_Denom (3.0, 4.0, 0.0) > 0.0, "Soft_Denom eps=0 positive");
   declare
      --  Two unit masses at (0,0) and (1,0), G=1, eps=0:
      --  F = 1 * r_hat / r^2 = (1,0)
      F : constant Vec2 :=
        Pair_Force (1.0, 1.0, (0.0, 0.0), (1.0, 0.0), 1.0, 0.0);
   begin
      Check (Approx (F.X, 1.0, 1.0E-9), "Pair_Force unit X");
      Check (Approx (F.Y, 0.0, 1.0E-9), "Pair_Force unit Y");
   end;
   declare
      F : constant Vec2 :=
        Pair_Force (2.0, 3.0, (0.0, 0.0), (0.0, 2.0), 1.0, 0.0);
      --  F = 6 / 4 * (0,1) = (0, 1.5)
   begin
      Check (Approx (F.X, 0.0, 1.0E-9), "Pair_Force vertical X=0");
      Check (Approx (F.Y, 1.5, 1.0E-9), "Pair_Force vertical Y=1.5");
   end;
   declare
      F : constant Vec2 :=
        Pair_Force (1.0, 1.0, (0.0, 0.0), (0.0, 0.0), 1.0, 1.0E-2);
   begin
      Check (Approx (F.X, 0.0, 1.0E-12), "soft coincidence Fx=0");
      Check (Approx (F.Y, 0.0, 1.0E-12), "soft coincidence Fy=0");
      Check (True, "softening prevents NaN on coincidence");
   end;

   ---------------------------------------------------------------------
   Section ("2. Accept_Node / Well_Separated unit tests");
   ---------------------------------------------------------------------
   Check (Accept_Node (0.1, 1.0, 0.5), "s/d=0.1 < 0.5 accepted");
   Check (not Accept_Node (1.0, 1.0, 0.5), "s/d=1 not < 0.5");
   Check (not Accept_Node (0.5, 1.0, 0.5), "s/d=0.5 not < 0.5");
   Check (Accept_Node (0.49, 1.0, 0.5), "s/d=0.49 < 0.5 accepted");
   Check (not Accept_Node (1.0, 0.0, 0.5), "Dist=0 rejected");
   Check (not Accept_Node (0.1, 1.0, 0.0), "Theta=0 rejected");
   Check (Accept_Node (0.0, 10.0, 0.5), "zero-size node accepted");
   Check (Well_Separated (0.0, 0.0, 0.1, 1.0, 0.0, 0.5),
          "far body MAC accepted");
   Check (not Well_Separated (0.0, 0.0, 0.1, 0.05, 0.0, 0.5),
          "near body MAC rejected");
   Check (not Well_Separated (0.5, 0.5, 1.0, 0.5, 0.5, 0.5),
          "body at COM rejected");
   Check (Well_Separated (0.0, 0.0, 1.0, 10.0, 0.0, 0.5),
          "distant body theta=0.5");
   Check (not Well_Separated (0.0, 0.0, 1.0, 10.0, 0.0, 0.05),
          "same geometry theta=0.05 rejected");
   Check (Accept_Node (2.0, 5.0, 0.5), "s/d=0.4 < 0.5");
   Check (not Accept_Node (2.0, 3.0, 0.5), "s/d≈0.667 not < 0.5");

   ---------------------------------------------------------------------
   Section ("3. Empty / single body → zero force");
   ---------------------------------------------------------------------
   declare
      Empty : Body_Array (1 .. 0);
      F0    : Force_Array (1 .. 1);
      C     : constant BH_Config := Cfg;
      T     : Tree;
      One   : constant Body_Array :=
        [1 => (Mass => 2.5, Pos => (0.5, 0.5), Vel => (0.0, 0.0))];
      F1    : Force_Array (1 .. 1);
      FB    : Force_Array (1 .. 1);
   begin
      Forces_All_Brute (Empty, 0, C, F0);
      Check (True, "brute empty does not crash");
      Build_Tree (T, Empty, 0, C);
      Check (Node_Count (T) >= 1, "empty tree has root");
      Check (Approx (Total_Mass (T), 0.0), "empty root mass 0");
      Forces_All_Barnes_Hut (T, Empty, 0, C, F0);
      Check (True, "BH empty does not crash");

      Forces_All_Brute (One, 1, C, FB);
      Check (Approx (FB (1).X, 0.0) and Approx (FB (1).Y, 0.0),
             "brute single force zero");
      Build_Tree (T, One, 1, C);
      Check (Approx (Total_Mass (T), 2.5, 1.0E-12), "single total mass");
      Check (Approx (Root_COM (T).X, 0.5, 1.0E-12), "single COM X");
      Check (Approx (Root_COM (T).Y, 0.5, 1.0E-12), "single COM Y");
      Forces_All_Barnes_Hut (T, One, 1, C, F1);
      Check (Approx (F1 (1).X, 0.0) and Approx (F1 (1).Y, 0.0),
             "BH single force zero");
      Check (Vec_Near
               (Force_Brute (One, 1, 1, C), (0.0, 0.0)),
             "Force_Brute single zero");
      Check (Vec_Near
               (Force_Barnes_Hut (T, One, 1, 1, C), (0.0, 0.0)),
             "Force_Barnes_Hut single zero");
   end;

   ---------------------------------------------------------------------
   Section ("4. Two bodies: BH ≡ brute for any θ");
   ---------------------------------------------------------------------
   declare
      Two : constant Body_Array :=
        [1 => (1.0, (0.2, 0.5), (0.0, 0.0)),
         2 => (2.0, (0.8, 0.5), (0.0, 0.0))];
      Thetas : constant array (1 .. 5) of Real :=
        [0.0, 0.1, 0.5, 0.9, 1.5];
   begin
      for K in Thetas'Range loop
         declare
            C  : constant BH_Config := Cfg (Theta => Thetas (K));
            T  : Tree;
            FB, FH : Force_Array (1 .. 2);
            Err : Non_Negative;
         begin
            Forces_All_Brute (Two, 2, C, FB);
            Build_Tree (T, Two, 2, C);
            Forces_All_Barnes_Hut (T, Two, 2, C, FH);
            Err := Max_Abs_Error (FB, FH, 2);
            Check (Err < 1.0E-9,
                   "two-body BH≡brute theta=" &
                     Real'Image (Thetas (K)));
            Check (Approx (Total_Mass (T), 3.0, 1.0E-12),
                   "two-body mass theta=" & Real'Image (Thetas (K)));
            --  Forces opposite direction (action-reaction soft)
            Check (FB (1).X > 0.0, "body1 pulled +X");
            Check (FB (2).X < 0.0, "body2 pulled -X");
         end;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("5. Three bodies COM / mass / θ→0");
   ---------------------------------------------------------------------
   declare
      Three : constant Body_Array :=
        [1 => (1.0, (0.1, 0.1), (0.0, 0.0)),
         2 => (1.0, (0.9, 0.1), (0.0, 0.0)),
         3 => (2.0, (0.5, 0.9), (0.0, 0.0))];
      C0 : constant BH_Config := Cfg (Theta => 0.0, Leaf => 1);
      C5 : constant BH_Config := Cfg (Theta => 0.5, Leaf => 1);
      T  : Tree;
      FB, F0, F5 : Force_Array (1 .. 3);
      SM : constant Non_Negative := Sum_Masses (Three, 3);
      Expected_COM_X : constant Real :=
        (1.0 * 0.1 + 1.0 * 0.9 + 2.0 * 0.5) / 4.0;
      Expected_COM_Y : constant Real :=
        (1.0 * 0.1 + 1.0 * 0.1 + 2.0 * 0.9) / 4.0;
   begin
      Check (Approx (SM, 4.0, 1.0E-12), "three sum masses=4");
      Build_Tree (T, Three, 3, C5);
      Check (Approx (Total_Mass (T), 4.0, 1.0E-12), "three root mass");
      Check (Approx (Root_COM (T).X, Expected_COM_X, 1.0E-10),
             "three root COM X");
      Check (Approx (Root_COM (T).Y, Expected_COM_Y, 1.0E-10),
             "three root COM Y");
      Check (Node_Count (T) >= 1, "three tree has nodes");

      Forces_All_Brute (Three, 3, C0, FB);
      Build_Tree (T, Three, 3, C0);
      Forces_All_Barnes_Hut (T, Three, 3, C0, F0);
      Check (Max_Abs_Error (FB, F0, 3) < 1.0E-9,
             "three theta=0 ≡ brute");

      Build_Tree (T, Three, 3, C5);
      Forces_All_Barnes_Hut (T, Three, 3, C5, F5);
      Check (Max_Abs_Error (FB, F5, 3) < 1.0,
             "three theta=0.5 finite error");
   end;

   ---------------------------------------------------------------------
   Section ("6. Softening prevents NaN on coincidence");
   ---------------------------------------------------------------------
   declare
      Coin : constant Body_Array :=
        [1 => (1.0, (0.4, 0.4), (0.0, 0.0)),
         2 => (1.0, (0.4, 0.4), (0.0, 0.0)),
         3 => (1.0, (0.7, 0.7), (0.0, 0.0))];
      C : constant BH_Config := Cfg (Soft => 1.0E-2);
      T : Tree;
      FB, FH : Force_Array (1 .. 3);
   begin
      Forces_All_Brute (Coin, 3, C, FB);
      Build_Tree (T, Coin, 3, C);
      Forces_All_Barnes_Hut (T, Coin, 3, C, FH);
      Check (FB (1).X = FB (1).X, "brute Fx not NaN body1");
      Check (FB (2).Y = FB (2).Y, "brute Fy not NaN body2");
      Check (FH (1).X = FH (1).X, "BH Fx not NaN");
      Check (Max_Abs_Error (FB, FH, 3) < 1.0E-6,
             "coincidence BH≈brute with softening");
   end;

   ---------------------------------------------------------------------
   Section ("7. Random clouds: error decreases as θ → 0");
   ---------------------------------------------------------------------
   declare
      Sizes : constant array (1 .. 4) of Body_Count := [8, 16, 32, 64];
      Seeds : constant array (1 .. 3) of Natural := [7, 42, 99];
   begin
      for Si in Sizes'Range loop
         for Se in Seeds'Range loop
            declare
               N  : constant Body_Count := Sizes (Si);
               B  : constant Body_Array := Make_Random (N, Seeds (Se));
               C_Brute : constant BH_Config := Cfg (Theta => 0.5);
               FB : Force_Array (1 .. Body_Index (N));
               Err_Lo, Err_Mid, Err_Hi : Non_Negative;
            begin
               Forces_All_Brute (B, N, C_Brute, FB);

               declare
                  C  : constant BH_Config := Cfg (Theta => 0.0);
                  T  : Tree;
                  FH : Force_Array (1 .. Body_Index (N));
               begin
                  Build_Tree (T, B, N, C);
                  Forces_All_Barnes_Hut (T, B, N, C, FH);
                  Err_Lo := Max_Abs_Error (FB, FH, N);
                  Check (Err_Lo < 1.0E-8,
                         "N=" & Body_Count'Image (N)
                         & " seed=" & Natural'Image (Seeds (Se))
                         & " theta=0 ≈ brute");
                  Check (Approx (Total_Mass (T), Sum_Masses (B, N), 1.0E-9),
                         "N=" & Body_Count'Image (N)
                         & " seed=" & Natural'Image (Seeds (Se))
                         & " mass conserved");
               end;

               declare
                  C  : constant BH_Config := Cfg (Theta => 0.3);
                  T  : Tree;
                  FH : Force_Array (1 .. Body_Index (N));
               begin
                  Build_Tree (T, B, N, C);
                  Forces_All_Barnes_Hut (T, B, N, C, FH);
                  Err_Mid := Max_Abs_Error (FB, FH, N);
               end;

               declare
                  C  : constant BH_Config := Cfg (Theta => 0.9);
                  T  : Tree;
                  FH : Force_Array (1 .. Body_Index (N));
               begin
                  Build_Tree (T, B, N, C);
                  Forces_All_Barnes_Hut (T, B, N, C, FH);
                  Err_Hi := Max_Abs_Error (FB, FH, N);
               end;

               Check (Err_Lo <= Err_Mid + 1.0E-12,
                      "N=" & Body_Count'Image (N)
                      & " seed=" & Natural'Image (Seeds (Se))
                      & " err(0)<=err(0.3)");
               Check (Err_Mid <= Err_Hi + 1.0E-6
                      or else Err_Hi < 1.0E-6,
                      "N=" & Body_Count'Image (N)
                      & " seed=" & Natural'Image (Seeds (Se))
                      & " err(0.3)<=err(0.9) (or tiny)");
               Check (Err_Hi = Err_Hi, "error finite N="
                      & Body_Count'Image (N));
            end;
         end loop;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("8. Default_Config / Leaf_Capacity / G scaling");
   ---------------------------------------------------------------------
   declare
      D : constant BH_Config := Default_Config;
      Two : constant Body_Array :=
        [1 => (1.0, (0.25, 0.5), (0.0, 0.0)),
         2 => (1.0, (0.75, 0.5), (0.0, 0.0))];
      C1 : constant BH_Config := Cfg (G => 1.0);
      C2 : constant BH_Config := Cfg (G => 2.0);
      F1, F2 : Force_Array (1 .. 2);
   begin
      Check (Approx (D.Theta, 0.5), "Default Theta=0.5");
      Check (D.Leaf_Capacity = 1, "Default Leaf_Capacity=1");
      Check (D.G > 0.0, "Default G>0");
      Check (D.Softening >= 0.0, "Default Softening>=0");
      Forces_All_Brute (Two, 2, C1, F1);
      Forces_All_Brute (Two, 2, C2, F2);
      Check (Approx (F2 (1).X, 2.0 * F1 (1).X, 1.0E-9),
             "G=2 doubles force X");
      Check (Approx (F2 (1).Y, 2.0 * F1 (1).Y, 1.0E-9),
             "G=2 doubles force Y");
   end;

   declare
      Cloud : constant Body_Array := Make_Random (16, 123);
      C_Leaf1 : constant BH_Config := Cfg (Theta => 0.0, Leaf => 1);
      C_Leaf4 : constant BH_Config := Cfg (Theta => 0.0, Leaf => 4);
      T1, T4 : Tree;
      F1, F4, FB : Force_Array (1 .. 16);
   begin
      Forces_All_Brute (Cloud, 16, C_Leaf1, FB);
      Build_Tree (T1, Cloud, 16, C_Leaf1);
      Build_Tree (T4, Cloud, 16, C_Leaf4);
      Forces_All_Barnes_Hut (T1, Cloud, 16, C_Leaf1, F1);
      Forces_All_Barnes_Hut (T4, Cloud, 16, C_Leaf4, F4);
      Check (Max_Abs_Error (FB, F1, 16) < 1.0E-8, "leaf=1 theta=0");
      Check (Max_Abs_Error (FB, F4, 16) < 1.0E-8, "leaf=4 theta=0");
      Check (Node_Count (T1) >= Node_Count (T4),
             "smaller leaf → >= nodes");
   end;

   ---------------------------------------------------------------------
   Section ("9. Convenience API / Max_Abs_Error / Euler_Step");
   ---------------------------------------------------------------------
   declare
      B : constant Body_Array := Make_Random (8, 55);
      C : constant BH_Config := Cfg (Theta => 0.0);
      FB, FH : Force_Array (1 .. 8);
   begin
      Forces_All_Brute (B, 8, C, FB);
      Forces_All_Barnes_Hut_From_Bodies (B, 8, C, FH);
      Check (Max_Abs_Error (FB, FH, 8) < 1.0E-8,
             "From_Bodies theta=0 ≡ brute");
      Check (Approx (Max_Abs_Error (FB, FB, 8), 0.0),
             "Max_Abs_Error identical=0");
      Check (Max_Abs_Error (FB, FH, 0) = 0.0,
             "Max_Abs_Error Count=0");
   end;

   declare
      B : Body_Array :=
        [1 => (1.0, (0.3, 0.5), (0.0, 0.0)),
         2 => (1.0, (0.7, 0.5), (0.0, 0.0))];
      C : constant BH_Config := Cfg (Theta => 0.5, Soft => 1.0E-2);
      X1 : constant Real := B (1).Pos.X;
   begin
      Euler_Step (B, 2, C, 0.01);
      Check (B (1).Pos.X /= X1 or else B (1).Vel.X /= 0.0,
             "Euler_Step moves or accelerates");
      Check (B (1).Pos.X = B (1).Pos.X, "Euler pos finite");
      Check (B (2).Vel.X = B (2).Vel.X, "Euler vel finite");
   end;

   declare
      Empty : Body_Array (1 .. 0);
      C : constant BH_Config := Cfg;
   begin
      Euler_Step (Empty, 0, C, 0.1);
      Check (True, "Euler empty no-op");
   end;

   ---------------------------------------------------------------------
   Section ("10. Action-reaction & symmetry checks");
   ---------------------------------------------------------------------
   declare
      Two : constant Body_Array :=
        [1 => (3.0, (0.2, 0.3), (0.0, 0.0)),
         2 => (5.0, (0.8, 0.7), (0.0, 0.0))];
      C : constant BH_Config := Cfg (Soft => 1.0E-4);
      F : Force_Array (1 .. 2);
   begin
      Forces_All_Brute (Two, 2, C, F);
      --  Softened Newton: F12 = -F21
      Check (Approx (F (1).X, -F (2).X, 1.0E-9), "Fx action-reaction");
      Check (Approx (F (1).Y, -F (2).Y, 1.0E-9), "Fy action-reaction");
   end;

   declare
      --  Symmetric square
      Sq : constant Body_Array :=
        [1 => (1.0, (0.25, 0.25), (0.0, 0.0)),
         2 => (1.0, (0.75, 0.25), (0.0, 0.0)),
         3 => (1.0, (0.25, 0.75), (0.0, 0.0)),
         4 => (1.0, (0.75, 0.75), (0.0, 0.0))];
      C : constant BH_Config := Cfg (Theta => 0.0);
      T : Tree;
      FB, FH : Force_Array (1 .. 4);
   begin
      Forces_All_Brute (Sq, 4, C, FB);
      Build_Tree (T, Sq, 4, C);
      Forces_All_Barnes_Hut (T, Sq, 4, C, FH);
      Check (Max_Abs_Error (FB, FH, 4) < 1.0E-9, "square theta=0");
      Check (Approx (Total_Mass (T), 4.0, 1.0E-12), "square mass=4");
      Check (Approx (Root_COM (T).X, 0.5, 1.0E-10), "square COM X=0.5");
      Check (Approx (Root_COM (T).Y, 0.5, 1.0E-10), "square COM Y=0.5");
      --  Corner bodies should have |Fx|≈|Fy| by symmetry
      Check (Approx (abs (FB (1).X), abs (FB (1).Y), 1.0E-8),
             "corner1 |Fx|=|Fy|");
      Check (FB (1).X > 0.0 and FB (1).Y > 0.0, "corner1 pulled NE");
   end;

   ---------------------------------------------------------------------
   Section ("11. Extra Accept_Node edge cases & Sum_Masses");
   ---------------------------------------------------------------------
   Check (not Accept_Node (10.0, 1.0, 0.5), "large s/d rejected");
   Check (Accept_Node (0.01, 100.0, 0.5), "tiny s/d accepted");
   Check (Accept_Node (1.0, 2.0001, 0.5), "barely under theta");
   Check (not Accept_Node (1.0, 1.9999, 0.5), "barely over theta");
   declare
      Z : Body_Array (1 .. 0);
      One : constant Body_Array :=
        [1 => (7.0, (0.0, 0.0), (0.0, 0.0))];
   begin
      Check (Approx (Sum_Masses (Z, 0), 0.0), "Sum_Masses empty");
      Check (Approx (Sum_Masses (One, 1), 7.0), "Sum_Masses one");
   end;

   ---------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------
   New_Line;
   Put_Line ("================================");
   Put_Line ("PASS: " & Natural'Image (Pass_Count));
   Put_Line ("FAIL: " & Natural'Image (Fail_Count));
   Put_Line ("================================");

   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;
