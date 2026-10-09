pragma Ada_2022;
--  Own checks for Domino_And_Tromino_Tiling_Lite (see tests/SOURCES.txt).
--  No expected value comes from the program:
--  * brute-force tiling: fill the first empty cell (column by column) with
--    every piece that fits, for boards up to 2 x 18;
--  * the three-term recurrence T (n) = 2 T (n - 1) + T (n - 3) in
--    Long_Long_Integer for every n <= 28, and T (29) > Natural'Last;
--  * the ghost tables regenerated entry by entry from that recurrence.
with Ada.Text_IO;
with Domino_And_Tromino_Tiling_Lite; use Domino_And_Tromino_Tiling_Lite;

procedure Own_Checks with SPARK_Mode => Off is
   Failures : Natural := 0;
   Checked  : Natural := 0;

   procedure Report (Ok : Boolean; Label : String) is
   begin
      Checked := Checked + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 10 then
            Ada.Text_IO.Put_Line ("  FAIL own check: " & Label);
         end if;
      end if;
   end Report;

   Max_Brute : constant := 18;
   type Board is array (0 .. 1, 0 .. Max_Brute + 1) of Boolean;   --  True = covered

   --  Pieces as cell offsets (row, column) from the first empty cell (the
   --  top-most empty cell of the left-most column with one), which every
   --  placed piece must cover as its earliest cell in that order. A
   --  tromino is a 2 x 2 square of columns c, c + 1 minus one cell; the
   --  four choices of the missing cell give the four L rows below.
   type Offset is record
      R, C : Integer;
   end record;
   type Piece is array (1 .. 3) of Offset;
   type Piece_Info is record
      Size  : Positive;
      Cells : Piece;
   end record;
   Pieces : constant array (1 .. 6) of Piece_Info :=
     [(2, [(0, 0), (1, 0), (0, 0)]),            --  vertical domino
      (2, [(0, 0), (0, 1), (0, 0)]),            --  horizontal domino
      (3, [(0, 0), (1, 0), (0, 1)]),            --  L missing bottom right
      (3, [(0, 0), (1, 0), (1, 1)]),            --  L missing top right
      (3, [(0, 0), (0, 1), (1, 1)]),            --  L missing bottom left
      (3, [(0, 0), (-1, 1), (0, 1)])];          --  L missing top left (starts at a bottom cell)

   function Count (B : in out Board; N : Natural) return Long_Long_Integer is
      R, C  : Integer := -1;
      Total : Long_Long_Integer := 0;
   begin
      Find :
      for Col in 0 .. N - 1 loop
         for Row in 0 .. 1 loop
            if not B (Row, Col) then
               R := Row;
               C := Col;
               exit Find;
            end if;
         end loop;
      end loop Find;
      if R < 0 then
         return 1;
      end if;
      for P of Pieces loop
         declare
            Fits : Boolean := True;
         begin
            for K in 1 .. P.Size loop
               declare
                  RR : constant Integer := R + P.Cells (K).R;
                  CC : constant Integer := C + P.Cells (K).C;
               begin
                  Fits := Fits and then RR in 0 .. 1 and then CC in 0 .. N - 1
                    and then not B (RR, CC);
               end;
               exit when not Fits;
            end loop;
            if Fits then
               for K in 1 .. P.Size loop
                  B (R + P.Cells (K).R, C + P.Cells (K).C) := True;
               end loop;
               Total := Total + Count (B, N);
               for K in 1 .. P.Size loop
                  B (R + P.Cells (K).R, C + P.Cells (K).C) := False;
               end loop;
            end if;
         end;
      end loop;
      return Total;
   end Count;

   T : array (0 .. 29) of Long_Long_Integer := [0 => 1, 1 => 1, 2 => 2, others => 0];
begin
   for N in 3 .. 29 loop
      T (N) := 2 * T (N - 1) + T (N - 3);
   end loop;
   Report (T (29) > Long_Long_Integer (Natural'Last), "T (29) does not fit Natural");

   for N in Column_Count loop
      Report (Long_Long_Integer (Number_Of_Tilings (N)) = T (N), "recurrence n =" & N'Image);
      --  Ghost tables regenerated entry by entry. Full is T itself; Part
      --  from Full (n + 1) = Full (n) + Full (n - 1) + 2 Part (n).
      pragma Assert (Long_Long_Integer (Full_Table (N)) = T (N));
      pragma Assert (Long_Long_Integer (Part_Table (N))
                     = (T (N + 1) - T (N) - (if N = 0 then 0 else T (N - 1))) / 2);
   end loop;

   for N in 0 .. Max_Brute loop
      declare
         B : Board := [others => [others => False]];
      begin
         Report (Long_Long_Integer (Number_Of_Tilings (N)) = Count (B, N), "brute force n =" & N'Image);
      end;
   end loop;

   Ada.Text_IO.Put_Line ("own checks:" & Checked'Image & " checks," & Failures'Image & " failures");
   if Failures > 0 then
      raise Program_Error with "own checks failed";
   end if;
end Own_Checks;
