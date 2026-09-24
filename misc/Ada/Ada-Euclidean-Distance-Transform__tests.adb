--  Standalone test suite for Euclidean_Distance_Transform (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Numerics.Long_Elementary_Functions;
with Ada.Text_IO;
with Euclidean_Distance_Transform; use Euclidean_Distance_Transform;

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
   function Nat (X : Natural) return Natural is (X);
   function Pos (X : Positive) return Positive is (X);
   function B (X : Boolean) return Boolean is (X);

   ------------------------------------------------------------------
   -- Fixtures
   ------------------------------------------------------------------

   function Blank (H, W : Positive) return Binary_Image is
     ([1 .. H => [1 .. W => False]]);

   function Single_Feature
     (H, W : Positive; Fr, Fc : Positive) return Binary_Image
   is
      Img : Binary_Image := Blank (H, W);
   begin
      Img (Fr, Fc) := True;
      return Img;
   end Single_Feature;

   function Horizontal_Line
     (H, W : Positive; Row : Positive) return Binary_Image
   is
      Img : Binary_Image := Blank (H, W);
   begin
      for C in Img'Range (2) loop
         Img (Row, C) := True;
      end loop;
      return Img;
   end Horizontal_Line;

   function Square_Blob
     (H, W : Positive;
      R0, C0, R1, C1 : Positive) return Binary_Image
   is
      Img : Binary_Image := Blank (H, W);
   begin
      for Rr in R0 .. R1 loop
         for Cc in C0 .. C1 loop
            Img (Rr, Cc) := True;
         end loop;
      end loop;
      return Img;
   end Square_Blob;

   --  Independent brute-force squared EDT (test oracle).
   function Brute_Squared (Image : Binary_Image) return Squared_Distance_Map is
      Result : Squared_Distance_Map (Image'Range (1), Image'Range (2));
      Best   : Natural;
      Dr, Dc : Integer;
      Cand   : Natural;
      Inf    : constant Natural := 10_000_000;
   begin
      for Rr in Image'Range (1) loop
         for Cc in Image'Range (2) loop
            Best := Inf;
            for Fr in Image'Range (1) loop
               for Fc in Image'Range (2) loop
                  if Image (Fr, Fc) then
                     Dr := Integer (Rr) - Integer (Fr);
                     Dc := Integer (Cc) - Integer (Fc);
                     Cand := Natural (Dr * Dr + Dc * Dc);
                     if Cand < Best then
                        Best := Cand;
                     end if;
                  end if;
               end loop;
            end loop;
            Result (Rr, Cc) := Best;
         end loop;
      end loop;
      return Result;
   end Brute_Squared;

   function Maps_Equal
     (A, B : Squared_Distance_Map) return Boolean
   is
   begin
      if A'First (1) /= B'First (1) or else A'Last (1) /= B'Last (1)
        or else A'First (2) /= B'First (2) or else A'Last (2) /= B'Last (2)
      then
         return False;
      end if;
      for Rr in A'Range (1) loop
         for Cc in A'Range (2) loop
            if A (Rr, Cc) /= B (Rr, Cc) then
               return False;
            end if;
         end loop;
      end loop;
      return True;
   end Maps_Equal;

   function Raised_Invalid_DT (Image : Binary_Image) return Boolean is
      M : Distance_Map (1 .. 1, 1 .. 1);
   begin
      M := Distance_Transform (Image);
      pragma Unreferenced (M);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_DT;

   function Raised_Invalid_Sq (Image : Binary_Image) return Boolean is
      M : Squared_Distance_Map (1 .. 1, 1 .. 1);
   begin
      M := Squared_Distance_Transform (Image);
      pragma Unreferenced (M);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_Sq;

   function Raised_Invalid_Meijster (Image : Binary_Image) return Boolean is
      M : Squared_Distance_Map (1 .. 1, 1 .. 1);
   begin
      M := Meijster_Squared_Distance_Transform (Image);
      pragma Unreferenced (M);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_Meijster;

   function Raised_Invalid_Chamfer (Image : Binary_Image) return Boolean is
      M : Distance_Map (1 .. 1, 1 .. 1);
   begin
      M := Chamfer_Distance_Transform (Image);
      pragma Unreferenced (M);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_Chamfer;

   function Raised_Invalid_At_Dist
     (Map : Distance_Map; Row, Col : Positive) return Boolean
   is
      V : Real;
   begin
      V := Distance_At (Map, Row, Col);
      pragma Unreferenced (V);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_At_Dist;

   function Raised_Invalid_At_Sq
     (Map : Squared_Distance_Map; Row, Col : Positive) return Boolean
   is
      V : Natural;
   begin
      V := Squared_Distance_At (Map, Row, Col);
      pragma Unreferenced (V);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_At_Sq;

begin
   Ada.Text_IO.Put_Line ("Euclidean_Distance_Transform tests");
   Ada.Text_IO.Put_Line ("==================================");

   ------------------------------------------------------------------
   Section ("1. Near / helpers / capacities");
   ------------------------------------------------------------------
   Check (Near (R (1.0), R (1.0)), "Near equal");
   Check (Near (R (1.0), R (1.0 + 1.0E-12)), "Near within eps");
   Check (not Near (R (0.0), R (1.0)), "not Near 0,1");
   Check (Max_Width = Pos (64), "Max_Width = 64");
   Check (Max_Height = Pos (64), "Max_Height = 64");
   Check (Chamfer_Ortho = Nat (3), "Chamfer_Ortho = 3");
   Check (Chamfer_Diagonal = Nat (4), "Chamfer_Diagonal = 4");

   declare
      Img : constant Binary_Image := Single_Feature (3, 4, 2, 3);
   begin
      Check (Width_Of (Img) = Nat (4), "Width_Of = 4");
      Check (Height_Of (Img) = Nat (3), "Height_Of = 3");
      Check (Has_Feature (Img), "Has_Feature single");
      Check (Feature_Count (Img) = Nat (1), "Feature_Count = 1");
      Check (not Has_Feature (Blank (2, 2)), "no feature on blank");
      Check (Feature_Count (Blank (2, 2)) = Nat (0), "Feature_Count blank=0");
   end;

   ------------------------------------------------------------------
   Section ("2. Invalid_Argument (empty / featureless)");
   ------------------------------------------------------------------
   declare
      Empty_H : Binary_Image (1 .. 0, 1 .. 3);
      Empty_W : Binary_Image (1 .. 3, 1 .. 0);
      No_Feat : constant Binary_Image := Blank (3, 3);
   begin
      Check (Raised_Invalid_DT (Empty_H), "DT empty height");
      Check (Raised_Invalid_DT (Empty_W), "DT empty width");
      Check (Raised_Invalid_DT (No_Feat), "DT featureless");
      Check (Raised_Invalid_Sq (No_Feat), "Sq featureless");
      Check (Raised_Invalid_Meijster (No_Feat), "Meijster featureless");
      Check (Raised_Invalid_Chamfer (No_Feat), "Chamfer featureless");
      Check (Raised_Invalid_Sq (Empty_H), "Sq empty height");
      Check (Raised_Invalid_Meijster (Empty_W), "Meijster empty width");
   end;

   ------------------------------------------------------------------
   Section ("3. Single feature — exact distances");
   ------------------------------------------------------------------
   declare
      Img : constant Binary_Image := Single_Feature (5, 5, 3, 3);
      Sq  : constant Squared_Distance_Map :=
        Squared_Distance_Transform (Img);
      Dt  : constant Distance_Map := Distance_Transform (Img);
      Br  : constant Squared_Distance_Map := Brute_Squared (Img);
   begin
      Check (Maps_Equal (Sq, Br), "single vs brute squared");
      Check (Squared_Distance_At (Sq, 3, 3) = Nat (0), "feature sq=0");
      Check (Near (Distance_At (Dt, 3, 3), R (0.0)), "feature dist=0");
      Check (Squared_Distance_At (Sq, 3, 4) = Nat (1), "ortho neighbor sq=1");
      Check (Near (Distance_At (Dt, 3, 4), R (1.0)), "ortho neighbor dist=1");
      Check (Squared_Distance_At (Sq, 4, 4) = Nat (2), "diag neighbor sq=2");
      Check
        (Near
           (Distance_At (Dt, 4, 4),
            Real (Math.Sqrt (2.0))),
         "diag neighbor dist=√2");
      Check (Squared_Distance_At (Sq, 1, 1) = Nat (8), "corner sq=(2²+2²)=8");
      Check
        (Near
           (Distance_At (Dt, 1, 1),
            Real (Math.Sqrt (8.0))),
         "corner dist=√8");
      Check (Raised_Invalid_At_Dist (Dt, Pos (9), Pos (1)), "Distance_At OOB");
      Check (Raised_Invalid_At_Sq (Sq, Pos (1), Pos (9)), "Sq_At OOB");
   end;

   ------------------------------------------------------------------
   Section ("4. Horizontal line feature");
   ------------------------------------------------------------------
   declare
      Img : constant Binary_Image := Horizontal_Line (5, 6, 3);
      Sq  : constant Squared_Distance_Map :=
        Squared_Distance_Transform (Img);
      Dt  : constant Distance_Map := Distance_Transform (Img);
      Br  : constant Squared_Distance_Map := Brute_Squared (Img);
   begin
      Check (Maps_equal (Sq, Br), "line vs brute");
      Check (Feature_Count (Img) = Nat (6), "line Feature_Count=6");
      Check (Squared_Distance_At (Sq, 3, 1) = Nat (0), "on-line sq=0");
      Check (Squared_Distance_At (Sq, 3, 6) = Nat (0), "on-line end sq=0");
      Check (Squared_Distance_At (Sq, 2, 3) = Nat (1), "above line sq=1");
      Check (Squared_Distance_At (Sq, 1, 4) = Nat (4), "two above sq=4");
      Check (Squared_Distance_At (Sq, 5, 2) = Nat (4), "two below sq=4");
      Check (Near (Distance_At (Dt, 1, 1), R (2.0)), "two above dist=2");
   end;

   ------------------------------------------------------------------
   Section ("5. Square blob");
   ------------------------------------------------------------------
   declare
      Img : constant Binary_Image := Square_Blob (6, 6, 2, 2, 4, 4);
      Sq  : constant Squared_Distance_Map :=
        Squared_Distance_Transform (Img);
      Dt  : constant Distance_Map := Distance_Transform (Img);
      Br  : constant Squared_Distance_Map := Brute_Squared (Img);
      Mj  : constant Squared_Distance_Map :=
        Meijster_Squared_Distance_Transform (Img);
   begin
      Check (Maps_equal (Sq, Br), "blob vs brute");
      Check (Maps_equal (Sq, Mj), "blob naive=Meijster");
      Check (Feature_Count (Img) = Nat (9), "3×3 blob Feature_Count=9");
      Check (Squared_Distance_At (Sq, 3, 3) = Nat (0), "blob interior 0");
      Check (Squared_Distance_At (Sq, 2, 2) = Nat (0), "blob corner feature 0");
      Check (Squared_Distance_At (Sq, 1, 1) = Nat (2), "outside diag sq=2");
      Check (Squared_Distance_At (Sq, 1, 3) = Nat (1), "outside ortho sq=1");
      Check (Squared_Distance_At (Sq, 6, 6) = Nat (8), "far corner sq=8");
      Check (Near (Distance_At (Dt, 1, 3), R (1.0)), "blob ortho dist=1");
   end;

   ------------------------------------------------------------------
   Section ("6. Meijster matches naive on varied shapes");
   ------------------------------------------------------------------
   declare
      A : constant Binary_Image := Single_Feature (4, 7, 1, 7);
      Bimg : constant Binary_Image := Single_Feature (7, 4, 7, 1);
      C : Binary_Image := Blank (5, 5);
      D : Binary_Image := Blank (8, 8);
   begin
      C (1, 1) := True;
      C (5, 5) := True;
      C (1, 5) := True;
      D (2, 3) := True;
      D (6, 7) := True;
      D (4, 1) := True;
      D (8, 4) := True;

      Check
        (Maps_Equal
           (Squared_Distance_Transform (A),
            Meijster_Squared_Distance_Transform (A)),
         "Meijster=naive corner feature A");
      Check
        (Maps_equal
           (Squared_Distance_Transform (Bimg),
            Meijster_Squared_Distance_Transform (Bimg)),
         "Meijster=naive corner feature B");
      Check
        (Maps_equal
           (Squared_Distance_Transform (C),
            Meijster_Squared_Distance_Transform (C)),
         "Meijster=naive three corners");
      Check
        (Maps_equal
           (Squared_Distance_Transform (D),
            Meijster_Squared_Distance_Transform (D)),
         "Meijster=naive four scatter");
      Check
        (Maps_equal
           (Squared_Distance_Transform (A), Brute_Squared (A)),
         "naive=brute corner A");
      Check
        (Maps_equal
           (Meijster_Squared_Distance_Transform (D), Brute_Squared (D)),
         "Meijster=brute scatter D");
   end;

   ------------------------------------------------------------------
   Section ("7. Chamfer approximation properties");
   ------------------------------------------------------------------
   declare
      Img : constant Binary_Image := Single_Feature (5, 5, 3, 3);
      Ch  : constant Distance_Map := Chamfer_Distance_Transform (Img);
      Dt  : constant Distance_Map := Distance_Transform (Img);
   begin
      Check (Near (Distance_At (Ch, 3, 3), R (0.0)), "chamfer feature=0");
      Check (Near (Distance_At (Ch, 3, 4), R (1.0)), "chamfer ortho≈1");
      Check (Near (Distance_At (Ch, 4, 3), R (1.0)), "chamfer ortho y≈1");
      --  Diagonal step cost 4/3 ≈ 1.333… (exact Euclidean √2 ≈ 1.414)
      Check
        (Near (Distance_At (Ch, 4, 4), R (4.0 / 3.0), R (1.0E-9)),
         "chamfer diag=4/3");
      Check
        (Distance_At (Ch, 4, 4) < Distance_At (Dt, 4, 4) + R (0.1),
         "chamfer diag close to √2");
      Check
        (not Near (Distance_At (Ch, 4, 4), Distance_At (Dt, 4, 4), R (0.01)),
         "chamfer ≠ exact Euclidean on diag");
   end;

   declare
      Line : constant Binary_Image := Horizontal_Line (4, 4, 2);
      Ch   : constant Distance_Map := Chamfer_Distance_Transform (Line);
   begin
      Check (Near (Distance_At (Ch, 2, 1), R (0.0)), "chamfer on line=0");
      Check (Near (Distance_At (Ch, 1, 2), R (1.0)), "chamfer above line=1");
      Check (Near (Distance_At (Ch, 4, 3), R (2.0)), "chamfer two below=2");
   end;

   ------------------------------------------------------------------
   Section ("8. 1×1 and thin images");
   ------------------------------------------------------------------
   declare
      One : constant Binary_Image := Single_Feature (1, 1, 1, 1);
      Row : constant Binary_Image := Horizontal_Line (1, 5, 1);
      Col : Binary_Image := Blank (5, 1);
      Sq1 : constant Squared_Distance_Map :=
        Squared_Distance_Transform (One);
      Mj1 : constant Squared_Distance_Map :=
        Meijster_Squared_Distance_Transform (One);
   begin
      Col (3, 1) := True;
      Check (Squared_Distance_At (Sq1, 1, 1) = Nat (0), "1×1 feature sq=0");
      Check (Maps_equal (Sq1, Mj1), "1×1 Meijster=naive");
      Check
        (Maps_equal
           (Squared_Distance_Transform (Row),
            Meijster_Squared_Distance_Transform (Row)),
         "1-row Meijster=naive");
      Check
        (Maps_equal
           (Squared_Distance_Transform (Col),
            Meijster_Squared_Distance_Transform (Col)),
         "1-col Meijster=naive");
      Check
        (Squared_Distance_At
           (Squared_Distance_Transform (Col), 1, 1) = Nat (4),
         "1-col top sq=4");
      Check
        (Squared_Distance_At
           (Squared_Distance_Transform (Col), 5, 1) = Nat (4),
         "1-col bottom sq=4");
   end;

   ------------------------------------------------------------------
   Section ("9. Distance_At / Squared_Distance_At round-trip");
   ------------------------------------------------------------------
   declare
      Img : constant Binary_Image := Square_Blob (4, 5, 2, 2, 3, 3);
      Sq  : constant Squared_Distance_Map :=
        Squared_Distance_Transform (Img);
      Dt  : constant Distance_Map := Distance_Transform (Img);
      Ok  : Boolean := True;
   begin
      for Rr in Sq'Range (1) loop
         for Cc in Sq'Range (2) loop
            if Squared_Distance_At (Sq, Rr, Cc) /= Sq (Rr, Cc) then
               Ok := False;
            end if;
            if not Near (Distance_At (Dt, Rr, Cc), Dt (Rr, Cc)) then
               Ok := False;
            end if;
            if not Near
              (Distance_At (Dt, Rr, Cc),
               Real (Math.Sqrt (Long_Float (Sq (Rr, Cc)))))
            then
               Ok := False;
            end if;
         end loop;
      end loop;
      Check (Ok, "At accessors match map cells + √sq");
      Check (B (Ok), "round-trip flag held");
   end;

   ------------------------------------------------------------------
   Section ("10. Larger classroom grid vs brute / Meijster");
   ------------------------------------------------------------------
   declare
      Img : Binary_Image := Blank (12, 10);
      Sq, Mj, Br : Squared_Distance_Map (1 .. 12, 1 .. 10);
   begin
      Img (1, 1) := True;
      Img (12, 10) := True;
      Img (6, 5) := True;
      Img (3, 8) := True;
      Sq := Squared_Distance_Transform (Img);
      Mj := Meijster_Squared_Distance_Transform (Img);
      Br := Brute_Squared (Img);
      Check (Maps_equal (Sq, Br), "12×10 naive=brute");
      Check (Maps_equal (Mj, Br), "12×10 Meijster=brute");
      Check (Feature_Count (Img) = Nat (4), "12×10 Feature_Count=4");
      Check (Squared_Distance_At (Sq, 6, 5) = Nat (0), "center feature 0");
      Check (Has_Feature (Img), "12×10 Has_Feature");
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
