pragma Ada_2022;
package body Number_Of_Islands_DFS with SPARK_Mode => On is
   Stack_Size : constant := 16;
   subtype Stack_Position is Positive range 1 .. Stack_Size;
   type Coordinate_Stack is array (Stack_Position) of Coordinate;

   procedure Explore (G : Grid; Start_R, Start_C : Coordinate; Seen : in out Grid)
     with Global => null, Pre => G (Start_R, Start_C), Post => Seen (Start_R, Start_C) is
      Rows : Coordinate_Stack := (others => 1);
      Cols : Coordinate_Stack := (others => 1);
      Top : Natural range 0 .. Stack_Size := 1;
      R : Coordinate;
      C : Coordinate;
   begin
      Seen (Start_R, Start_C) := True;
      Rows (1) := Start_R;
      Cols (1) := Start_C;
      for Step in 1 .. 16 loop
         pragma Loop_Invariant (Top in 0 .. Stack_Size);
         pragma Loop_Invariant (Seen (Start_R, Start_C));
         if Top > 0 then
            R := Rows (Top);
            C := Cols (Top);
            Top := Top - 1;
            if R > 1 and then G (R - 1, C) and then not Seen (R - 1, C) and then Top < Stack_Size then
               Seen (R - 1, C) := True; Top := Top + 1; Rows (Top) := R - 1; Cols (Top) := C;
            end if;
            if R < Grid_Size and then G (R + 1, C) and then not Seen (R + 1, C) and then Top < Stack_Size then
               Seen (R + 1, C) := True; Top := Top + 1; Rows (Top) := R + 1; Cols (Top) := C;
            end if;
            if C > 1 and then G (R, C - 1) and then not Seen (R, C - 1) and then Top < Stack_Size then
               Seen (R, C - 1) := True; Top := Top + 1; Rows (Top) := R; Cols (Top) := C - 1;
            end if;
            if C < Grid_Size and then G (R, C + 1) and then not Seen (R, C + 1) and then Top < Stack_Size then
               Seen (R, C + 1) := True; Top := Top + 1; Rows (Top) := R; Cols (Top) := C + 1;
            end if;
         end if;
      end loop;
   end Explore;

   function Count (G : Grid) return Island_Count is
      Seen : Grid := (others => (others => False));
      Total : Island_Count := 0;
      procedure Start (R, C : Coordinate) is
      begin
         if G (R, C) and then not Seen (R, C) then
            Total := Total + 1; Explore (G, R, C, Seen);
            pragma Assert (Seen (R, C));
         end if;
      end Start;
   begin
      Start (1, 1); Start (1, 2); Start (1, 3); Start (1, 4);
      Start (2, 1); Start (2, 2); Start (2, 3); Start (2, 4);
      Start (3, 1); Start (3, 2); Start (3, 3); Start (3, 4);
      Start (4, 1); Start (4, 2); Start (4, 3); Start (4, 4);
      return Total;
   end Count;
end Number_Of_Islands_DFS;
