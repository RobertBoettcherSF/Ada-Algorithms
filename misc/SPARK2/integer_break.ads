pragma Ada_2022;
package Integer_Break with SPARK_Mode => On is
   subtype Number is Positive range 2 .. 10;
   subtype Product is Natural range 1 .. 36;
   function Maximum (N : Number) return Product with Global => null;
end Integer_Break;
