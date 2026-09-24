pragma Ada_2022;

package body Search_A_2D_Matrix with SPARK_Mode => On is
   function Contains (Grid : Matrix; Target : Value) return Boolean is
      R : Integer range 1 .. Rows + 1 := 1;
      C : Integer range 0 .. Cols := Cols;
      Found : Boolean := False;
   begin
      for Step in 1 .. Rows + Cols loop
         pragma Loop_Invariant (R in 1 .. Rows + 1);
         pragma Loop_Invariant (C in 0 .. Cols);
         exit when Found or else R > Rows or else C = 0;
         if Grid (Row (R), Column (C)) = Target then
            Found := True;
         elsif Grid (Row (R), Column (C)) < Target then
            R := R + 1;
         else
            C := C - 1;
         end if;
      end loop;
      return Found;
   end Contains;
end Search_A_2D_Matrix;
