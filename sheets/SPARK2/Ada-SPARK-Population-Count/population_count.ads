pragma Ada_2022;
with Interfaces;
package Population_Count with SPARK_Mode => On is
   subtype Word is Interfaces.Unsigned_32;

   function Count (Value : Word) return Natural
     with Global => null, Post => Count'Result <= 32;
end Population_Count;
