-- warnsdorff.adb
-- Package body for Warnsdorff's Rule algorithm.

package body Warnsdorff is

   -- Internal type to track relative X, Y movements.
   type Position is record
      X, Y : Integer;
   end record;

   -- Array defining all 8 possible moves a knight can make.
   type Move_Array is array (1 .. 8) of Position;
   Knight_Moves : constant Move_Array :=
     ((1, 2), (2, 1), (2, -1), (1, -2),
      (-1, -2), (-2, -1), (-2, 1), (-1, 2));

   -- Helper: Checks if a target square is within bounds and unvisited.
   function Is_Safe (Grid : Board_Grid; Size : Positive; X, Y : Integer) return Boolean is
   begin
      return X >= 1 and then X <= Size and then
             Y >= 1 and then Y <= Size and then
             Grid (X, Y) = 0;
   end Is_Safe;

   -- Helper: Returns the "degree" of a square (number of valid onward moves).
   function Get_Degree (Grid : Board_Grid; Size : Positive; X, Y : Integer) return Integer is
      Count : Integer := 0;
   begin
      for I in Knight_Moves'Range loop
         if Is_Safe (Grid, Size, X + Knight_Moves(I).X, Y + Knight_Moves(I).Y) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Get_Degree;

   -- Helper: For Pohl's variant. Returns the sum of the degrees of all valid onward squares.
   function Sum_Neighbor_Degrees (Grid : Board_Grid; Size : Positive; X, Y : Integer) return Integer is
      Sum : Integer := 0;
   begin
      for I in Knight_Moves'Range loop
         declare
            NX : constant Integer := X + Knight_Moves(I).X;
            NY : constant Integer := Y + Knight_Moves(I).Y;
         begin
            if Is_Safe (Grid, Size, NX, NY) then
               Sum := Sum + Get_Degree (Grid, Size, NX, NY);
            end if;
         end;
      end loop;
      return Sum;
   end Sum_Neighbor_Degrees;

   procedure Solve_Tour
     (Size     : in  Positive;
      Start_X  : in  Positive;
      Start_Y  : in  Positive;
      Strategy : in  Strategy_Type;
      Result   : out Board_Grid;
      Success  : out Boolean)
   is
      Curr_X, Curr_Y : Integer;
   begin
      if Start_X > Size or Start_Y > Size then
         raise Invalid_Start_Position;
      end if;

      -- Initialize board to 0 (unvisited)
      for I in 1 .. Size loop
         for J in 1 .. Size loop
            Result (I, J) := 0;
         end loop;
      end loop;

      -- Trivial board edge case
      if Size = 1 then
         Result (1, 1) := 1;
         Success := True;
         return;
      end if;

      Curr_X := Start_X;
      Curr_Y := Start_Y;
      Result (Curr_X, Curr_Y) := 1;

      -- Iterate through remaining moves
      for Step in 2 .. Size * Size loop
         declare
            Min_Degree    : Integer := 9; -- Max possible degree is 8, so 9 acts as infinity
            Min_Pohl      : Integer := Integer'Last;
            Next_X, Next_Y : Integer := -1;
            Deg           : Integer;
            Pohl_Val      : Integer;
         begin
            for I in Knight_Moves'Range loop
               declare
                  NX : constant Integer := Curr_X + Knight_Moves(I).X;
                  NY : constant Integer := Curr_Y + Knight_Moves(I).Y;
               begin
                  if Is_Safe (Result, Size, NX, NY) then
                     Deg := Get_Degree (Result, Size, NX, NY);

                     -- Warnsdorff Core Rule: Pick minimum degree
                     if Deg < Min_Degree then
                        Min_Degree := Deg;
                        Next_X := NX;
                        Next_Y := NY;
                        
                        -- Track Pohl value in case of future ties during this step
                        if Strategy = Pohl then
                           Min_Pohl := Sum_Neighbor_Degrees(Result, Size, NX, NY);
                        end if;
                        
                     -- Pohl / Squirrel and Cull Tie-Breaking
                     elsif Deg = Min_Degree and Strategy = Pohl then
                        Pohl_Val := Sum_Neighbor_Degrees(Result, Size, NX, NY);
                        if Pohl_Val < Min_Pohl then
                           Min_Pohl := Pohl_Val;
                           Next_X := NX;
                           Next_Y := NY;
                        end if;
                     end if;
                  end if;
               end;
            end loop;

            -- Dead end reached before board is full
            if Next_X = -1 then
               Success := False;
               return;
            end if;

            -- Apply the best move found
            Curr_X := Next_X;
            Curr_Y := Next_Y;
            Result (Curr_X, Curr_Y) := Step;
         end;
      end loop;

      Success := True;
   end Solve_Tour;

   function Is_Valid_Tour (Grid : Board_Grid; Size : Positive) return Boolean is
      type Point is record
         X, Y : Integer;
      end record;
      Positions : array (1 .. Size * Size) of Point;
   begin
      -- Map sequence steps to coordinates and ensure all cells are visited
      for I in 1 .. Size loop
         for J in 1 .. Size loop
            if Grid (I, J) < 1 or Grid (I, J) > Size * Size then
               return False;
            end if;
            Positions (Grid (I, J)) := (I, J);
         end loop;
      end loop;

      -- Validate each step is a strict L-shape Knight Move
      for I in 1 .. Size * Size - 1 loop
         declare
            DX : constant Integer := abs (Positions (I).X - Positions (I + 1).X);
            DY : constant Integer := abs (Positions (I).Y - Positions (I + 1).Y);
         begin
            if not ((DX = 1 and DY = 2) or (DX = 2 and DY = 1)) then
               return False;
            end if;
         end;
      end loop;

      return True;
   end Is_Valid_Tour;

end Warnsdorff;
