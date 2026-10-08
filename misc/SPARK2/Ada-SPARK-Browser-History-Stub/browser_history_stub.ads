pragma SPARK_Mode (On);

package Browser_History_Stub is
   History_Size : constant := 4;
   subtype History_Index is Positive range 1 .. History_Size;
   subtype Page_Id is Positive range 1 .. 100;
   subtype Back_Steps is Natural range 0 .. History_Size;
   type History_Array is array (History_Index) of Page_Id;

   function Back_Target
     (History : History_Array; Current : History_Index;
      Steps : Back_Steps) return Page_Id;
end Browser_History_Stub;
