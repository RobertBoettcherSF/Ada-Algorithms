pragma Ada_2022;

package Next_Greater_Node_In_Linked_List with SPARK_Mode => On is
   subtype Length_Type is Natural range 0 .. 32;
   subtype Index is Positive range 1 .. 32;
   subtype Value is Natural range 0 .. 32;
   subtype Result_Value is Integer range -1 .. 32;
   type Values is array (Index) of Value;
   type Results is array (Index) of Result_Value;

   function Next_Greater (A : Values; Length : Length_Type) return Results
     with Global => null;
end Next_Greater_Node_In_Linked_List;
