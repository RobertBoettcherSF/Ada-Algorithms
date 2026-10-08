pragma Ada_2022;
package Valid_Square with SPARK_Mode => On is
   subtype Side_Length is Natural range 0 .. 10;
   function Is_Valid_Square (Side : Side_Length) return Boolean
     with Global => null;
end Valid_Square;
