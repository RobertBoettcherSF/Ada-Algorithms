pragma Ada_2022;
package Valid_Perfect_Square with SPARK_Mode => On is
   subtype Number is Natural range 0 .. 100;
   function Is_Perfect_Square (N : Number) return Boolean with Global => null;
end Valid_Perfect_Square;
