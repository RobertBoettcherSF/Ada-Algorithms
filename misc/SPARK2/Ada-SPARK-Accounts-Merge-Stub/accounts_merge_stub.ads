pragma SPARK_Mode (On);

package Accounts_Merge_Stub is
   Account_Count : constant := 4;
   Email_Count   : constant := 6;
   subtype Account_Id is Positive range 1 .. Account_Count;
   subtype Email_Id is Positive range 1 .. Email_Count;
   type Account is record
      Owner  : Account_Id;
      Email1 : Email_Id;
      Email2 : Email_Id;
   end record;
   type Account_Array is array (Account_Id) of Account;

   function Merged_Account_Count (Accounts : Account_Array) return Natural;
end Accounts_Merge_Stub;
