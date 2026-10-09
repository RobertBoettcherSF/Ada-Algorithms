pragma Ada_2022;
--  Scaffold for the failing test: the new API, still answering from the
--  old table (X in -2 .. 2, N in 0 .. 5).
package Pow_X_N with SPARK_Mode => On is
   procedure Power (X : Integer; N : Natural; Result : out Integer; Ok : out Boolean)
     with Global => null;
end Pow_X_N;
