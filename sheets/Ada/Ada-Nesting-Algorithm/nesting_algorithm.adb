--  Nesting_Algorithm body — 1D stock cutting and 2D shelf nesting.

pragma Ada_2022;

package body Nesting_Algorithm
  with SPARK_Mode => Off
is

   -------------------------------------------------------------------------
   -- Numeric helpers
   -------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Area_Of (R : Rectangle) return Real is
   begin
      return R.Width * R.Height;
   end Area_Of;

   -------------------------------------------------------------------------
   -- Validation helpers
   -------------------------------------------------------------------------

   procedure Require_Positive_Stock (Stock : Real) is
   begin
      if Stock <= 0.0 then
         raise Invalid_Argument with "stock length must be positive";
      end if;
   end Require_Positive_Stock;

   procedure Require_Nonneg_Kerf (Kerf : Real) is
   begin
      if Kerf < 0.0 then
         raise Invalid_Argument with "kerf must be non-negative";
      end if;
   end Require_Nonneg_Kerf;

   procedure Require_Pieces_1D (Pieces : Length_Array) is
   begin
      if Pieces'Length = 0 then
         raise Invalid_Argument with "empty piece list";
      end if;
      if Pieces'Length > Max_Pieces then
         raise Invalid_Argument with "too many pieces";
      end if;
      for L of Pieces loop
         if L <= 0.0 then
            raise Invalid_Argument with "piece length must be positive";
         end if;
      end loop;
   end Require_Pieces_1D;

   procedure Require_Plate (W, H : Real) is
   begin
      if W <= 0.0 or else H <= 0.0 then
         raise Invalid_Argument with "plate sides must be positive";
      end if;
   end Require_Plate;

   procedure Require_Pieces_2D (Pieces : Rect_Array) is
   begin
      if Pieces'Length = 0 then
         raise Invalid_Argument with "empty piece list";
      end if;
      if Pieces'Length > Max_Pieces then
         raise Invalid_Argument with "too many pieces";
      end if;
      for R of Pieces loop
         if R.Width <= 0.0 or else R.Height <= 0.0 then
            raise Invalid_Argument
              with "rectangle width/height must be positive";
         end if;
      end loop;
   end Require_Pieces_2D;

   -------------------------------------------------------------------------
   -- 1D
   -------------------------------------------------------------------------

   function Scrap_1D
     (Stock, Yield, Kerf_Total : Real) return Real
   is
   begin
      return Stock - Yield - Kerf_Total;
   end Scrap_1D;

   function Nest_1D
     (Stock  : Real;
      Pieces : Length_Array;
      Kerf   : Real := 0.0) return Nest_1D_Result
   is
      Result : Nest_1D_Result;
      Cursor : Real := 0.0;  -- next free position along the stock
      Need   : Real;
   begin
      Require_Positive_Stock (Stock);
      Require_Nonneg_Kerf (Kerf);
      Require_Pieces_1D (Pieces);

      Result.Stock := Stock;

      for I in Pieces'Range loop
         --  Kerf before this piece when it is not the first placed piece.
         if Result.Placed_Count = 0 then
            Need := Pieces (I);
         else
            Need := Kerf + Pieces (I);
         end if;

         if Cursor + Need > Stock + Epsilon then
            --  Cannot place this or any later piece in input order.
            exit;
         end if;

         if Result.Placed_Count > 0 then
            Result.Kerf_Total := Result.Kerf_Total + Kerf;
            Cursor := Cursor + Kerf;
         end if;

         Cursor := Cursor + Pieces (I);
         Result.Yield := Result.Yield + Pieces (I);
         Result.Placed_Count := Result.Placed_Count + 1;
      end loop;

      Result.Used_Length := Result.Yield + Result.Kerf_Total;
      Result.Scrap := Scrap_1D (Stock, Result.Yield, Result.Kerf_Total);
      Result.Fits :=
        Result.Placed_Count = Pieces'Length
        and then Result.Scrap >= -Epsilon;
      return Result;
   end Nest_1D;

   -------------------------------------------------------------------------
   -- 2D helpers
   -------------------------------------------------------------------------

   function Rectangles_Overlap
     (A_X, A_Y, A_W, A_H : Real;
      B_X, B_Y, B_W, B_H : Real;
      Tol                : Real := Epsilon) return Boolean
   is
   begin
      --  Separating-axis: no overlap if one is strictly left/right/above/
      --  below the other (allowing Tol for educational soft boundaries).
      if A_X + A_W <= B_X + Tol then
         return False;
      end if;
      if B_X + B_W <= A_X + Tol then
         return False;
      end if;
      if A_Y + A_H <= B_Y + Tol then
         return False;
      end if;
      if B_Y + B_H <= A_Y + Tol then
         return False;
      end if;
      return True;
   end Rectangles_Overlap;

   function Fits_In_Plate
     (X, Y, W, H           : Real;
      Plate_Width          : Real;
      Plate_Height         : Real;
      Tol                  : Real := Epsilon) return Boolean
   is
   begin
      return X >= -Tol
        and then Y >= -Tol
        and then X + W <= Plate_Width + Tol
        and then Y + H <= Plate_Height + Tol;
   end Fits_In_Plate;

   --  Shelf state for the FFD heuristic.
   type Shelf_Rec is record
      Y0     : Real := 0.0;  -- bottom of shelf
      Height : Real := 0.0;  -- shelf strip height
      Next_X : Real := 0.0;  -- next free x along the shelf
      Active : Boolean := False;
   end record;

   type Shelf_Array is array (1 .. Max_Pieces) of Shelf_Rec;

   --  Work item: original index + size; Prefer_* are FFD sort keys.
   type Work_Item is record
      Orig     : Piece_Index;
      Width    : Real := 0.0;
      Height   : Real := 0.0;
      Prefer_H : Real := 0.0;
      Prefer_W : Real := 0.0;
   end record;

   type Work_Array is array (Piece_Index range <>) of Work_Item;

   procedure Sort_Decreasing_Height (W : in out Work_Array) is
      J    : Piece_Index;
      Key  : Work_Item;
      Swap : Boolean;
   begin
      if W'Length <= 1 then
         return;
      end if;
      for I in W'First + 1 .. W'Last loop
         Key := W (I);
         J := I;
         while J > W'First loop
            Swap := False;
            if W (J - 1).Prefer_H < Key.Prefer_H then
               Swap := True;
            elsif Near (W (J - 1).Prefer_H, Key.Prefer_H)
              and then W (J - 1).Prefer_W < Key.Prefer_W
            then
               Swap := True;
            end if;
            exit when not Swap;
            W (J) := W (J - 1);
            J := J - 1;
         end loop;
         W (J) := Key;
      end loop;
   end Sort_Decreasing_Height;

   --  Try to orient W×H into a Need_W × Need_H slot. Prefer unrotated.
   function Try_Orient
     (W, H           : Real;
      Allow_Rotate   : Boolean;
      Need_W, Need_H : Real;
      Out_W, Out_H   : out Real;
      Rotated        : out Boolean) return Boolean
   is
   begin
      Out_W := W;
      Out_H := H;
      Rotated := False;
      if W <= Need_W + Epsilon and then H <= Need_H + Epsilon then
         return True;
      end if;
      if Allow_Rotate
        and then H <= Need_W + Epsilon
        and then W <= Need_H + Epsilon
      then
         Out_W := H;
         Out_H := W;
         Rotated := True;
         return True;
      end if;
      return False;
   end Try_Orient;

   function Nest_2D_Shelf
     (Plate_Width  : Real;
      Plate_Height : Real;
      Pieces       : Rect_Array;
      Allow_Rotate : Boolean := False) return Nest_2D_Result
   is
      Result      : Nest_2D_Result;
      N           : constant Piece_Count := Pieces'Length;
      Work        : Work_Array (1 .. N);
      Shelves     : Shelf_Array;
      Shelf_Count : Natural := 0;
      Top_Y       : Real := 0.0;
      Placed_Mask : array (Piece_Index range Pieces'Range) of Boolean :=
        (others => False);

      function Orient_For_Shelf
        (Item   : Work_Item;
         Shelf  : Shelf_Rec;
         OW, OH : out Real;
         Rot    : out Boolean) return Boolean
      is
         Rem_W : constant Real := Plate_Width - Shelf.Next_X;
      begin
         return Try_Orient
           (Item.Width, Item.Height, Allow_Rotate,
            Rem_W, Shelf.Height, OW, OH, Rot);
      end Orient_For_Shelf;

      function Orient_New_Shelf
        (Item   : Work_Item;
         OW, OH : out Real;
         Rot    : out Boolean) return Boolean
      is
         Rem_H : constant Real := Plate_Height - Top_Y;
         Ok_UR : constant Boolean :=
           Item.Width <= Plate_Width + Epsilon
           and then Item.Height <= Rem_H + Epsilon;
         Ok_R  : constant Boolean :=
           Allow_Rotate
           and then Item.Height <= Plate_Width + Epsilon
           and then Item.Width <= Rem_H + Epsilon;
      begin
         if Ok_UR and then Ok_R then
            --  Both orientations fit: prefer larger height as shelf height.
            if Item.Height >= Item.Width then
               OW := Item.Width;
               OH := Item.Height;
               Rot := False;
            else
               OW := Item.Height;
               OH := Item.Width;
               Rot := True;
            end if;
            return True;
         elsif Ok_UR then
            OW := Item.Width;
            OH := Item.Height;
            Rot := False;
            return True;
         elsif Ok_R then
            OW := Item.Height;
            OH := Item.Width;
            Rot := True;
            return True;
         else
            OW := 0.0;
            OH := 0.0;
            Rot := False;
            return False;
         end if;
      end Orient_New_Shelf;

      procedure Record_Placement
        (PX, PY, OW, OH : Real;
         Orig           : Piece_Index;
         Rot            : Boolean)
      is
         Slot : Piece_Count;
      begin
         Result.Placed_Count := Result.Placed_Count + 1;
         Slot := Result.Placed_Count;
         Result.Placements (Slot) :=
           (X           => PX,
            Y           => PY,
            Width       => OW,
            Height      => OH,
            Piece_Index => Natural (Orig),
            Rotated     => Rot,
            Placed      => True);
         Result.Used_Area := Result.Used_Area + OW * OH;
         Placed_Mask (Orig) := True;
      end Record_Placement;

   begin
      Require_Plate (Plate_Width, Plate_Height);
      Require_Pieces_2D (Pieces);

      Result.Plate_Area := Plate_Width * Plate_Height;

      for I in Pieces'Range loop
         declare
            K : constant Piece_Index :=
              Piece_Index (I - Pieces'First + 1);
            W : constant Real := Pieces (I).Width;
            H : constant Real := Pieces (I).Height;
         begin
            Work (K).Orig := I;
            Work (K).Width := W;
            Work (K).Height := H;
            if Allow_Rotate then
               if H >= W then
                  Work (K).Prefer_H := H;
                  Work (K).Prefer_W := W;
               else
                  Work (K).Prefer_H := W;
                  Work (K).Prefer_W := H;
               end if;
            else
               Work (K).Prefer_H := H;
               Work (K).Prefer_W := W;
            end if;
         end;
      end loop;

      Sort_Decreasing_Height (Work);

      for K in Work'Range loop
         declare
            Item   : constant Work_Item := Work (K);
            Placed : Boolean := False;
            OW, OH : Real;
            Rot    : Boolean;
         begin
            for S in 1 .. Shelf_Count loop
               if Orient_For_Shelf (Item, Shelves (S), OW, OH, Rot)
                 and then Fits_In_Plate
                   (Shelves (S).Next_X, Shelves (S).Y0, OW, OH,
                    Plate_Width, Plate_Height)
               then
                  Record_Placement
                    (Shelves (S).Next_X, Shelves (S).Y0, OW, OH,
                     Item.Orig, Rot);
                  Shelves (S).Next_X := Shelves (S).Next_X + OW;
                  Placed := True;
                  exit;
               end if;
            end loop;

            if not Placed then
               if Orient_New_Shelf (Item, OW, OH, Rot) then
                  Shelf_Count := Shelf_Count + 1;
                  Shelves (Shelf_Count) :=
                    (Y0     => Top_Y,
                     Height => OH,
                     Next_X => OW,
                     Active => True);
                  Record_Placement (0.0, Top_Y, OW, OH, Item.Orig, Rot);
                  Top_Y := Top_Y + OH;
               end if;
            end if;
         end;
      end loop;

      if Result.Plate_Area > 0.0 then
         Result.Utilization := Result.Used_Area / Result.Plate_Area;
      end if;

      Result.All_Fit := True;
      for I in Pieces'Range loop
         if not Placed_Mask (I) then
            Result.All_Fit := False;
            exit;
         end if;
      end loop;

      return Result;
   end Nest_2D_Shelf;

end Nesting_Algorithm;
