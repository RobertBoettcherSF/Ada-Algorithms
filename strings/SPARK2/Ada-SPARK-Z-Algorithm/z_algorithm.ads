pragma Ada_2022;
package Z_Algorithm with SPARK_Mode => On is
   Text_Length : constant := 8;
   subtype Index is Positive range 1 .. Text_Length;
   subtype Z_Length is Natural range 0 .. Text_Length;
   type Text_Array is array (Index) of Character;
   type Z_Array is array (Index) of Z_Length;

   procedure Compute_Z (Text : Text_Array; Result : out Z_Array);
end Z_Algorithm;
