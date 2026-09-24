with Student_Attendance_Record_I;
procedure Tests is
   Good : constant Student_Attendance_Record_I.Record_Array := "PPALLP";
   Too_Late : constant Student_Attendance_Record_I.Record_Array := "PPALLL";
   Too_Many_A : constant Student_Attendance_Record_I.Record_Array := "AAPLLP";
begin
   pragma Assert (Student_Attendance_Record_I.Is_Rewardable (Good));
   pragma Assert (not Student_Attendance_Record_I.Is_Rewardable (Too_Late));
   pragma Assert (not Student_Attendance_Record_I.Is_Rewardable (Too_Many_A));
end Tests;
