pragma Ada_2022;

package N_Queens_Lite with SPARK_Mode => On is
   Board_Size : constant := 4;
   subtype Row is Positive range 1 .. Board_Size;
   subtype Column is Natural range 0 .. Board_Size;
   type Positions is array (Row) of Column;
   function Is_Solution (P : Positions) return Boolean with Global => null;
end N_Queens_Lite;
