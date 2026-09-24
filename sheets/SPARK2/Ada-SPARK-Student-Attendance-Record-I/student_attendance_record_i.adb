pragma Ada_2022;

package body Student_Attendance_Record_I with SPARK_Mode => On is
   function Is_Rewardable (Record_Value : Record_Array) return Boolean is
   begin
      return
        not (Record_Value (1) = 'A' and then Record_Value (2) = 'A')
        and then not (Record_Value (1) = 'A' and then Record_Value (3) = 'A')
        and then not (Record_Value (1) = 'A' and then Record_Value (4) = 'A')
        and then not (Record_Value (1) = 'A' and then Record_Value (5) = 'A')
        and then not (Record_Value (1) = 'A' and then Record_Value (6) = 'A')
        and then not (Record_Value (2) = 'A' and then Record_Value (3) = 'A')
        and then not (Record_Value (2) = 'A' and then Record_Value (4) = 'A')
        and then not (Record_Value (2) = 'A' and then Record_Value (5) = 'A')
        and then not (Record_Value (2) = 'A' and then Record_Value (6) = 'A')
        and then not (Record_Value (3) = 'A' and then Record_Value (4) = 'A')
        and then not (Record_Value (3) = 'A' and then Record_Value (5) = 'A')
        and then not (Record_Value (3) = 'A' and then Record_Value (6) = 'A')
        and then not (Record_Value (4) = 'A' and then Record_Value (5) = 'A')
        and then not (Record_Value (4) = 'A' and then Record_Value (6) = 'A')
        and then not (Record_Value (5) = 'A' and then Record_Value (6) = 'A')
        and then not (Record_Value (1) = 'L' and then Record_Value (2) = 'L' and then Record_Value (3) = 'L')
        and then not (Record_Value (2) = 'L' and then Record_Value (3) = 'L' and then Record_Value (4) = 'L')
        and then not (Record_Value (3) = 'L' and then Record_Value (4) = 'L' and then Record_Value (5) = 'L')
        and then not (Record_Value (4) = 'L' and then Record_Value (5) = 'L' and then Record_Value (6) = 'L');
   end Is_Rewardable;
end Student_Attendance_Record_I;
