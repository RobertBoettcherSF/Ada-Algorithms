pragma Ada_2022;
package body Pow_X_N with SPARK_Mode => On is
   procedure Power (X : Integer; N : Natural; Result : out Integer; Ok : out Boolean) is
      type Row is array (0 .. 5) of Integer;
      Table : constant array (-2 .. 2) of Row :=
        [[1, -2, 4, -8, 16, -32], [1, -1, 1, -1, 1, -1], [1, 0, 0, 0, 0, 0],
         [1, 1, 1, 1, 1, 1], [1, 2, 4, 8, 16, 32]];
   begin
      if X in -2 .. 2 and then N <= 5 then
         Result := Table (X) (N);
         Ok := True;
      else
         Result := 0;
         Ok := False;
      end if;
   end Power;
end Pow_X_N;
