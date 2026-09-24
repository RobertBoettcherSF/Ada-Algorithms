pragma Ada_2022;

package Count_And_Say_Stub with SPARK_Mode => On is
   subtype Number_Type is Positive range 1 .. 5;
   Length : constant := 12;
   subtype Index is Positive range 1 .. Length;
   type Text_Array is array (Index) of Character;

   function Describe (Number : Number_Type) return Text_Array
     with Global => null;
end Count_And_Say_Stub;
