pragma SPARK_Mode (On);

package Valid_Number is
   Text_Length : constant := 12;
   subtype Index is Positive range 1 .. Text_Length;
   type Text is array (Index) of Character;

   function Is_Valid (Input : Text) return Boolean
     with Global => null;
end Valid_Number;
