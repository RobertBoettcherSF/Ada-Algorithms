pragma Ada_2022;

package Student_Attendance_Record_I with SPARK_Mode => On is
   Length : constant := 6;
   subtype Index is Positive range 1 .. Length;
   type Record_Array is array (Index) of Character;

   function Is_Rewardable (Record_Value : Record_Array) return Boolean
     with Global => null;
end Student_Attendance_Record_I;
