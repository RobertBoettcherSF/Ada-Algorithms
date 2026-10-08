pragma SPARK_Mode (On);

package Remove_Element is
   subtype Index is Positive range 1 .. 32;
   subtype Length_Type is Natural range 0 .. 32;
   subtype Value is Integer range -1_000 .. 1_000;
   type Values is array (Index) of Value;

   procedure Remove (Data : in out Values; Length : in out Length_Type;
                     Target : Value)
     with Global => null;
end Remove_Element;
