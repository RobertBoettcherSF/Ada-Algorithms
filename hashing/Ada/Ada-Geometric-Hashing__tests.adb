--  Standalone test suite for Geometric_Hashing (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Numerics;
with Ada.Numerics.Long_Elementary_Functions;
with Ada.Text_IO;
with Geometric_Hashing; use Geometric_Hashing;

procedure Tests is

   package Math renames Ada.Numerics.Long_Elementary_Functions;

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check
     (Condition : Boolean;
      Message   : String)
   is
   begin
      if Condition then
         Pass_Count := Pass_Count + 1;
         Ada.Text_IO.Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Ada.Text_IO.Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      Ada.Text_IO.New_Line;
      Ada.Text_IO.Put_Line ("=== " & Title & " ===");
   end Section;

   --  Non-static views (avoid -gnatwc constant-condition warnings).
   function R (X : Real) return Real is (X);
   function Pos (X : Positive) return Positive is (X);
   function Nat (X : Natural) return Natural is (X);
   function P (X, Y : Real) return Point is ((X => X, Y => Y));

   Pi : constant Real := Real (Ada.Numerics.Pi);

   function Rotate_About
     (Q : Point; Angle : Real; Center : Point := (0.0, 0.0)) return Point
   is
      C  : constant Real := Real (Math.Cos (Long_Float (Angle)));
      S  : constant Real := Real (Math.Sin (Long_Float (Angle)));
      Dx : constant Real := Q.X - Center.X;
      Dy : constant Real := Q.Y - Center.Y;
   begin
      return
        (X => Center.X + C * Dx - S * Dy,
         Y => Center.Y + S * Dx + C * Dy);
   end Rotate_About;

   function Translate (Q : Point; T : Point) return Point is
     ((X => Q.X + T.X, Y => Q.Y + T.Y));

   function Transform_Cloud
     (Cloud  : Point_Array;
      Angle  : Real;
      Offset : Point) return Point_Array
   is
      Out_C : Point_Array (Cloud'Range);
   begin
      for I in Cloud'Range loop
         Out_C (I) := Translate (Rotate_About (Cloud (I), Angle), Offset);
      end loop;
      return Out_C;
   end Transform_Cloud;

   function Raised_Invalid_Build (Cloud : Point_Array) return Boolean is
      T : Hash_Table;
   begin
      T := Build_Table (Cloud);
      pragma Unreferenced (T);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_Build;

   function Raised_Invalid_Recognize
     (Scene : Point_Array; Table : Hash_Table) return Boolean
   is
      Res : Recognition_Result;
   begin
      Res := Recognize (Scene, Table);
      pragma Unreferenced (Res);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_Recognize;

   function Raised_Invalid_Quantize (Bin : Real) return Boolean is
      K : Hash_Key;
   begin
      K := Quantize (P (0.0, 0.0), Bin);
      pragma Unreferenced (K);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_Quantize;

   function Raised_Invalid_Empty_Table (Bin : Real) return Boolean is
      T : Hash_Table;
   begin
      T := Empty_Table (Bin);
      pragma Unreferenced (T);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_Empty_Table;

   --  Small models
   Triangle : constant Point_Array :=
     [P (0.0, 0.0), P (4.0, 0.0), P (1.0, 3.0)];

   Quad : constant Point_Array :=
     [P (0.0, 0.0), P (5.0, 0.0), P (5.0, 4.0), P (0.0, 3.0)];

   Pentagon : constant Point_Array :=
     [P (0.0, 0.0), P (6.0, 0.0), P (7.0, 4.0), P (3.0, 6.0), P (-1.0, 3.0)];

begin
   Ada.Text_IO.Put_Line ("Geometric_Hashing tests");
   Ada.Text_IO.Put_Line ("=======================");

   ------------------------------------------------------------------
   Section ("1. Near / Near_Point / Dist");
   ------------------------------------------------------------------
   Check (Near (R (1.0), R (1.0)), "Near equal");
   Check (Near (R (1.0), R (1.0 + 1.0E-12)), "Near within eps");
   Check (not Near (R (0.0), R (1.0)), "not Near 0,1");
   Check (Near_Point (P (0.0, 0.0), P (0.0, 0.0)), "Near_Point identical");
   Check (not Near_Point (P (0.0, 0.0), P (1.0, 0.0)), "not Near_Point");
   Check (Near (R (2.0), R (2.0), R (0.0)), "Near exact Tol=0");
   Check (not Near (R (2.0), R (2.1), R (0.05)), "not Near outside Tol");
   Check (Near (Dist2 (P (0.0, 0.0), P (3.0, 4.0)), R (25.0)),
          "Dist2 3-4-5 = 25");
   Check (Near (Dist (P (0.0, 0.0), P (3.0, 4.0)), R (5.0)),
          "Dist 3-4-5 = 5");
   Check (Near (Dist2 (P (1.0, 1.0), P (1.0, 1.0)), R (0.0)),
          "Dist2 identical = 0");

   ------------------------------------------------------------------
   Section ("2. Make_Basis / To_Basis_Coords");
   ------------------------------------------------------------------
   declare
      A : constant Point := P (0.0, 0.0);
      B : constant Point := P (4.0, 0.0);
      Fr : constant Basis := Make_Basis (A, B);
      Mid : constant Point := To_Basis_Coords (P (2.0, 0.0), Fr);
      CA  : constant Point := To_Basis_Coords (A, Fr);
      CB  : constant Point := To_Basis_Coords (B, Fr);
      Up  : constant Point := To_Basis_Coords (P (2.0, 2.0), Fr);
      Deg : constant Basis := Make_Basis (A, A);
   begin
      Check (Fr.Valid, "horizontal basis Valid");
      Check (Near_Point (CA, P (-1.0, 0.0), R (1.0E-9)),
             "A maps to (-1,0)");
      Check (Near_Point (CB, P (1.0, 0.0), R (1.0E-9)),
             "B maps to (+1,0)");
      Check (Near_Point (Mid, P (0.0, 0.0), R (1.0E-9)),
             "midpoint maps to (0,0)");
      Check (Near (Fr.Scale, R (2.0)), "scale = half length = 2");
      Check (Near_Point (Up, P (0.0, 1.0), R (1.0E-9)),
             "point above midpoint → (0,1)");
      Check (not Deg.Valid, "coincident points → invalid basis");
      Check (Near_Point (To_Basis_Coords (P (9.0, 9.0), Deg),
                         P (0.0, 0.0)),
             "invalid basis coords → (0,0)");
   end;

   declare
      A : constant Point := P (1.0, 1.0);
      B : constant Point := P (1.0, 5.0);
      Fr : constant Basis := Make_Basis (A, B);
      CA : constant Point := To_Basis_Coords (A, Fr);
      CB : constant Point := To_Basis_Coords (B, Fr);
      Right : constant Point := To_Basis_Coords (P (3.0, 3.0), Fr);
   begin
      Check (Fr.Valid, "vertical basis Valid");
      Check (Near_Point (CA, P (-1.0, 0.0), R (1.0E-9)),
             "vertical A → (-1,0)");
      Check (Near_Point (CB, P (1.0, 0.0), R (1.0E-9)),
             "vertical B → (+1,0)");
      --  Midpoint (1,3); right of upward axis → +y' after 90° CCW of up?
      --  Ux = (0,1), Uy = (-1,0); P(3,3)-O(1,3)=(2,0)
      --  u = (2,0)·(0,1)/2 = 0; v = (2,0)·(-1,0)/2 = -1
      Check (Near_Point (Right, P (0.0, -1.0), R (1.0E-9)),
             "right of vertical basis → (0,-1)");
   end;

   ------------------------------------------------------------------
   Section ("3. Quantize / Same_Key");
   ------------------------------------------------------------------
   declare
      K1 : constant Hash_Key := Quantize (P (0.0, 0.0));
      K2 : constant Hash_Key := Quantize (P (0.24, -0.24));
      K3 : constant Hash_Key := Quantize (P (0.13, 0.13));
      K4 : constant Hash_Key := Quantize (P (1.0, -0.5), R (0.25));
   begin
      Check (K1.U = 0 and then K1.V = 0, "quantize origin → (0,0)");
      Check (K2.U = 1 and then K2.V = -1,
             "0.24/0.25 rounds to 1; -0.24 → -1");
      Check (K3.U = 1 and then K3.V = 1,
             "0.13/0.25 = 0.52 → rounds to 1");
      Check (K4.U = 4 and then K4.V = -2, "1.0/0.25=4; -0.5/0.25=-2");
      Check (Same_Key (K1, Quantize (P (0.0, 0.0))), "Same_Key equal");
      Check (not Same_Key (K1, K4), "not Same_Key distinct");
      Check (Raised_Invalid_Quantize (R (0.0)), "Bin_Size=0 raises");
      Check (Raised_Invalid_Quantize (R (-0.1)), "Bin_Size<0 raises");
   end;

   ------------------------------------------------------------------
   Section ("4. Build_Table counts / Lookup");
   ------------------------------------------------------------------
   declare
      T3 : constant Hash_Table := Build_Table (Triangle);
      T4 : constant Hash_Table := Build_Table (Quad);
      T5 : constant Hash_Table := Build_Table (Pentagon, Model_Id => 7);
      --  Triangle: 3*2*1 = 6 entries (all bases non-degenerate).
      --  Quad: 4*3*2 = 24.
      --  Pentagon: 5*4*3 = 60.
   begin
      Check (Entry_Length (T3) = 6, "triangle table has 6 entries");
      Check (Entry_Length (T4) = 24, "quad table has 24 entries");
      Check (Entry_Length (T5) = 60, "pentagon table has 60 entries");
      Check (T3.Bin_Size = Default_Bin_Size, "default bin size stored");
      Check (T5.Entries (1).Model_Id = 7, "custom Model_Id stored");
      Check (Lookup_Count (T3, T3.Entries (1).Key) >= 1,
             "Lookup_Count ≥ 1 for first key");
      Check (Entry_Length (Empty_Table) = 0, "Empty_Table length 0");
   end;

   ------------------------------------------------------------------
   Section ("5. Invalid_Argument guards");
   ------------------------------------------------------------------
   declare
      Empty : Point_Array (1 .. 0);
      One   : constant Point_Array := [P (0.0, 0.0)];
      Two   : constant Point_Array := [P (0.0, 0.0), P (1.0, 0.0)];
      Ok    : constant Hash_Table := Build_Table (Triangle);
   begin
      Check (Raised_Invalid_Build (Empty), "empty model raises");
      Check (Raised_Invalid_Build (One), "1-point model raises");
      Check (Raised_Invalid_Build (Two), "2-point model raises");
      Check (Raised_Invalid_Recognize (Empty, Ok), "empty scene raises");
      Check (Raised_Invalid_Recognize (One, Ok), "1-point scene raises");
      Check (Raised_Invalid_Recognize (Two, Ok), "2-point scene raises");
      Check (Raised_Invalid_Recognize (Triangle, Empty_Table),
             "empty table raises on Recognize");
      Check (Raised_Invalid_Empty_Table (R (0.0)),
             "Empty_Table Bin_Size=0 raises");
      Check (Raised_Invalid_Build (Triangle) = False,
             "valid triangle Build does not raise");
   end;

   ------------------------------------------------------------------
   Section ("6. Identity recognition (triangle / quad)");
   ------------------------------------------------------------------
   declare
      T3  : constant Hash_Table := Build_Table (Triangle);
      T4  : constant Hash_Table := Build_Table (Quad);
      R3  : constant Recognition_Result :=
        Recognize (Triangle, T3, Min_Votes => 1);
      R4  : constant Recognition_Result :=
        Recognize (Quad, T4, Min_Votes => 2);
   begin
      Check (R3.Found, "identity triangle Found");
      Check (R3.Model_Id = 1, "identity triangle Model_Id=1");
      Check (R3.Vote_Count >= 1, "identity triangle votes ≥ 1");
      Check (R4.Found, "identity quad Found");
      Check (R4.Vote_Count >= 2, "identity quad votes ≥ 2");
      Check (R4.Model_Id = 1, "identity quad Model_Id=1");
   end;

   ------------------------------------------------------------------
   Section ("7. Translated triangle / quad");
   ------------------------------------------------------------------
   declare
      Offset : constant Point := P (10.0, -7.5);
      Scene3 : constant Point_Array :=
        Transform_Cloud (Triangle, R (0.0), Offset);
      Scene4 : constant Point_Array :=
        Transform_Cloud (Quad, R (0.0), Offset);
      T3 : constant Hash_Table := Build_Table (Triangle);
      T4 : constant Hash_Table := Build_Table (Quad);
      R3 : constant Recognition_Result :=
        Recognize (Scene3, T3, Min_Votes => 1);
      R4 : constant Recognition_Result :=
        Recognize (Scene4, T4, Min_Votes => 2);
   begin
      Check (R3.Found, "translated triangle Found");
      Check (R3.Vote_Count >= 1, "translated triangle votes ≥ 1");
      Check (R4.Found, "translated quad Found");
      Check (R4.Vote_Count >= 2, "translated quad votes ≥ 2");
      Check (R4.Model_Id = 1, "translated quad Model_Id");
   end;

   ------------------------------------------------------------------
   Section ("8. Rotated recognition");
   ------------------------------------------------------------------
   declare
      Ang : constant Real := Pi / 6.0;  -- 30°
      Scene4 : constant Point_Array :=
        Transform_Cloud (Quad, Ang, P (0.0, 0.0));
      Scene5 : constant Point_Array :=
        Transform_Cloud (Pentagon, Ang, P (0.0, 0.0));
      T4 : constant Hash_Table := Build_Table (Quad);
      T5 : constant Hash_Table := Build_Table (Pentagon, Model_Id => 3);
      R4 : constant Recognition_Result :=
        Recognize (Scene4, T4, Min_Votes => 2);
      R5 : constant Recognition_Result :=
        Recognize (Scene5, T5, Min_Votes => 2);
   begin
      Check (R4.Found, "rotated quad Found");
      Check (R4.Vote_Count >= 2, "rotated quad high votes");
      Check (R5.Found, "rotated pentagon Found");
      Check (R5.Vote_Count >= 2, "rotated pentagon votes ≥ 2");
      Check (R5.Model_Id = 3, "rotated pentagon Model_Id=3");
   end;

   ------------------------------------------------------------------
   Section ("9. Rotate + translate (similarity pose)");
   ------------------------------------------------------------------
   declare
      Ang    : constant Real := Pi / 4.0;  -- 45°
      Offset : constant Point := P (-3.5, 8.0);
      Scene4 : constant Point_Array :=
        Transform_Cloud (Quad, Ang, Offset);
      Scene5 : constant Point_Array :=
        Transform_Cloud (Pentagon, Ang, Offset);
      T4 : constant Hash_Table := Build_Table (Quad);
      T5 : constant Hash_Table := Build_Table (Pentagon);
      R4 : constant Recognition_Result :=
        Recognize (Scene4, T4, Min_Votes => 2);
      R5 : constant Recognition_Result :=
        Recognize (Scene5, T5, Min_Votes => 3);
   begin
      Check (R4.Found, "rigid-pose quad Found");
      Check (R4.Vote_Count >= 2, "rigid-pose quad votes ≥ 2");
      Check (R5.Found, "rigid-pose pentagon Found");
      Check (R5.Vote_Count >= 3, "rigid-pose pentagon votes ≥ 3");
      Check (R5.Model_Id = 1, "rigid-pose Model_Id=1");
      Check (R4.Scene_Basis.I /= R4.Scene_Basis.J,
             "scene basis indices distinct");
      Check (R4.Model_Basis.I /= R4.Model_Basis.J,
             "model basis indices distinct");
   end;

   ------------------------------------------------------------------
   Section ("10. Quantize_Point consistency");
   ------------------------------------------------------------------
   declare
      Fr : constant Basis := Make_Basis (P (0.0, 0.0), P (2.0, 0.0));
      K  : constant Hash_Key :=
        Quantize_Point (P (1.0, 0.5), Fr, R (0.25));
      UV : constant Point := To_Basis_Coords (P (1.0, 0.5), Fr);
      --  Mid=(1,0); P-Mid=(0,0.5); scale=1; u=0, v=0.5 → bins (0,2)
   begin
      Check (Fr.Valid, "Quantize_Point basis valid");
      Check (Near (UV.X, R (0.0)) and then Near (UV.Y, R (0.5)),
             "UV = (0, 0.5)");
      Check (K.U = 0 and then K.V = 2, "Quantize_Point → (0,2)");
   end;

   ------------------------------------------------------------------
   Section ("11. Unrelated scene / high Min_Votes");
   ------------------------------------------------------------------
   declare
      Noise : constant Point_Array :=
        [P (100.0, 100.0), P (110.0, 100.0), P (105.0, 108.0),
         P (102.0, 103.0)];
      --  Similar shape but different relative geometry vs Quad.
      Other : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0), P (0.5, 0.1), P (0.2, 0.8)];
      T4 : constant Hash_Table := Build_Table (Quad);
      Rn : constant Recognition_Result :=
        Recognize (Noise, T4, Min_Votes => 50);
      Ro : constant Recognition_Result :=
        Recognize (Other, T4, Min_Votes => 10);
   begin
      Check (not Rn.Found, "absurd Min_Votes → not Found");
      Check (not Ro.Found or else Ro.Vote_Count < 10,
             "dissimilar shape fails high threshold");
      Check (Pos (Max_Points) = 24, "Max_Points = 24");
      Check (Nat (Max_Entries) = 12_288, "Max_Entries = 12288");
      Check (Near (Default_Bin_Size, R (0.25)), "Default_Bin_Size=0.25");
   end;

   ------------------------------------------------------------------
   Section ("12. Basis_Pair / multi-basis vote strength");
   ------------------------------------------------------------------
   declare
      T5 : constant Hash_Table := Build_Table (Pentagon);
      Scene : constant Point_Array :=
        Transform_Cloud (Pentagon, Pi / 3.0, P (2.0, -4.0));
      Res : constant Recognition_Result :=
        Recognize (Scene, T5, Min_Votes => 2);
   begin
      Check (Res.Found, "60°+translate pentagon Found");
      Check (Res.Vote_Count >= 2, "pentagon votes ≥ 2");
      --  Remaining points per basis = 3 for pentagon → strong peak.
      Check (Res.Vote_Count >= 3 or else Res.Vote_Count = 2,
             "vote count in expected band");
      Check (Res.Model_Basis.I <= Pentagon'Last
             and then Res.Model_Basis.J <= Pentagon'Last,
             "model basis within pentagon");
      Check (Res.Scene_Basis.I >= Scene'First
             and then Res.Scene_Basis.J <= Scene'Last,
             "scene basis indices in range");
   end;

   ------------------------------------------------------------------
   Section ("13. Capacity / constants smoke");
   ------------------------------------------------------------------
   declare
      Big : Point_Array (1 .. 8);
      Tb  : Hash_Table;
      --  8*7*6 = 336 entries.
   begin
      for I in Big'Range loop
         Big (I) :=
           P (Real (I), Real (I * I) * 0.1);
      end loop;
      Tb := Build_Table (Big, Model_Id => 99);
      Check (Entry_Length (Tb) = 336, "8-point model → 336 entries");
      Check (Tb.Entries (1).Model_Id = 99, "Model_Id 99 stored");
      declare
         Sc : constant Point_Array :=
           Transform_Cloud (Big, R (0.2), P (1.0, 1.0));
         Rr : constant Recognition_Result :=
           Recognize (Sc, Tb, Min_Votes => 4);
      begin
         Check (Rr.Found, "8-point rigid pose Found");
         Check (Rr.Vote_Count >= 4, "8-point votes ≥ 4");
         Check (Rr.Model_Id = 99, "8-point Model_Id=99");
      end;
   end;

   ------------------------------------------------------------------
   -- Summary
   ------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line
     ("Results: "
      & Natural'Image (Pass_Count)
      & " PASS,"
      & Natural'Image (Fail_Count)
      & " FAIL");

   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;
