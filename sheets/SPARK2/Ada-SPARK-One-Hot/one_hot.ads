pragma SPARK_Mode (On);

package One_Hot is
   Category_Count : constant := 4;
   subtype Category is Positive range 1 .. Category_Count;
   type Vector is array (Category) of Boolean;

   function Encode (Value : Category) return Vector;
end One_Hot;
