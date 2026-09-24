pragma Ada_2022;
package Accounts_Merge_Lite with SPARK_Mode => On is
   Max_Accounts : constant := 32;
   subtype Account is Positive range 1 .. Max_Accounts;
   subtype Owner is Positive range 1 .. Max_Accounts;
   subtype Group_Count is Natural range 0 .. Max_Accounts;
   type Owner_Array is array (Account) of Owner;
   function Merge_Count (N : Account; Owners : Owner_Array)
     return Group_Count;
end Accounts_Merge_Lite;
