--  Standalone test suite for Nesting_Algorithm (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Nesting_Algorithm; use Nesting_Algorithm;

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
   function N (X : Natural) return Natural is (X);
   function L1 (A : Real) return Length_Array is
     ([1 => A]);
   function L2 (A, B : Real) return Length_Array is
     ([1 => A, 2 => B]);
   function L3 (A, B, C : Real) return Length_Array is
     ([1 => A, 2 => B, 3 => C]);
   function RR (W, H : Real) return Rectangle is
     ((Width => W, Height => H));

   function Raised_Nest_1D
     (Stock : Real; Pieces : Length_Array; Kerf : Real) return Boolean
   is
      Res : Nest_1D_Result;
   begin
      Res := Nest_1D (Stock, Pieces, Kerf);
      pragma Unreferenced (Res);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Nest_1D;

   function Raised_Nest_2D
     (PW, PH : Real; Pieces : Rect_Array; Rot : Boolean) return Boolean
   is
      Res : Nest_2D_Result;
   begin
      Res := Nest_2D_Shelf (PW, PH, Pieces, Rot);
      pragma Unreferenced (Res);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Nest_2D;

   function No_Overlap (Res : Nest_2D_Result) return Boolean is
   begin
      for I in 1 .. Res.Placed_Count loop
         for J in I + 1 .. Res.Placed_Count loop
            declare
               A : Placement renames Res.Placements (I);
               B : Placement renames Res.Placements (J);
            begin
               if Rectangles_Overlap
                 (A.X, A.Y, A.Width, A.Height,
                  B.X, B.Y, B.Width, B.Height, R (0.0))
               then
                  return False;
               end if;
            end;
         end loop;
      end loop;
      return True;
   end No_Overlap;

   function All_Inside
     (Res : Nest_2D_Result; PW, PH : Real) return Boolean
   is
   begin
      for I in 1 .. Res.Placed_Count loop
         declare
            P : Placement renames Res.Placements (I);
         begin
            if not Fits_In_Plate
              (P.X, P.Y, P.Width, P.Height, PW, PH)
            then
               return False;
            end if;
         end;
      end loop;
      return True;
   end All_Inside;

begin
   Ada.Text_IO.Put_Line ("Nesting_Algorithm tests");
   Ada.Text_IO.Put_Line ("=======================");

   ------------------------------------------------------------------
   Section ("1. Near / Area_Of / Scrap_1D helpers");
   ------------------------------------------------------------------
   Check (Near (R (1.0), R (1.0)), "Near equal");
   Check (Near (R (1.0), R (1.0 + 1.0E-12)), "Near within eps");
   Check (not Near (R (0.0), R (1.0)), "not Near 0,1");
   Check (Near (R (2.0), R (2.0), R (0.0)), "Near exact Tol=0");
   Check (not Near (R (2.0), R (2.1), R (0.05)), "not Near outside Tol");
   Check (Near (Area_Of (RR (3.0, 4.0)), R (12.0)), "Area_Of 3x4=12");
   Check (Near (Area_Of (RR (1.0, 1.0)), R (1.0)), "Area_Of 1x1=1");
   Check (Near (Scrap_1D (R (100.0), R (80.0), R (5.0)), R (15.0)),
          "Scrap_1D 100-80-5=15");
   Check (Near (Scrap_1D (R (10.0), R (10.0), R (0.0)), R (0.0)),
          "Scrap_1D exact fill");
   Check (Near (Scrap_1D (R (50.0), R (40.0), R (2.0)), R (8.0)),
          "Scrap_1D 50-40-2=8");

   ------------------------------------------------------------------
   Section ("2. Nest_1D classic fit");
   ------------------------------------------------------------------
   declare
      Res : Nest_1D_Result;
   begin
      Res := Nest_1D (R (100.0), L3 (20.0, 30.0, 40.0), R (0.0));
      Check (Res.Fits, "1D 20+30+40 on 100 fits");
      Check (Res.Placed_Count = 3, "1D placed 3");
      Check (Near (Res.Yield, R (90.0)), "1D yield 90");
      Check (Near (Res.Kerf_Total, R (0.0)), "1D kerf 0");
      Check (Near (Res.Scrap, R (10.0)), "1D scrap 10");
      Check (Near (Res.Used_Length, R (90.0)), "1D used 90");
      Check (Near (Res.Stock, R (100.0)), "1D stock 100");
   end;

   declare
      Res : Nest_1D_Result;
   begin
      Res := Nest_1D (R (10.0), L1 (10.0), R (0.0));
      Check (Res.Fits, "1D exact single piece fits");
      Check (Near (Res.Scrap, R (0.0)), "1D exact scrap 0");
      Check (Res.Placed_Count = 1, "1D exact placed 1");
   end;

   declare
      Res : Nest_1D_Result;
   begin
      Res := Nest_1D (R (100.0), L2 (40.0, 40.0), R (5.0));
      Check (Res.Fits, "1D with kerf fits");
      Check (Near (Res.Yield, R (80.0)), "1D kerf yield 80");
      Check (Near (Res.Kerf_Total, R (5.0)), "1D kerf_total 5");
      Check (Near (Res.Scrap, R (15.0)), "1D kerf scrap 15");
      Check (Near (Res.Used_Length, R (85.0)), "1D kerf used 85");
   end;

   ------------------------------------------------------------------
   Section ("3. Nest_1D fail / partial");
   ------------------------------------------------------------------
   declare
      Res : Nest_1D_Result;
   begin
      Res := Nest_1D (R (50.0), L2 (30.0, 30.0), R (0.0));
      Check (not Res.Fits, "1D 30+30 on 50 does not fit");
      Check (Res.Placed_Count = 1, "1D partial places first only");
      Check (Near (Res.Yield, R (30.0)), "1D partial yield 30");
      Check (Near (Res.Scrap, R (20.0)), "1D partial scrap 20");
   end;

   declare
      Res : Nest_1D_Result;
   begin
      Res := Nest_1D (R (100.0), L3 (40.0, 40.0, 40.0), R (10.0));
      Check (not Res.Fits, "1D kerf blocks third piece");
      Check (Res.Placed_Count = 2, "1D kerf placed 2 of 3");
      Check (Near (Res.Kerf_Total, R (10.0)), "1D kerf_total one gap");
      Check (Near (Res.Yield, R (80.0)), "1D kerf yield 80");
      Check (Near (Res.Scrap, R (10.0)), "1D kerf remaining scrap 10");
   end;

   declare
      Res : Nest_1D_Result;
   begin
      Res := Nest_1D (R (5.0), L1 (10.0), R (0.0));
      Check (not Res.Fits, "1D single piece too long fails");
      Check (Res.Placed_Count = 0, "1D too long places 0");
      Check (Near (Res.Scrap, R (5.0)), "1D too long scrap=stock");
   end;

   ------------------------------------------------------------------
   Section ("4. Nest_1D Invalid_Argument");
   ------------------------------------------------------------------
   Check (Raised_Nest_1D (R (0.0), L1 (1.0), R (0.0)),
          "1D stock 0 raises");
   Check (Raised_Nest_1D (R (-1.0), L1 (1.0), R (0.0)),
          "1D stock negative raises");
   Check (Raised_Nest_1D (R (10.0), L1 (1.0), R (-0.1)),
          "1D negative kerf raises");
   Check (Raised_Nest_1D (R (10.0), L1 (0.0), R (0.0)),
          "1D zero piece raises");
   Check (Raised_Nest_1D (R (10.0), L1 (-2.0), R (0.0)),
          "1D negative piece raises");
   declare
      Empty : Length_Array (1 .. 0);
   begin
      Check (Raised_Nest_1D (R (10.0), Empty, R (0.0)),
             "1D empty list raises");
   end;

   ------------------------------------------------------------------
   Section ("5. Nest_1D multi-piece / capacity note");
   ------------------------------------------------------------------
   declare
      Pieces : Length_Array (1 .. 8);
      Res    : Nest_1D_Result;
   begin
      for I in Pieces'Range loop
         Pieces (I) := R (10.0);
      end loop;
      Res := Nest_1D (R (100.0), Pieces, R (0.0));
      Check (Res.Fits, "1D eight 10s on 100 fit");
      Check (Near (Res.Scrap, R (20.0)), "1D eight 10s scrap 20");
      Check (N (Max_Pieces) = 32, "Max_Pieces = 32");
   end;

   declare
      Pieces : constant Length_Array :=
        [1 => 5.0, 2 => 5.0, 3 => 5.0, 4 => 5.0, 5 => 5.0];
      Res    : Nest_1D_Result;
   begin
      Res := Nest_1D (R (29.0), Pieces, R (1.0));
      Check (Res.Fits, "1D five 5s with kerf 1 exact fit");
      Check (Near (Res.Kerf_Total, R (4.0)), "1D five pieces kerf_total 4");
      Check (Near (Res.Scrap, R (0.0)), "1D exact with kerf scrap 0");
      Check (Near (Res.Used_Length, R (29.0)), "1D used = stock");
   end;

   ------------------------------------------------------------------
   Section ("6. Rectangles_Overlap / Fits_In_Plate");
   ------------------------------------------------------------------
   Check (Rectangles_Overlap
            (R (0.0), R (0.0), R (2.0), R (2.0),
             R (1.0), R (1.0), R (2.0), R (2.0), R (0.0)),
          "overlap intersecting squares");
   Check (not Rectangles_Overlap
            (R (0.0), R (0.0), R (1.0), R (1.0),
             R (1.0), R (0.0), R (1.0), R (1.0), R (0.0)),
          "touching edges only is not overlap (Tol=0)");
   Check (not Rectangles_Overlap
            (R (0.0), R (0.0), R (1.0), R (1.0),
             R (2.0), R (2.0), R (1.0), R (1.0), R (0.0)),
          "separated squares no overlap");
   Check (Rectangles_Overlap
            (R (0.0), R (0.0), R (3.0), R (1.0),
             R (1.0), R (0.0), R (1.0), R (1.0), R (0.0)),
          "contained strip overlaps");
   Check (Fits_In_Plate
            (R (0.0), R (0.0), R (10.0), R (5.0), R (10.0), R (5.0)),
          "exact plate fit");
   Check (not Fits_In_Plate
            (R (0.0), R (0.0), R (11.0), R (5.0), R (10.0), R (5.0)),
          "too wide for plate");
   Check (not Fits_In_Plate
            (R (-0.1), R (0.0), R (1.0), R (1.0), R (10.0), R (10.0)),
          "negative x outside");
   Check (Fits_In_Plate
            (R (1.0), R (1.0), R (2.0), R (2.0), R (5.0), R (5.0)),
          "interior box fits");

   ------------------------------------------------------------------
   Section ("7. Nest_2D_Shelf classic small packs");
   ------------------------------------------------------------------
   declare
      Pieces : constant Rect_Array :=
        [1 => RR (5.0, 5.0), 2 => RR (5.0, 5.0)];
      Res : Nest_2D_Result;
   begin
      Res := Nest_2D_Shelf (R (10.0), R (5.0), Pieces, False);
      Check (Res.All_Fit, "2D two 5x5 on 10x5 fit");
      Check (Res.Placed_Count = 2, "2D placed 2");
      Check (Near (Res.Utilization, R (1.0)), "2D util 100%");
      Check (Near (Res.Used_Area, R (50.0)), "2D used area 50");
      Check (Near (Res.Plate_Area, R (50.0)), "2D plate area 50");
      Check (No_Overlap (Res), "2D no overlap two squares");
      Check (All_Inside (Res, R (10.0), R (5.0)), "2D inside plate");
   end;

   declare
      Pieces : constant Rect_Array :=
        [1 => RR (4.0, 3.0),
         2 => RR (4.0, 3.0),
         3 => RR (4.0, 3.0)];
      Res : Nest_2D_Result;
   begin
      Res := Nest_2D_Shelf (R (10.0), R (10.0), Pieces, False);
      Check (Res.All_Fit, "2D three 4x3 on 10x10 fit");
      Check (Res.Placed_Count = 3, "2D three placed");
      Check (Near (Res.Used_Area, R (36.0)), "2D used 36");
      Check (No_Overlap (Res), "2D three no overlap");
      Check (All_Inside (Res, R (10.0), R (10.0)), "2D three inside");
      Check (Res.Utilization > R (0.3), "2D util > 0.3");
   end;

   declare
      Pieces : constant Rect_Array := [1 => RR (10.0, 10.0)];
      Res : Nest_2D_Result;
   begin
      Res := Nest_2D_Shelf (R (10.0), R (10.0), Pieces, False);
      Check (Res.All_Fit, "2D single exact fill");
      Check (Near (Res.Utilization, R (1.0)), "2D single util 1");
      Check (Near (Res.Placements (1).X, R (0.0)), "2D single at x=0");
      Check (Near (Res.Placements (1).Y, R (0.0)), "2D single at y=0");
   end;

   ------------------------------------------------------------------
   Section ("8. Nest_2D_Shelf fail / rotation");
   ------------------------------------------------------------------
   declare
      Pieces : constant Rect_Array :=
        [1 => RR (6.0, 6.0), 2 => RR (6.0, 6.0)];
      Res : Nest_2D_Result;
   begin
      Res := Nest_2D_Shelf (R (10.0), R (10.0), Pieces, False);
      Check (not Res.All_Fit, "2D two 6x6 on 10x10 fail without rot help");
      Check (Res.Placed_Count = 1, "2D only one 6x6 placed");
   end;

   declare
      Pieces : constant Rect_Array :=
        [1 => RR (8.0, 2.0),
         2 => RR (2.0, 8.0)];
      Res : Nest_2D_Result;
   begin
      Res := Nest_2D_Shelf (R (10.0), R (4.0), Pieces, True);
      Check (Res.All_Fit, "2D rotation allows both on 10x4");
      Check (Res.Placed_Count = 2, "2D rotated pack placed 2");
      Check (No_Overlap (Res), "2D rotated no overlap");
      Check (All_Inside (Res, R (10.0), R (4.0)), "2D rotated inside");
   end;

   declare
      Pieces : constant Rect_Array := [1 => RR (3.0, 8.0)];
      Res_No, Res_Yes : Nest_2D_Result;
   begin
      Res_No := Nest_2D_Shelf (R (10.0), R (5.0), Pieces, False);
      Res_Yes := Nest_2D_Shelf (R (10.0), R (5.0), Pieces, True);
      Check (not Res_No.All_Fit, "2D 3x8 without rotate fails on 10x5");
      Check (Res_Yes.All_Fit, "2D 3x8 with rotate fits on 10x5");
      Check (Res_Yes.Placements (1).Rotated, "2D piece marked rotated");
      Check (Near (Res_Yes.Placements (1).Width, R (8.0)),
             "2D rotated width 8");
      Check (Near (Res_Yes.Placements (1).Height, R (3.0)),
             "2D rotated height 3");
   end;

   ------------------------------------------------------------------
   Section ("9. Nest_2D Invalid_Argument");
   ------------------------------------------------------------------
   declare
      One : constant Rect_Array := [1 => RR (1.0, 1.0)];
   begin
      Check (Raised_Nest_2D (R (0.0), R (10.0), One, False),
             "2D plate width 0 raises");
      Check (Raised_Nest_2D (R (10.0), R (-1.0), One, False),
             "2D plate height negative raises");
      Check (Raised_Nest_2D (R (10.0), R (10.0),
              [1 => RR (0.0, 1.0)], False),
             "2D zero width piece raises");
      Check (Raised_Nest_2D (R (10.0), R (10.0),
              [1 => RR (1.0, -2.0)], False),
             "2D negative height piece raises");
   end;
   declare
      Empty : Rect_Array (1 .. 0);
   begin
      Check (Raised_Nest_2D (R (10.0), R (10.0), Empty, False),
             "2D empty list raises");
   end;

   ------------------------------------------------------------------
   Section ("10. Nest_2D FFD ordering / multi-shelf");
   ------------------------------------------------------------------
   declare
      Pieces : constant Rect_Array :=
        [1 => RR (2.0, 2.0),
         2 => RR (3.0, 5.0),
         3 => RR (2.0, 4.0)];
      Res : Nest_2D_Result;
   begin
      Res := Nest_2D_Shelf (R (10.0), R (10.0), Pieces, False);
      Check (Res.All_Fit, "2D mixed heights all fit");
      Check (Res.Placed_Count = 3, "2D mixed placed 3");
      Check (No_Overlap (Res), "2D mixed no overlap");
      declare
         Found_Tall_Bottom : Boolean := False;
      begin
         for I in 1 .. Res.Placed_Count loop
            if Res.Placements (I).Piece_Index = 2
              and then Near (Res.Placements (I).Y, R (0.0))
            then
               Found_Tall_Bottom := True;
            end if;
         end loop;
         Check (Found_Tall_Bottom, "2D FFD tallest on bottom shelf");
      end;
   end;

   declare
      Pieces : Rect_Array (1 .. 4);
      Res : Nest_2D_Result;
   begin
      for I in Pieces'Range loop
         Pieces (I) := RR (5.0, 5.0);
      end loop;
      Res := Nest_2D_Shelf (R (10.0), R (10.0), Pieces, False);
      Check (Res.All_Fit, "2D four 5x5 on 10x10 fit (2 shelves)");
      Check (Near (Res.Utilization, R (1.0)), "2D four util 100%");
      Check (No_Overlap (Res), "2D four no overlap");
      Check (All_Inside (Res, R (10.0), R (10.0)), "2D four inside");
   end;

   ------------------------------------------------------------------
   Section ("11. Nest_2D placement metadata");
   ------------------------------------------------------------------
   declare
      Pieces : constant Rect_Array :=
        [1 => RR (2.0, 3.0), 2 => RR (4.0, 3.0)];
      Res : Nest_2D_Result;
      Seen1, Seen2 : Boolean := False;
   begin
      Res := Nest_2D_Shelf (R (10.0), R (5.0), Pieces, False);
      Check (Res.All_Fit, "2D metadata pack fits");
      for I in 1 .. Res.Placed_Count loop
         Check (Res.Placements (I).Placed, "2D placement Placed flag");
         if Res.Placements (I).Piece_Index = 1 then
            Seen1 := True;
            Check (Near (Res.Placements (I).Width, R (2.0)),
                   "2D piece1 width preserved");
            Check (Near (Res.Placements (I).Height, R (3.0)),
                   "2D piece1 height preserved");
         elsif Res.Placements (I).Piece_Index = 2 then
            Seen2 := True;
         end if;
      end loop;
      Check (Seen1 and Seen2, "2D both piece indices present");
   end;

   ------------------------------------------------------------------
   Section ("12. Wikipedia scrap identity round-trip");
   ------------------------------------------------------------------
   declare
      Stocks : constant array (1 .. 4) of Real :=
        [100.0, 50.0, 200.0, 37.0];
      Kerfs  : constant array (1 .. 4) of Real :=
        [0.0, 1.0, 2.5, 0.5];
   begin
      for K in Stocks'Range loop
         declare
            Pieces : constant Length_Array := L3 (10.0, 12.0, 8.0);
            Res : constant Nest_1D_Result :=
              Nest_1D (Stocks (K), Pieces, Kerfs (K));
         begin
            Check
              (Near
                 (Res.Scrap,
                  Scrap_1D (Res.Stock, Res.Yield, Res.Kerf_Total)),
               "wiki scrap identity case" & Integer'Image (K));
            Check
              (Near (Res.Used_Length, Res.Yield + Res.Kerf_Total),
               "used = yield + kerf case" & Integer'Image (K));
         end;
      end loop;
   end;

   ------------------------------------------------------------------
   -- Summary
   ------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line
     ("Result:" & Natural'Image (Pass_Count) & " PASS,"
      & Natural'Image (Fail_Count) & " FAIL");

   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;
